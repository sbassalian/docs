#!/usr/bin/env ruby
# frozen_string_literal: true

# Checks what `mint broken-links` doesn't:
#   - every page in docs.json navigation has a file
#   - every `openapi:` frontmatter names an operation that exists in a spec
#   - every page under api-reference/ and essentials/ is in the navigation
#   - every redirect destination resolves
#
#   ruby scripts/check_nav.rb
require 'json'

ROOT = File.expand_path('..', __dir__)
Dir.chdir(ROOT)

docs = JSON.parse(File.read('docs.json'))
problems = []

def pages_in(node, out = [])
  case node
  when Hash
    out << node['page'] if node['page'].is_a?(String)
    node.each_value { |v| pages_in(v, out) }
  when Array
    node.each { |v| v.is_a?(String) ? out << v : pages_in(v, out) }
  end
  out
end

nav = pages_in(docs['navigation'])
nav.group_by(&:itself).each { |page, hits| problems << "In the nav #{hits.size} times: #{page}" if hits.size > 1 }
nav.each { |page| problems << "Nav page has no file: #{page}" unless File.exist?("#{page}.mdx") || File.exist?("#{page}.md") }

specs = Dir['api-reference/*.json'].to_h { |f| ["/#{f}", JSON.parse(File.read(f))] }
ops = specs.transform_values do |spec|
  spec['paths'].flat_map { |path, verbs| verbs.keys.map { |verb| "#{verb.upcase} #{path}" } }
end
all_ops = ops.values.flatten

Dir['**/*.mdx'].each do |file|
  ref = File.read(file)[/\A---\n.*?^openapi:\s*["']?([^"'\n]+)["']?\s*$/m, 1]
  next unless ref

  parts = ref.split
  if parts.first.start_with?('/')
    spec_file = parts.shift
    problems << "#{file}: spec #{spec_file} doesn't exist" and next unless ops.key?(spec_file)
    problems << "#{file}: #{parts.join(' ')} isn't in #{spec_file}" unless ops[spec_file].include?(parts.join(' '))
  else
    problems << "#{file}: #{ref} isn't in any spec" unless all_ops.include?(ref)
  end
end

listed = nav.to_h { |page| [page, true] }
Dir['{api-reference,essentials,ai}/**/*.mdx'].each do |file|
  page = file.delete_suffix('.mdx')
  problems << "Not in the nav: #{page}" unless listed[page]
end

(docs['redirects'] || []).each do |r|
  dest = r['destination'].split('#').first.delete_prefix('/')
  dest = 'index' if dest.empty?
  problems << "Redirect #{r['source']} -> #{r['destination']} has no page" unless File.exist?("#{dest}.mdx") || File.exist?("#{dest}.md")
end

if problems.empty?
  puts "OK: #{nav.size} nav pages, #{all_ops.size} spec operations, no problems."
else
  puts problems
  exit 1
end
