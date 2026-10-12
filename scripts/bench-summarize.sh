#!/bin/bash
# Text-only helpers for benchmark-isolated-run.sh; no Xcode needed, so CI can test them.
#   bench-summarize.sh tests <xcodebuild-log>    -> executed test count, or "unknown"
#   bench-summarize.sh changed <porcelain-file>  -> "<raw> <excluding-generated>"
#   bench-summarize.sh patterns                  -> generated-path patterns, one per line
set -euo pipefail

usage() { echo "Usage: $0 tests <log> | changed <porcelain-file> | patterns" >&2; exit 2; }
[ "$#" -ge 1 ] || usage

case "$1" in
  tests)
    [ "$#" -eq 2 ] || usage
    ruby -e '
      text = File.read(ARGV[0], mode: "rb").force_encoding("UTF-8").scrub
      # XCTest nests suite summaries (class < bundle < "All tests"), so the outermost is the max.
      xctest = text.scan(/\bExecuted (\d+) tests?, with /).flatten.map(&:to_i)
      # Swift Testing prints one run summary: "Test run with N test(s) in M suite(s) passed|failed".
      swift_testing = text.scan(/\bTest run with (\d+) tests? in /).flatten.map(&:to_i)
      if xctest.empty? && swift_testing.empty?
        puts "unknown"
      else
        puts (xctest.max || 0) + (swift_testing.max || 0)
      end
    ' "$2"
    ;;
  changed)
    [ "$#" -eq 2 ] || usage
    ruby -e '
      generated = lambda do |path|
        parts = path.split("/")
        parts.any? { |p| p.end_with?(".xcodeproj", ".xcworkspace", ".xcresult") } ||
          parts.any? { |p| %w[Derived .build DerivedData].include?(p) }
      end
      raw = 0
      kept = 0
      File.foreach(ARGV[0]) do |line|
        line = line.chomp
        next if line.strip.empty?
        path = line[3..].to_s
        path = path.split(" -> ", 2).last if path.include?(" -> ")
        path = path[1..-2] if path.start_with?("\"") && path.end_with?("\"")
        raw += 1
        kept += 1 unless generated.call(path)
      end
      puts "#{raw} #{kept}"
    ' "$2"
    ;;
  patterns)
    [ "$#" -eq 1 ] || usage
    printf '%s\n' '*.xcodeproj/' '*.xcworkspace/' 'Derived/' '.build/' 'Tuist/.build/' 'DerivedData/' '*.xcresult/'
    ;;
  *) usage ;;
esac
