#!/bin/bash
# Extracts the single `ios-tuist-result` block (references/output-contract.md)
# from a skill's response and prints it as JSON. Exit codes: 0 ok, 2 no block,
# 3 YAML parse error, 4 schema violation (incl. more than one block).
set -euo pipefail

[ "$#" -eq 1 ] && [ -f "$1" ] || { echo "Usage: $0 <response.md>" >&2; exit 64; }

exec ruby -rjson -ryaml - "$1" <<'RUBY'
SKILLS = %w[ios-tuist-architecture-review ios-tuist-bootstrap ios-tuist-ci ios-tuist-dependency
            ios-tuist-feature ios-tuist-migrate ios-tuist-module ios-tuist-restyle
            ios-tuist-scaffold ios-tuist-test-target]
OUTCOMES = %w[completed refused blocked partial]
STEP = %w[pass fail not-run]

text = File.binread(ARGV[0]).force_encoding("UTF-8").scrub
blocks = text.scan(/^```ios-tuist-result[ \t]*\r?\n(.*?)^```[ \t]*\r?$/m).map(&:first)
if blocks.empty?
  warn "error: no ios-tuist-result block"
  exit 2
end
if blocks.size > 1
  warn "error: #{blocks.size} ios-tuist-result blocks (exactly one is required)"
  exit 4
end

begin
  data = YAML.safe_load(blocks.first)
rescue Psych::SyntaxError => e
  warn "error: ios-tuist-result is not valid YAML: #{e.message}"
  exit 3
end

errors = []
errors << "block must be a mapping" unless data.is_a?(Hash)
data = {} unless data.is_a?(Hash)
required = %w[skill outcome version_evidence files_changed dependency_edges_added
              dependency_edges_removed validation unverified]
(required - data.keys).each { |k| errors << "missing field: #{k}" }
(data.keys - required).each { |k| errors << "unknown field: #{k}" }
errors << "skill must be one of #{SKILLS.join(", ")}" if data.key?("skill") && !SKILLS.include?(data["skill"])
errors << "outcome must be one of #{OUTCOMES.join("|")}" if data.key?("outcome") && !OUTCOMES.include?(data["outcome"])

ve = data["version_evidence"]
if data.key?("version_evidence") && ve != "unavailable"
  if !ve.is_a?(Hash)
    errors << "version_evidence must be \"unavailable\" or a mapping"
  else
    (%w[effective source conflicts collected_by] - ve.keys).each { |k| errors << "version_evidence missing: #{k}" }
    errors << "version_evidence.conflicts must be a list" unless ve["conflicts"].is_a?(Array)
    errors << "version_evidence.collected_by must be script|manual" unless %w[script manual].include?(ve["collected_by"])
  end
end

%w[files_changed unverified].each do |k|
  next unless data.key?(k)
  errors << "#{k} must be a list of strings" unless data[k].is_a?(Array) && data[k].all? { |v| v.is_a?(String) }
end
{ "dependency_edges_added" => %w[from to usage], "dependency_edges_removed" => %w[from to] }.each do |k, keys|
  next unless data.key?(k)
  list = data[k]
  unless list.is_a?(Array) && list.all? { |e| e.is_a?(Hash) && (keys - e.keys).empty? }
    errors << "#{k} must be a list of {#{keys.join(", ")}}"
  end
end
if data.key?("validation")
  v = data["validation"]
  if v.is_a?(Hash) && %w[generate build test].all? { |k| STEP.include?(v[k]) } && v.keys.sort == %w[build generate test]
    # valid
  else
    errors << "validation must be {generate, build, test} each pass|fail|not-run"
  end
end

unless errors.empty?
  errors.each { |e| warn "error: #{e}" }
  exit 4
end
puts JSON.pretty_generate({ "schema" => "ios-tuist-result/1" }.merge(data))
RUBY
