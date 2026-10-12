#!/bin/bash
# Unit tests for scripts/parse-skill-result.sh.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
PARSE="$REPO_ROOT/scripts/parse-skill-result.sh"
SAMPLES="$REPO_ROOT/tests/output-contract/samples"
failures=0

# expect <name> <sample> <exit code> [ruby check on stdout JSON]
expect() {
  local name="$1" sample="$2" want="$3" check="${4:-}" out status
  out="$("$PARSE" "$SAMPLES/$sample" 2>/dev/null)"
  status=$?
  if [ "$status" -eq "$want" ] && { [ -z "$check" ] || printf '%s' "$out" | ruby -rjson -e "h = JSON.parse(STDIN.read); exit((${check}) ? 0 : 1)"; }; then
    echo "ok   - $name"
  else
    echo "FAIL - $name (exit $status, want $want)"
    failures=$((failures + 1))
  fi
}

expect "valid review block"          valid.md        0 'h["schema"] == "ios-tuist-result/1" && h["skill"] == "ios-tuist-architecture-review" && h["version_evidence"]["effective"] == "4.206.0"'
expect "valid module block"          valid-module.md 0 'h["dependency_edges_added"] == [{"from" => "App", "to" => "NetworkingKit", "usage" => "App/Sources/ExtractCandidateApp.swift:2"}] && h["validation"]["test"] == "pass"'
expect "missing block exits 2"       missing.md      2
expect "malformed YAML exits 3"      malformed.md    3
expect "bad enum values exit 4"      invalid-enum.md 4
expect "two blocks exit 4"           two-blocks.md   4

# pipefail would turn the expected exit 2 into a failed grep; capture first.
msg="$("$PARSE" "$SAMPLES/missing.md" 2>&1 >/dev/null)"
if [ "$msg" = "error: no ios-tuist-result block" ]; then
  echo "ok   - missing block message"
else
  echo "FAIL - missing block message"
  failures=$((failures + 1))
fi

[ "$failures" -eq 0 ] && echo "all parse-skill-result tests passed" || echo "$failures parse-skill-result test(s) failed"
exit "$failures"
