#!/usr/bin/env ruby
# frozen_string_literal: true

# Generates the TikTok Shop gateway endpoints of the API reference from the
# backend's route table and the gateway's OpenAPI spec. Rerun it when either
# changes; don't edit its output by hand. Public wording lives in
# scripts/tik_tok_shop_overrides.yml, and the run fails if any internal term
# would reach the docs.
#
#   ruby scripts/gen_tik_tok_shop.rb [ROUTES_YML] [GATEWAY_OPENAPI_JSON]
#
# Defaults assume ../backend and ../gateway-tik-tok-shop checkouts next to this repo.
require 'json'
require 'yaml'
require 'fileutils'

# The gateway's texts aren't ASCII; don't depend on the shell's locale.
Encoding.default_external = Encoding::UTF_8

ROOT = File.expand_path('..', __dir__)
ROUTES_FILE = ARGV[0] || File.expand_path('../backend/config/tik_tok_shop_public_routes.yml', ROOT)
GATEWAY_SPEC_FILE = ARGV[1] || File.expand_path('../gateway-tik-tok-shop/docs/api/openapi.json', ROOT)
OVERRIDES_FILE = File.join(ROOT, 'scripts/tik_tok_shop_overrides.yml')

SPEC_OUT = 'api-reference/tik-tok-shop-openapi.json'
PAGES_DIR = 'api-reference/endpoint/tik-tok-shop'
NAV_GROUP = 'TikTok Shop'
AREAS = ['Finance', 'Shop health', 'Affiliate', 'Samples', 'Products', 'Creators', 'Collabs and outreach'].freeze

# Words that only make sense inside Growi. Any of them in generated text fails the run.
INTERNAL = /\b(gateway|rails|postgres|clickhouse|redis|sweep\w*|backfill\w*|workers?|cron|isv|scraper|tts|gw)\b|
            ENG-\d+|DOC-DERIVED|web-only|unknown_shop|src\/|\w+\.ts\b|—/ix

ERROR_BODY = { 'content' => { 'application/json' => { 'schema' => { '$ref' => '#/components/schemas/TikTokShopError' } } } }.freeze

ORGANIZATION_PARAM = {
  'name' => 'organization_id', 'in' => 'query', 'required' => false, 'schema' => { 'type' => 'integer' },
  'description' => "Use the TikTok Shop of this child brand (organization id) of your API key's organization"
}.freeze

ERROR_SCHEMA = {
  'type' => 'object', 'required' => ['error'],
  'properties' => {
    'error' => { 'type' => 'string', 'description' => 'What went wrong' },
    'code' => { 'type' => 'string', 'description' => 'Machine-readable reason, when there is one' }
  }
}.freeze

def deep_copy(obj)
  Marshal.load(Marshal.dump(obj))
end

# JSON.stringify(value, null, 2) layout, which docs.json already uses.
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

def each_description(obj, path, &block)
  case obj
  when Hash
    obj.each do |k, v|
      next if %w[example examples].include?(k)

      if k == 'description' && v.is_a?(String)
        yield obj, path
      else
        each_description(v, "#{path}.#{k}", &block)
      end
    end
  when Array
    obj.each_with_index { |v, i| each_description(v, "#{path}[#{i}]", &block) }
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

def error_responses(gateway, route)
  post = route['verb'] == 'post'
  out = {}
  if (bad = gateway.dig('400', 'description'))
    # Callers never send a shop id, so drop the gateway's "Invalid shop id, ..." lead.
    rest = bad.sub(/\AInvalid shop id(?:,? or|,)\s*/i, '')
    text = rest == bad ? bad : "Invalid params: #{rest}"
    text = text.sub(/\.+\z/, '')
    text += '; also a body that is not a valid JSON object' if post
    out['400'] = { 'description' => text }.merge(ERROR_BODY)
  end
  out['401'] = { 'description' => 'Missing or invalid API key' }.merge(ERROR_BODY)
  forbidden = []
  forbidden << "The shop's TikTok authorization doesn't include this data (`code: scope_not_granted`), so the seller has to re-authorize the shop" if gateway['403']
  forbidden << "Read-only (viewer) API keys can't call POST endpoints" if post
  out['403'] = { 'description' => forbidden.join('. ') }.merge(ERROR_BODY) if forbidden.any?
  out['404'] = { 'description' => "`organization_id` isn't an active child brand of your organization, or the record you asked for doesn't exist" }.merge(ERROR_BODY)
  unprocessable = 'No TikTok Shop is connected for this organization. A parent organization whose shops sit on its child brands has to pass `organization_id`'
  unprocessable += ". Also returned when the shop isn't connected through TikTok's official API (`code: unsupported_on_web_only_shop`)" if gateway['422']
  out['422'] = { 'description' => unprocessable }.merge(ERROR_BODY)
  limited = 'Rate limited: one call every 2 seconds and an hourly cap per API key. See `Retry-After` and the `X-RateLimit-*` headers'
  limited += ". Also returned when TikTok's daily quota for this shop is spent (`code: quota_exhausted`)" if gateway['429']
  out['429'] = { 'description' => limited }.merge(ERROR_BODY)
  out['502'] = { 'description' => 'TikTok refused or failed. `error` is a fixed message and `code` names the failure when there is one' }.merge(ERROR_BODY)
  out
end

routes = YAML.load_file(ROUTES_FILE)
gateway_spec = JSON.parse(File.read(GATEWAY_SPEC_FILE))
overrides = YAML.load_file(OVERRIDES_FILE)
prose = overrides.fetch('endpoints')
texts = overrides.fetch('texts') || {}
drop_fields = overrides['drop_fields'] || {}
problems = []

