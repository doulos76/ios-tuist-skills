#!/bin/bash
# Unit tests for scripts/bench-summarize.sh (bash + ruby only, no Xcode).
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SUM="$REPO_ROOT/scripts/bench-summarize.sh"
FIX="$REPO_ROOT/tests/harness/fixtures"
failures=0

expect() {
  local name="$1" want="$2"; shift 2
  local got; got="$("$@" 2>&1)"
  if [ "$got" = "$want" ]; then
    echo "ok   - $name"
  else
    echo "FAIL - $name: expected [$want], got [$got]"
    failures=$((failures + 1))
  fi
}

expect "xctest zero tests"              "0"       "$SUM" tests "$FIX/xctest-zero.log"
expect "xctest 0 + swift testing 1"     "1"       "$SUM" tests "$FIX/mixed-swift-testing.log"
expect "nested xctest summaries -> max" "5"       "$SUM" tests "$FIX/xctest-nested.log"
expect "swift testing failed run"       "3"       "$SUM" tests "$FIX/swift-testing-fail.log"
expect "no summary line -> unknown"     "unknown" "$SUM" tests "$FIX/no-summary.log"
expect "changed raw vs excluding gen"   "10 4"    "$SUM" changed "$FIX/status-porcelain.txt"
expect "empty status"                   "0 0"     "$SUM" changed /dev/null
expect "pattern list" "$(printf '%s\n' '*.xcodeproj/' '*.xcworkspace/' 'Derived/' '.build/' 'Tuist/.build/' 'DerivedData/' '*.xcresult/')" "$SUM" patterns

[ "$failures" -eq 0 ] && echo "all bench-summarize tests passed" || echo "$failures bench-summarize test(s) failed"
exit "$failures"
