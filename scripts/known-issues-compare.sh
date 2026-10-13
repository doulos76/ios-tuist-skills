#!/bin/bash
# Compares known-issues-probe.sh output with tests/known-issues/expected.json.
# A difference fails the job so a human re-verifies the entry; nothing is edited.
# Usage: known-issues-compare.sh <probe-output> <expected.json>
set -euo pipefail

ruby -rjson - "$1" "$2" <<'RUBY'
got = File.readlines(ARGV[0], chomp: true).select { |l| l.include?("=") }.map { |l| l.split("=", 2) }.to_h
want = JSON.parse(File.read(ARGV[1]))
version = got.delete("tuist_version") || "unknown"
rows = want.map { |probe, exp| [probe, exp, got.fetch(probe, "missing")] }
extra = got.keys - want.keys
table = ["Tuist #{version}", "", "| probe | expected | got |", "|---|---|---|"] + rows.map { |r| "| #{r.join(' | ')} |" }
puts table
File.write(ENV["GITHUB_STEP_SUMMARY"], table.join("\n") + "\n", mode: "a") if ENV["GITHUB_STEP_SUMMARY"]
extra.each { |p| puts "::warning title=unexpected probe::#{p}=#{got[p]} has no expectation" }
bad = rows.reject { |_, exp, actual| exp == actual }
bad.each { |p, exp, actual| puts "::error title=known issue changed::#{p}: expected #{exp}, got #{actual} on Tuist #{version} — re-verify references/tuist-known-issues.md" }
exit(bad.empty? ? 0 : 1)
RUBY
