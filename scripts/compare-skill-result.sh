#!/bin/bash
# Prints deterministic metrics: what the skill claimed in ios-tuist-result
# (parsed JSON) next to what the harness measured (report lines + edge JSON).
set -euo pipefail

[ "$#" -ge 2 ] && [ "$#" -le 3 ] || { echo "Usage: $0 <result.json> <report.md> [edges.json]" >&2; exit 64; }

exec ruby -rjson - "$@" <<'RUBY'
result = JSON.parse(File.read(ARGV[0]))
report = File.read(ARGV[1])
edges = ARGV[2] && File.size?(ARGV[2]) ? JSON.parse(File.read(ARGV[2])) : nil
# Report labels are the ones benchmark-isolated-run.sh prints (Task 1 / WS-H).
measured = lambda { |label| report[/^#{Regexp.escape(label)}:[ \t]*(.+)$/, 1] || "unrecorded" }

puts "Outcome: #{result["outcome"]}"
puts "Files changed: claimed #{result["files_changed"].size}; measured #{measured.call("Changed files (excluding generated)")}"
claimed_edges = result["dependency_edges_added"].size
if edges
  no_usage = edges["added"].count { |e| e["usage"].nil? }
  puts "Edges added: claimed #{claimed_edges}; measured #{edges["added"].size} (#{no_usage} without usage found)"
else
  puts "Edges added: claimed #{claimed_edges}; measured unavailable"
end
v = result["validation"]
puts "Validation: claimed generate=#{v["generate"]} build=#{v["build"]} test=#{v["test"]}; " \
     "harness Generate=#{measured.call("Generate")} Build=#{measured.call("Build")} Test=#{measured.call("Test")} " \
     "(tests executed: #{measured.call("Tests executed")})"
puts "Unverified items: #{result["unverified"].size}"
RUBY
