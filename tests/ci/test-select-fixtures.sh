#!/bin/bash
# Unit tests for scripts/ci-select-fixtures.sh (bash + ruby only).
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SELECT="$REPO_ROOT/scripts/ci-select-fixtures.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
failures=0

names_of() {
  ruby -rjson -e 'puts JSON.parse(STDIN.read)["matrix"]["include"].map { |e| e["fixture"] }.sort.join(",")'
}
flag_of() {
  ruby -rjson -e 'puts JSON.parse(STDIN.read)["has_fixtures"]'
}
ALL="$(ruby -rjson -e 'puts JSON.parse(File.read(ARGV[0])).map { |e| e["fixture"] }.sort.join(",")' "$REPO_ROOT/tests/fixtures/ci-matrix.json")"

# expect <name> <expected fixtures csv> <event> [changed files...]
expect() {
  local name="$1" expected="$2" event="$3"; shift 3
  printf '%s\n' "$@" > "$TMP/files"
  local out; out="$("$SELECT" --event "$event" --files-from "$TMP/files")"
  local got; got="$(printf '%s' "$out" | names_of)"
  local want_flag="true"; [ -z "$expected" ] && want_flag="false"
  local got_flag; got_flag="$(printf '%s' "$out" | flag_of)"
  if [ "$got" = "$expected" ] && [ "$got_flag" = "$want_flag" ]; then
    echo "ok   - $name"
  else
    echo "FAIL - $name: expected [$expected]/$want_flag, got [$got]/$got_flag"
    failures=$((failures + 1))
  fi
}

expect "docs and skills only select nothing" "" pull_request docs/superpowers/a.md skills/ios-tuist-ci/SKILL.md README.md .claude-plugin/plugin.json
expect "one file in one fixture"             "modular" pull_request tests/fixtures/modular/App/Sources/A.swift
expect "dotfile inside a fixture"            "extract-candidate" pull_request tests/fixtures/extract-candidate/.tool-versions
expect "two fixtures plus docs"              "ci-gaps,modular" pull_request docs/x.md tests/fixtures/modular/Project.swift tests/fixtures/ci-gaps/Tuist.swift
expect "fixture outside the matrix"          "" pull_request tests/fixtures/new-project/README.md
expect "workflow change selects all"         "$ALL" pull_request .github/workflows/validate-fixtures.yml
expect "matrix file change selects all"     "$ALL" pull_request tests/fixtures/ci-matrix.json
expect "local validator change selects all"  "$ALL" pull_request scripts/validate-fixtures-locally.sh
expect "selector change selects all"         "$ALL" pull_request scripts/ci-select-fixtures.sh
expect "push selects all"                    "$ALL" push docs/x.md
expect "workflow_dispatch selects all"       "$ALL" workflow_dispatch
expect "schedule selects all"                "$ALL" schedule

# A failing git diff must fall back to every fixture, never to none.
out="$("$SELECT" --event pull_request --base 0000000000000000000000000000000000000001 --head 0000000000000000000000000000000000000002 2>/dev/null)"
got="$(printf '%s' "$out" | names_of)"
if [ "$got" = "$ALL" ]; then echo "ok   - unresolvable diff selects all"; else echo "FAIL - unresolvable diff: got [$got]"; failures=$((failures + 1)); fi

[ "$failures" -eq 0 ] && echo "all selection tests passed" || echo "$failures selection test(s) failed"
exit "$failures"
