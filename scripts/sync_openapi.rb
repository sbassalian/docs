#!/usr/bin/env ruby
# frozen_string_literal: true

# Copies the public endpoints of the backend's rswag spec (swagger/v1/swagger.yaml)
# into api-reference/openapi.json and writes one page per endpoint, so Mintlify
# renders params, bodies and responses straight from the backend.
#
#   ruby scripts/sync_openapi.rb [PATH_TO_BACKEND_SWAGGER]
#
# The default is ../backend/swagger/v1/swagger.yaml (a backend checkout next to this repo).
#
# Only the paths listed in scripts/openapi_public_paths.yml are copied. The spec also
# holds operations that are still written by hand; the script leaves those alone and
# only replaces the operations it generated itself (marked x-generated-by). Taking an
# allow-list entry out removes its operation on the next run.
#
# An entry with `pending: true` is an endpoint that hasn't shipped yet. If the backend
# spec doesn't have it, its hand-written "coming soon" page stays as it is. Once the
# backend has it, the page is generated like any other and the run reminds you to
# drop the flag.
#
# The run fails, writing nothing, if any internal term would reach the docs or a
# non-pending entry is missing from the backend spec.
require 'json'
require 'yaml'
require 'fileutils'

Encoding.default_external = Encoding::UTF_8

ROOT = File.expand_path('..', __dir__)
BACKEND_SPEC = File.expand_path(ARGV[0] || '../backend/swagger/v1/swagger.yaml', ARGV[0] ? Dir.pwd : ROOT)
ALLOW_LIST = File.join(ROOT, 'scripts/openapi_public_paths.yml')
SPEC_OUT = File.join(ROOT, 'api-reference/openapi.json')
GENERATED_BY = 'scripts/sync_openapi.rb'
VERBS = %w[get post put patch delete].freeze

# Same list as scripts/gen_tik_tok_shop.rb, plus backend class and table names.
INTERNAL = /\b(gateway|rails|postgres|clickhouse|redis|sidekiq|sweep\w*|backfill\w*|workers?|cron|isv|scraper|tts|gw|
            rswag|replica|matview|precompute\w*|snapshots?_v\d|org_post_daily\w*|post_daily_views)\b|
            ENG-\d+|DOC-DERIVED|web-only|src\/|\w+\.(rb|ts)\b|\w+::\w+|—/ix

ERROR_SCHEMA = { 'type' => 'object', 'properties' => { 'error' => { 'type' => 'string', 'description' => 'What went wrong' } } }.freeze

STANDARD_ERRORS = {
  '401' => 'Missing or invalid API key',
  '403' => "Read-only (viewer) API keys can't call write endpoints",
  '404' => "`organization_id` isn't an active child brand of your organization, or the record doesn't exist",
  '422' => 'Invalid or missing params. `error` says which',
  '429' => 'Rate limited: 2 seconds between calls and an hourly cap per API key. See `Retry-After` and the `X-RateLimit-*` headers'
}.freeze

def deep_copy(obj)
  Marshal.load(Marshal.dump(obj))
end

# JSON.stringify(value, null, 2) layout, which docs.json and the other generators use.
def to_json_text(obj, indent = '')
  inner = "#{indent}  "
  case obj
  when Hash
    return '{}' if obj.empty?

    "{\n#{obj.map { |k, v| "#{inner}#{JSON.generate(k.to_s)}: #{to_json_text(v, inner)}" }.join(",\n")}\n#{indent}}"
  when Array
    return '[]' if obj.empty?

    "[\n#{obj.map { |v| "#{inner}#{to_json_text(v, inner)}" }.join(",\n")}\n#{indent}]"
  else
    JSON.generate(obj)
  end
end

def each_text(obj, path, &block)
  case obj
  when Hash
    obj.each do |k, v|
      next if %w[example examples].include?(k)

      if %w[description summary].include?(k) && v.is_a?(String)
        yield obj, k, path
      else
        each_text(v, "#{path}.#{k}", &block)
      end
    end
  when Array
    obj.each_with_index { |v, i| each_text(v, "#{path}[#{i}]", &block) }
  end
end

# OpenAPI 3.1-style `type: [x, "null"]` becomes 3.0 `nullable`.
def normalize_types(obj)
  case obj
  when Hash
    if obj['type'].is_a?(Array)
      types = obj['type'] - ['null']
      obj['nullable'] = true if obj['type'].include?('null')
      types.size == 1 ? obj['type'] = types.first : obj.delete('type')
    end
    obj.each { |k, v| normalize_types(v) unless %w[example examples].include?(k) }
  when Array
    obj.each { |v| normalize_types(v) }
  end
end

def schema_refs(obj, found = [])
  case obj
  when Hash
    obj.each { |k, v| k == '$ref' ? found << v.split('/').last : schema_refs(v, found) }
  when Array
    obj.each { |v| schema_refs(v, found) }
  end
  found
end

