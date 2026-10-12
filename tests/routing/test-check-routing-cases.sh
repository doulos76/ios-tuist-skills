#!/bin/bash
# Unit tests for scripts/check-routing-cases.sh: the real cases.yaml passes; broken copies fail.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHECK="$REPO_ROOT/scripts/check-routing-cases.sh"
CASES="$REPO_ROOT/tests/routing/cases.yaml"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
failures=0

# mutate <name> <ruby expression on `doc`> : writes $TMP/<name>.yaml
mutate() {
  ruby -ryaml -e 'doc = YAML.safe_load(File.read(ARGV[0])); eval(ARGV[1]); File.write(ARGV[2], doc.to_yaml)' \
    "$CASES" "$2" "$TMP/$1.yaml"
}
expect_pass() {
  if "$CHECK" "$2" > "$TMP/out" 2>&1; then echo "ok   - $1"; else echo "FAIL - $1: $(cat "$TMP/out")"; failures=$((failures + 1)); fi
}
expect_fail() {
  local name="$1" file="$2" pattern="$3"
  if "$CHECK" "$file" > "$TMP/out" 2>&1; then
    echo "FAIL - $name: expected failure, got pass"; failures=$((failures + 1))
  elif grep -q -- "$pattern" "$TMP/out"; then
    echo "ok   - $name"
  else
    echo "FAIL - $name: missing [$pattern] in: $(cat "$TMP/out")"; failures=$((failures + 1))
  fi
}

expect_pass "committed cases.yaml is valid" "$CASES"

mutate unknown-skill 'doc["cases"][0]["expected_skill"] = "ios-tuist-nonexistent"'
expect_fail "unknown expected_skill" "$TMP/unknown-skill.yaml" "unknown expected_skill"

mutate missing-fixture 'doc["cases"][0]["fixture"] = "no-such-fixture"'
expect_fail "missing fixture dir" "$TMP/missing-fixture.yaml" "unknown fixture"

mutate dup-id 'doc["cases"][1]["id"] = doc["cases"][0]["id"]'
expect_fail "duplicate id" "$TMP/dup-id.yaml" "duplicate id"

mutate few-negatives 'doc["cases"].reject! { |c| c["category"] == "negative" }'
expect_fail "negative minimum" "$TMP/few-negatives.yaml" "negative: 0 < 8"

mutate ambiguous-no-forbidden 'doc["cases"].find { |c| c["category"] == "ambiguous" }.delete("forbidden_skills")'
expect_fail "ambiguous needs forbidden_skills" "$TMP/ambiguous-no-forbidden.yaml" "ambiguous case needs forbidden_skills"

mutate positive-gap 'doc["cases"].reject! { |c| c["category"] == "positive" && c["expected_skill"] == "ios-tuist-ci" }'
expect_fail "per-skill positive minimum" "$TMP/positive-gap.yaml" "positive ios-tuist-ci: 0 < 2"

mutate bad-key 'doc["cases"][0]["expected"] = "x"'
expect_fail "unknown key" "$TMP/bad-key.yaml" "unknown keys"

[ "$failures" -eq 0 ] && echo "all routing-case tests passed" || echo "$failures routing-case test(s) failed"
exit "$failures"
