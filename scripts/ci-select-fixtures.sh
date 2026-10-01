#!/bin/bash
# Chooses which fixtures the macOS matrix must validate for a change set.
# Pure function of (event, changed files, ci-matrix.json). Fails SAFE: when the
# change set cannot be computed it selects every fixture, never none.
#
#   ci-select-fixtures.sh --event <event> --base <sha> --head <sha> [--github-output]
#   ci-select-fixtures.sh --event pull_request --files-from <file>   # for tests
#
# Only pull_request events are filtered. push (main/develop), workflow_dispatch
# and schedule always validate everything, which backstops any gap in the path
# rules below.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MATRIX_FILE="${CI_MATRIX_FILE:-$REPO_ROOT/tests/fixtures/ci-matrix.json}"

event="" base="" head="" files_from="" github_output=0
while [ $# -gt 0 ]; do
  case "$1" in
    --event) event="${2:-}"; shift 2 ;;
    --base) base="${2:-}"; shift 2 ;;
    --head) head="${2:-}"; shift 2 ;;
    --files-from) files_from="${2:-}"; shift 2 ;;
    --github-output) github_output=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
[ -n "$event" ] || { echo "--event is required" >&2; exit 2; }

changed_files=""
effective_event="$event"
if [ "$event" = "pull_request" ]; then
  if [ -n "$files_from" ]; then
    changed_files="$(cat "$files_from")"
  elif [ -n "$base" ] && [ -n "$head" ] && changed_files="$(git -C "$REPO_ROOT" diff --name-only "$base...$head" 2>/dev/null)"; then
    :
  else
    echo "warning: could not compute the changed files; validating every fixture" >&2
    effective_event="diff-failed"
  fi
fi

CHANGED_FILES="$changed_files" EVENT="$effective_event" TO_GITHUB="$github_output" ruby -rjson -e '
  matrix = JSON.parse(File.read(ARGV[0]))
  names = matrix.map { |e| e.fetch("fixture") }
  files = ENV.fetch("CHANGED_FILES").split("\n").reject(&:empty?)
  everything = [
    %r{\A\.github/workflows/validate-fixtures\.yml\z},
    %r{\Atests/fixtures/ci-matrix\.json\z},
    %r{\Ascripts/(validate-fixtures-locally|ci-select-fixtures|ci-pick-simulator)\.sh\z},
  ]
  reasons = {}
  select_all = nil
  if ENV["EVENT"] != "pull_request"
    select_all = "event #{ENV["EVENT"]} always validates every fixture"
  else
    files.each do |f|
      if everything.any? { |re| re.match?(f) }
        select_all ||= "#{f} affects every fixture"
      elsif (m = %r{\Atests/fixtures/([^/]+)/}.match(f)) && names.include?(m[1])
        (reasons[m[1]] ||= []) << f
      end
    end
  end
  chosen = select_all ? matrix : matrix.select { |e| reasons.key?(e["fixture"]) }
  summary = if select_all
    ["all fixtures: #{select_all}"]
  elsif reasons.empty?
    ["no fixture selected: no changed path affects a fixture"]
  else
    reasons.map { |n, fs| "#{n}: #{fs.first}#{fs.size > 1 ? " (+#{fs.size - 1} more)" : ""}" }
  end
  result = { "matrix" => { "include" => chosen }, "has_fixtures" => !chosen.empty?, "summary" => summary }
  if ENV["TO_GITHUB"] == "1"
    File.open(ENV.fetch("GITHUB_OUTPUT"), "a") do |out|
      out.puts "matrix=#{JSON.generate(result["matrix"])}"
      out.puts "has_fixtures=#{result["has_fixtures"]}"
    end
    if ENV["GITHUB_STEP_SUMMARY"]
      File.open(ENV["GITHUB_STEP_SUMMARY"], "a") { |s| s.puts "### Fixture selection", *summary.map { |l| "- #{l}" } }
    end
  else
    puts JSON.generate(result)
  end
' "$MATRIX_FILE"
