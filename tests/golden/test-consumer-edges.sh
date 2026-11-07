#!/bin/bash
# Golden tests for scripts/skill/check-consumer-edges.sh on extract-candidate:
# added local and external edges without and with an import in App.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
EDGES="$REPO_ROOT/scripts/skill/check-consumer-edges.sh"
GOLDEN="$REPO_ROOT/tests/golden/consumer-edges"
FIXTURE="$REPO_ROOT/tests/fixtures/extract-candidate"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/golden-ce.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
failures=0

for case_name in no-usage with-usage external-usage external-no-usage; do
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

# Reversing each overlay reports a removal with the same edge kind.
for case_name in no-usage with-usage external-usage external-no-usage; do
  if "$EDGES" --json --before "$TMP/$case_name" "$FIXTURE" > "$TMP/removed.json" &&
    ruby -rjson -e '
      actual = JSON.parse(File.read(ARGV[0]))
      expected = JSON.parse(File.read(ARGV[1]))
      removed = expected["added"].map { |e| e.reject { |k, _| k == "usage" } }
      exit(actual["added"].empty? && actual["removed"] == removed ? 0 : 1)
    ' "$TMP/removed.json" "$GOLDEN/$case_name/expected.json"; then
    echo "ok   - consumer edges removed $case_name"
  else
    echo "FAIL - consumer edges removed $case_name"
    failures=$((failures + 1))
  fi
done

if "$EDGES" --before "$FIXTURE" "$TMP/external-no-usage" |
    grep -qF 'App -> LogKit: no usage found (external: product name may differ from module name)'; then
  echo "ok   - external name-mismatch caveat"
else
  echo "FAIL - external name-mismatch caveat"
  failures=$((failures + 1))
fi

# Changing only the edge kind must remain visible even with the same name.
cp -R "$TMP/external-no-usage" "$TMP/project-edge"
ruby -e '
  p = ARGV[0]
  File.write(p, File.read(p).sub(%q{.external(name: "LogKit")},
                               %q{.project(target: "LogKit", path: "../LogKit")}))
' "$TMP/project-edge/Project.swift"
if "$EDGES" --json --before "$TMP/project-edge" "$TMP/external-no-usage" > "$TMP/kind.json" &&
  ruby -rjson -e '
    h = JSON.parse(File.read(ARGV[0]))
    exit(h["added"] == [{"from" => "App", "to" => "LogKit", "kind" => "external", "usage" => nil}] &&
         h["removed"] == [{"from" => "App", "to" => "LogKit", "kind" => "project"}] ? 0 : 1)
  ' "$TMP/kind.json"; then
  echo "ok   - same-name project to external edge change"
else
  echo "FAIL - same-name project to external edge change"
  failures=$((failures + 1))
fi

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
