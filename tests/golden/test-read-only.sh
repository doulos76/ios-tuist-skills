#!/bin/bash
# Both skill scripts must leave every fixture untouched (PRD WS-A acceptance):
# same git status and the same file list (including untracked/ignored files).
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/golden-ro.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

state() {
  git -C "$REPO_ROOT" status --porcelain --ignored -- tests/fixtures
  (cd "$REPO_ROOT/tests/fixtures" && find . -print | LC_ALL=C sort)
}

state > "$TMP/before"
for dir in "$REPO_ROOT"/tests/fixtures/*/; do
  "$REPO_ROOT/scripts/skill/collect-version-evidence.sh" --no-commands "$dir" > /dev/null
  "$REPO_ROOT/scripts/skill/collect-version-evidence.sh" --json --no-commands "$dir" > /dev/null
  "$REPO_ROOT/scripts/skill/check-consumer-edges.sh" --before HEAD "$dir" > /dev/null
done
state > "$TMP/after"

if diff -u "$TMP/before" "$TMP/after"; then
  echo "ok   - scripts left tests/fixtures unchanged"
  exit 0
fi
echo "FAIL - scripts left tests/fixtures unchanged"
exit 1
