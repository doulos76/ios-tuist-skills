#!/bin/bash
# Unit tests for scripts/known-issues-compare.sh (no Tuist needed).
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CMP="$REPO_ROOT/scripts/known-issues-compare.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/ki-compare.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
failures=0
printf '%s\n' '{"a": "pass", "b": "present"}' > "$TMP/expected.json"

expect() { # expect <name> <exit> <probe lines...>
  local name="$1" want="$2"; shift 2
  printf '%s\n' "$@" > "$TMP/probe.txt"
  local out; out="$(GITHUB_STEP_SUMMARY="$TMP/summary.md" "$CMP" "$TMP/probe.txt" "$TMP/expected.json" 2>&1)"; local got=$?
  if [ "$got" = "$want" ]; then echo "ok   - $name"; else echo "FAIL - $name (exit $got, want $want)"; printf '%s\n' "$out" | sed 's/^/  /'; failures=$((failures + 1)); fi
}
expect "all match" 0 "tuist_version=4.206.0" "a=pass" "b=present"
expect "changed result fails" 1 "tuist_version=4.212.0" "a=pass" "b=absent"
expect "missing probe fails" 1 "tuist_version=4.212.0" "a=pass"
expect "unknown probe line is reported, not fatal" 0 "tuist_version=4.212.0" "a=pass" "b=present" "c=pass"
grep -q '| b | present | present |' "$TMP/summary.md" && echo "ok   - summary table written" || { echo "FAIL - summary table written"; failures=$((failures + 1)); }
exit $((failures > 0))
