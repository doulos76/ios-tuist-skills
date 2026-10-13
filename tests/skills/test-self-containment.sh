#!/bin/bash
# Acceptance checks for WS-B: each skill folder must be usable on its own.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"
failures=0
check() { # check <name> <command...>; passes when the command exits 0
  local name="$1"; shift
  if "$@" >/dev/null 2>&1; then echo "ok   - $name"; else echo "FAIL - $name"; failures=$((failures + 1)); fi
}
none() { ! grep -rn "$@"; }

check "no ../../ links in skills/" none '\.\./\.\./' skills/
check "no ../ markdown links in skills/" none '](\.\./' skills/
check "no 'Same structure as'" none 'Same structure as' skills/
check "no cross-skill debugging references" none -e 'same procedure as' -e 'Same Evidence-Driven' skills/
check "no .gitkeep left in skills/" test -z "$(find skills -name .gitkeep)"
check "all 10 SKILL.md run collect-version-evidence" test "$(grep -l 'collect-version-evidence.sh' skills/*/SKILL.md | wc -l | tr -d ' ')" = 10
check "module runs check-consumer-edges" grep -q 'check-consumer-edges.sh' skills/ios-tuist-module/SKILL.md
check "dependency runs check-consumer-edges" grep -q 'check-consumer-edges.sh' skills/ios-tuist-dependency/SKILL.md
check "every skill link resolves inside its skill" ./scripts/check-skill-links.sh

exit $((failures > 0))
