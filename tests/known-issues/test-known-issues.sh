#!/bin/bash
# WS-D acceptance: restyle rules keep no inline Tuist versions/issue numbers
# outside example fences; every known-issues entry has the PRD fields; every
# link into known-issues points at a real heading.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

ruby - <<'RUBY'
require "json"
failures = 0
report = ->(ok, name) { puts "#{ok ? 'ok  ' : 'FAIL'} - #{name}"; failures += 1 unless ok }

ki = "references/tuist-known-issues.md"
report.(File.file?(ki), "#{ki} exists")
text = File.file?(ki) ? File.read(ki) : ""
entries = text.split(/^### /)[1..] || []
report.(entries.size >= 6, "at least 6 entries (got #{entries.size})")
fields = ["- Affects:", "- Fixed in:", "- Source:", "- Last verified:", "- Skill impact:"]
entries.each do |e|
  title = e.lines.first.strip
  missing = fields.reject { |f| e.include?("\n#{f}") }
  report.(missing.empty?, "entry '#{title}' has all fields#{missing.empty? ? '' : " (missing #{missing.join(', ')})"}")
end
slug = ->(h) { h.downcase.gsub(/[^a-z0-9 \-]/, "").tr(" ", "-") }
anchors = text.scan(/^### (.+)$/).flatten.map { |h| slug.(h.strip) }

in_fence = false
inline = []
File.foreach("skills/ios-tuist-restyle/SKILL.md").with_index(1) do |line, n|
  if line.lstrip.start_with?("```") then in_fence = !in_fence; next end
  next if in_fence
  inline << "#{n}: #{line.strip}" if line.match?(/\b\d+\.\d+\.\d+\b|#\d{4,}/)
end
report.(inline.empty?, "restyle has no inline version/issue numbers outside fences#{inline.empty? ? '' : "\n  " + inline.join("\n  ")}")

links = Dir.glob("skills/*/SKILL.md").flat_map { |f| File.read(f).scan(/tuist-known-issues\.md#([a-z0-9-]+)/).flatten.map { |a| [f, a] } }
report.(links.any? { |f, _| f.include?("ios-tuist-restyle") }, "restyle links known issues")
links.each { |f, a| report.(anchors.include?(a), "#{f} -> ##{a} exists") }
report.(File.read("scripts/skill-resources.manifest").include?("ios-tuist-restyle references/tuist-known-issues.md"), "manifest syncs known issues into restyle")
pinned = JSON.parse(File.read("tests/fixtures/ci-matrix.json")).find { |e| e["fixture"] == "restyle-candidate" }["tuist"]
report.(File.read(".github/workflows/known-issues-recheck.yml").include?(%(tuist: ["#{pinned}", "latest"])), "recheck control version matches ci-matrix (#{pinned})")
report.(File.read(".github/workflows/known-issues-recheck.yml").include?('GITHUB_TOKEN: ${{ github.token }}'), "recheck authenticates GitHub API calls")
report.(File.read(".github/workflows/known-issues-recheck.yml").include?("could not resolve Tuist version"), "recheck fails when Tuist version resolution is empty")
exit(failures.zero? ? 0 : 1)
RUBY
