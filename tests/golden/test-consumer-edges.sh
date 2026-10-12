#!/bin/bash
# Golden tests for scripts/skill/check-consumer-edges.sh on extract-candidate:
# an added App -> NetworkingKit edge without and with an import in App.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
EDGES="$REPO_ROOT/scripts/skill/check-consumer-edges.sh"
GOLDEN="$REPO_ROOT/tests/golden/consumer-edges"
FIXTURE="$REPO_ROOT/tests/fixtures/extract-candidate"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/golden-ce.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
failures=0

for case_name in no-usage with-usage; do
  work="$TMP/$case_name"
  cp -R "$FIXTURE" "$work"
  # The case's after/ tree overlays the fixture copy (the "after" state).
  cp -R "$GOLDEN/$case_name/after/." "$work/"
  if "$EDGES" --json --before "$FIXTURE" "$work" > "$TMP/actual.json" &&
    ruby -rjson -e '
      a = JSON.parse(File.read(ARGV[0])); e = JSON.parse(File.read(ARGV[1]))
      exit 0 if a == e
      warn "expected:\n#{JSON.pretty_generate(e)}\nactual:\n#{JSON.pretty_generate(a)}"
      exit 1
    ' "$TMP/actual.json" "$GOLDEN/$case_name/expected.json"; then
    echo "ok   - consumer edges $case_name"
  else
    echo "FAIL - consumer edges $case_name"
    failures=$((failures + 1))
  fi
done

# git-revision mode: an unchanged fixture has no added or removed edge.
if "$EDGES" --json --before HEAD "$FIXTURE" | ruby -rjson -e '
    h = JSON.parse(STDIN.read); exit(h["added"].empty? && h["removed"].empty? ? 0 : 1)'; then
  echo "ok   - --before HEAD on unchanged fixture"
else
  echo "FAIL - --before HEAD on unchanged fixture"
  failures=$((failures + 1))
fi

# The caveat is part of every human-readable report.
if "$EDGES" --before HEAD "$FIXTURE" | grep -qF 'note: no usage found != dependency unnecessary'; then
  echo "ok   - caveat line printed"
else
  echo "FAIL - caveat line printed"
  failures=$((failures + 1))
fi

# An unknown revision is a usage error, not an empty result.
"$EDGES" --before no-such-rev-v09 "$FIXTURE" > /dev/null 2>&1
status=$?
if [ "$status" -eq 2 ]; then
  echo "ok   - unknown revision exits 2"
else
  echo "FAIL - unknown revision exits 2 (got $status)"
  failures=$((failures + 1))
fi

[ "$failures" -eq 0 ] && echo "all consumer-edge tests passed" || echo "$failures consumer-edge test(s) failed"
exit "$failures"