def public_op(source, entry)
  op = deep_copy(source)
  op.delete('tags')
  op.delete('operationId')
  op.delete('security')
  # The bearer security scheme covers auth; rswag lists the header as a param.
  op['parameters'] = (op['parameters'] || []).reject { |p| p['in'] == 'header' && p['name'].casecmp?('authorization') }
  op.delete('parameters') if op['parameters'].empty?
  op['summary'] = entry['title'] if entry['title']
  op['description'] = entry['description'].strip if entry['description']

  responses = op['responses'] || {}
  STANDARD_ERRORS.each do |code, text|
    next if code == '403' && entry['method'] == 'get'
    next if code == '429' && entry['rate_limit_exempt']
    next if code == '404' && !responses.key?('404') && !entry['child_brands']

    responses[code] = { 'description' => text,
                        'content' => { 'application/json' => { 'schema' => { '$ref' => '#/components/schemas/ApiError' } } } }
  end
  op['responses'] = responses.sort.to_h
  op['x-generated-by'] = GENERATED_BY
  op
end

def page_body(entry)
  entry['notes'] ? "\n#{entry['notes'].strip}\n" : ''
end

abort "No backend spec at #{BACKEND_SPEC}. Pass its path: ruby scripts/sync_openapi.rb PATH" unless File.exist?(BACKEND_SPEC)

backend = BACKEND_SPEC.end_with?('.json') ? JSON.parse(File.read(BACKEND_SPEC)) : YAML.load_file(BACKEND_SPEC, aliases: true)
config = YAML.load_file(ALLOW_LIST)
prefix = config.fetch('prefix')
entries = config.fetch('paths')
texts = config['texts'] || {}
spec = JSON.parse(File.read(SPEC_OUT))
problems = []
pending_now_live = []
still_pending = []

# Drop what an earlier run generated, so removed entries disappear.
spec['paths'].each_value { |ops| ops.reject! { |_, op| op.is_a?(Hash) && op['x-generated-by'] == GENERATED_BY } }
spec['paths'].reject! { |_, ops| ops.empty? }

generated = []
schema_names = []
entries.each do |entry|
  path = entry.fetch('path')
  verb = entry.fetch('method')
  next problems << "#{verb.upcase} #{path}: method must be one of #{VERBS.join(', ')}" unless VERBS.include?(verb)

  source = backend.dig('paths', "#{prefix}#{path}", verb)
  unless source
    if entry['pending']
      still_pending << "#{verb.upcase} #{path}"
    else
      problems << "#{verb.upcase} #{path} isn't in #{File.basename(BACKEND_SPEC)}"
    end
    next
  end
  pending_now_live << "#{verb.upcase} #{path}" if entry['pending']

  existing = spec.dig('paths', path, verb)
  if existing && existing['x-generated-by'] != GENERATED_BY
    problems << "#{verb.upcase} #{path} is still hand-written in openapi.json. Delete it there first, then rerun"
    next
  end

  op = public_op(source, entry)
  schema_names.concat(schema_refs(op))
  (spec['paths'][path] ||= {})[verb] = op
  generated << entry
end

spec['components'] ||= {}
spec['components']['schemas'] ||= {}
until schema_names.empty?
  name = schema_names.shift
  next if name == 'ApiError' || spec['components']['schemas'].key?(name)

  schema = backend.dig('components', 'schemas', name)
  next problems << "Schema #{name} is referenced but missing from the backend spec" unless schema

  spec['components']['schemas'][name] = deep_copy(schema)
  schema_names.concat(schema_refs(schema))
end
spec['components']['schemas']['ApiError'] ||= deep_copy(ERROR_SCHEMA)
normalize_types(spec)

# Deprecated endpoints are hidden from the docs, so drop the backend's
# "Replaces /stats/..." pointers to them.
REPLACES_DEPRECATED = %r{\s*Replaces /stats/[^.]*\.}

# Swap in public wording, then refuse to publish anything still internal.
generated_ops = generated.map { |e| [e['path'], e['method']] }
generated_ops.each do |path, verb|
  each_text(spec['paths'][path][verb], "#{verb.upcase} #{path}") do |holder, key, where|
    holder[key] = texts[holder[key]] if texts.key?(holder[key])
    holder[key] = holder[key].gsub(REPLACES_DEPRECATED, '').strip if holder[key].is_a?(String)
    holder.delete(key) if holder[key].nil?
    problems << "#{where}.#{key}: #{holder[key].inspect}" if holder[key]&.match?(INTERNAL)
  end
end

unless problems.empty?
  warn "Nothing written. Fix these first (public wording goes under `texts:` in #{File.basename(ALLOW_LIST)}):"
  problems.each { |p| warn "  #{p}" }
  exit 1
end

File.write(SPEC_OUT, "#{to_json_text(spec)}\n")

generated.each do |entry|
  next unless entry['page']

  page = File.join(ROOT, "#{entry['page']}.mdx")
  title = entry['title'] || backend.dig('paths', "#{prefix}#{entry['path']}", entry['method'], 'summary')
  body = page_body(entry)
  FileUtils.mkdir_p(File.dirname(page))
  File.write(page, <<~MDX)
    ---
    title: #{JSON.generate(title)}
    openapi: "#{entry['method'].upcase} #{entry['path']}"
    ---

    {/* Generated by #{GENERATED_BY} from the backend's OpenAPI spec. Edit scripts/openapi_public_paths.yml and rerun. */}
    #{body}
  MDX
end

puts "Synced #{generated.size} operations from #{BACKEND_SPEC} into #{File.basename(SPEC_OUT)}."
puts "Now in the backend spec, drop `pending: true` for: #{pending_now_live.join(', ')}" if pending_now_live.any?
puts "Still pending (coming-soon pages kept): #{still_pending.size}" if still_pending.any?