paths = {}
schema_names = []
routes.each do |route|
  action = route['action']
  gw_path = "/v1/shops/{shopId}/#{route['gateway']}"
  gw_op = gateway_spec.dig('paths', gw_path, route['verb'])
  next problems << "#{action}: #{route['verb'].upcase} #{gw_path} isn't in the gateway spec" unless gw_op
  next problems << "#{action}: no title/description in #{File.basename(OVERRIDES_FILE)}" unless prose[action]

  params = (gw_op['parameters'] || []).select { |p| %w[query path].include?(p['in']) && p['name'] != 'shopId' }
  query_names = params.select { |p| p['in'] == 'query' }.map { |p| p['name'] }
  if query_names.sort != route['params'].sort
    problems << "#{action}: gateway query params #{query_names.sort} differ from the route table's #{route['params'].sort}"
  end

  op = {
    'summary' => prose[action].fetch('title'),
    'description' => prose[action].fetch('description').strip,
    'parameters' => deep_copy(params) + [deep_copy(ORGANIZATION_PARAM)]
  }
  if gw_op['requestBody']
    op['requestBody'] = deep_copy(gw_op['requestBody'])
    body_schema = op.dig('requestBody', 'content', 'application/json', 'schema') || {}
    (drop_fields[action] || []).each do |field|
      body_schema.fetch('properties', {}).delete(field) || problems << "#{action}: drop_fields names #{field}, which the body doesn't have"
      body_schema['required']&.delete(field)
      op['requestBody']['content']['application/json'].fetch('example', {}).delete(field)
    end
  end
  op['responses'] = deep_copy(gw_op['responses'].select { |code, _| code.start_with?('2') })
                    .merge(error_responses(gw_op['responses'], route))

  schema_names.concat(schema_refs(op))
  (paths["/tik_tok_shop/#{route['public']}"] ||= {})[route['verb']] = op
end

# Copy referenced gateway schemas, following refs between them.
schemas = {}
until schema_names.empty?
  name = schema_names.shift
  next if schemas.key?(name) || name == 'TikTokShopError'

  schemas[name] = deep_copy(gateway_spec.dig('components', 'schemas', name) || abort("Missing gateway schema #{name}"))
  schema_names.concat(schema_refs(schemas[name]))
end
schemas['TikTokShopError'] = deep_copy(ERROR_SCHEMA)
schemas = schemas.sort.to_h

spec = {
  'openapi' => '3.0.3',
  'info' => { 'title' => 'Growi API: TikTok Shop', 'version' => '1.0.0',
              'description' => "Generated by scripts/gen_tik_tok_shop.rb from Growi's TikTok Shop route table." },
  'servers' => [{ 'url' => 'https://api.growi.io/api/public/v1' }],
  'security' => [{ 'bearerAuth' => [] }],
  'paths' => paths,
  'components' => { 'securitySchemes' => { 'bearerAuth' => { 'type' => 'http', 'scheme' => 'bearer' } }, 'schemas' => schemas }
}

# Swap in public wording, then refuse to publish anything still internal.
unused_texts = texts.keys
each_description(spec, '$') do |holder, path|
  original = holder['description']
  if texts.key?(original)
    unused_texts.delete(original)
    texts[original].nil? ? holder.delete('description') : holder['description'] = texts[original]
  end
  text = holder['description']
  problems << "#{path}: #{text.inspect}" if text && text.match?(INTERNAL)
end
prose.each { |action, p| problems << "#{action} title: #{p['title'].inspect}" if p['title'].to_s.match?(INTERNAL) }
warn "Unused entries in texts (the gateway wording changed?):\n  #{unused_texts.join("\n  ")}" if unused_texts.any?

unless problems.empty?
  warn "Nothing written. Fix these first (add a public version under `texts:` in #{File.basename(OVERRIDES_FILE)}):"
  problems.each { |p| warn "  #{p}" }
  exit 1
end

Dir.chdir(ROOT)
File.write(SPEC_OUT, "#{to_json_text(spec)}\n")

FileUtils.rm_rf(PAGES_DIR)
FileUtils.mkdir_p(PAGES_DIR)
nav = Hash.new { |h, k| h[k] = [] }
routes.each do |route|
  slug = route['action'].tr('_', '-')
  File.write("#{PAGES_DIR}/#{slug}.mdx", <<~MDX)
    ---
    title: #{JSON.generate(prose[route['action']]['title'])}
    openapi: "/#{SPEC_OUT} #{route['verb'].upcase} /tik_tok_shop/#{route['public']}"
    ---

    {/* Generated by scripts/gen_tik_tok_shop.rb. Edit scripts/tik_tok_shop_overrides.yml and rerun. */}
  MDX
  nav[route['area']] << "#{PAGES_DIR}/#{slug}"
end

unknown_areas = nav.keys - AREAS
abort "Route table areas missing from AREAS: #{unknown_areas.join(', ')}" if unknown_areas.any?

docs = JSON.parse(File.read('docs.json'))
group = docs['navigation']['tabs'].flat_map { |t| t['groups'] || [] }.find { |g| g['group'] == NAV_GROUP }
abort "No #{NAV_GROUP} group in docs.json" unless group
kept = group['pages'].reject do |page|
  page.is_a?(Hash) ? AREAS.include?(page['group']) : page.start_with?("#{PAGES_DIR}/")
end
group['pages'] = kept + AREAS.select { |a| nav.key?(a) }.map { |a| { 'group' => a, 'pages' => nav[a] } }
File.write('docs.json', "#{to_json_text(docs)}\n")

puts "Wrote #{paths.size} paths and #{schemas.size} schemas to #{SPEC_OUT}, #{routes.size} pages to #{PAGES_DIR}/, and the #{NAV_GROUP} nav group."
