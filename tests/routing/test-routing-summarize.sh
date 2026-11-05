#!/bin/bash
# Unit test for `run-routing-eval.sh summarize` on canned results (no claude needed).
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cp "$REPO_ROOT/tests/routing/fixtures/results-sample.jsonl" "$TMP/results.jsonl"
failures=0

"$REPO_ROOT/scripts/run-routing-eval.sh" summarize "$TMP" > "$TMP/stdout" 2>&1 || { echo "FAIL - summarize exited non-zero: $(cat "$TMP/stdout")"; exit 1; }

want() {
  if grep -qF -- "$2" "$TMP/summary.md"; then echo "ok   - $1"; else echo "FAIL - $1: [$2] not in summary.md"; failures=$((failures + 1)); fi
}
want "overall accuracy"        "Accuracy: 3/5 (60.0%)"
want "category line"           "| ambiguous | 0/1 | 0.0% |"
want "forbidden violation"     "- amb-a: selected ios-tuist-migrate (forbidden)"
want "precision of feature"    "| feature | 1 | 1 | 0 | 0.5 | 1.0 |"
want "eof anomaly listed"      "- off-a: stop_reason eof"
want "cost accounting"         "Known cost: \$0.30 over 2 cases; 3 cases stopped before a result (cost unknown)"
want "plugin version recorded" "Plugin version: 0.9.0"
want "plan-file writes listed"  "- neg-a: 1 plan-file write(s), then result"

ruby -rjson -e 'd = JSON.parse(File.read(ARGV[0])); exit(d["cases"].size == 5 && d["aggregate"]["correct"] == 3 && d["aggregate"]["plan_write_cases"] == ["neg-a"] ? 0 : 1)' "$TMP/results.json" \
  && echo "ok   - results.json aggregate" || { echo "FAIL - results.json aggregate"; failures=$((failures + 1)); }

[ "$failures" -eq 0 ] && echo "all routing-summarize tests passed" || echo "$failures routing-summarize test(s) failed"
exit "$failures"
