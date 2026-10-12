#!/bin/bash
# Each skill folder copied alone must still resolve every link (PRD WS-B acceptance).
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/standalone-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
failures=0

for skill in "$REPO_ROOT"/skills/*/; do
  name="$(basename "$skill")"
  mkdir -p "$TMP/$name/skills"
  cp -R "$skill" "$TMP/$name/skills/$name"
  if out="$("$REPO_ROOT/scripts/check-skill-links.sh" "$TMP/$name/skills")"; then
    echo "ok   - $name standalone"
  else
    echo "FAIL - $name standalone"; printf '%s\n' "$out" | sed 's/^/  /'; failures=$((failures + 1))
  fi
done

# The checker itself must catch the defects WS-B removes.
mkdir -p "$TMP/neg/skills/bad/references"
printf '%s\n' '---' 'name: bad' '---' '[x](../../references/version-safety.md)' '[y](references/nope.md)' \
  'Run `"${CLAUDE_SKILL_DIR}/scripts/nope.sh"`.' '```text' '[ignored](../in-a-fence.md)' '```' > "$TMP/neg/skills/bad/SKILL.md"
out="$("$REPO_ROOT/scripts/check-skill-links.sh" "$TMP/neg/skills")"; status=$?
if [ "$status" -ne 0 ] && grep -q 'uses \.\.' <<<"$out" && grep -q 'references/nope.md (missing)' <<<"$out" \
   && grep -q 'scripts/nope.sh (missing)' <<<"$out" && ! grep -q 'in-a-fence' <<<"$out"; then
  echo "ok   - checker rejects ../, missing files, missing \${CLAUDE_SKILL_DIR} paths; ignores fences"
else
  echo "FAIL - checker negative case"; printf '%s\n' "$out" | sed 's/^/  /'; failures=$((failures + 1))
fi

exit $((failures > 0))
