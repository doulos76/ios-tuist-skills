#!/bin/bash
# Unit test for scripts/compare-skill-result.sh (claimed vs measured metrics).
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SAMPLES="$REPO_ROOT/tests/output-contract/samples"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/compare.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
failures=0

"$REPO_ROOT/scripts/parse-skill-result.sh" "$SAMPLES/valid-module.md" > "$TMP/result.json"
if "$REPO_ROOT/scripts/compare-skill-result.sh" "$TMP/result.json" "$SAMPLES/report.md" "$SAMPLES/edges.json" > "$TMP/out.txt" &&
  diff -u "$SAMPLES/compare.expected.txt" "$TMP/out.txt"; then
  echo "ok   - claimed vs measured summary"
else
  echo "FAIL - claimed vs measured summary"
  failures=$((failures + 1))
fi

if "$REPO_ROOT/scripts/compare-skill-result.sh" "$TMP/result.json" "$SAMPLES/report.md" | grep -qx 'Edges added: claimed 1; measured unavailable'; then
  echo "ok   - edges unavailable without edge JSON"
else
  echo "FAIL - edges unavailable without edge JSON"
  failures=$((failures + 1))
fi

[ "$failures" -eq 0 ] && echo "all compare-skill-result tests passed" || echo "$failures compare-skill-result test(s) failed"
exit "$failures"
