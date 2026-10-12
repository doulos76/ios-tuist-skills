#!/bin/bash
# Runs every golden/unit test of the deterministic skill scripts. CI: lint.yml "golden tests".
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
failed=0
for t in \
  tests/golden/test-version-evidence.sh \
  tests/golden/test-consumer-edges.sh \
  tests/golden/test-read-only.sh; do
  echo "## $t"
  "$REPO_ROOT/$t" || failed=$((failed + 1))
done
[ "$failed" -eq 0 ] && echo "all golden suites passed" || echo "$failed golden suite(s) failed"
exit "$failed"
