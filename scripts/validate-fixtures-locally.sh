#!/bin/bash
# Reproduces .github/workflows/validate-fixtures.yml locally, fixture by
# fixture, driven by the workflow file's own matrix — not a duplicated
# fixture list — so this script never drifts from CI as fixtures are
# added or the matrix's fields change.
#
# Use this while GitHub Actions credit is exhausted on this repo's
# account (see the "CI credit exhausted" memory), or any time you want
# to validate fixtures without spending Actions minutes.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOW_FILE="$REPO_ROOT/.github/workflows/validate-fixtures.yml"
export XDG_CACHE_HOME=/tmp/tuist-local-validate/cache
export XDG_STATE_HOME=/tmp/tuist-local-validate/state
export XDG_DATA_HOME=/tmp/tuist-local-validate/data
mkdir -p "$XDG_CACHE_HOME" "$XDG_STATE_HOME" "$XDG_DATA_HOME"

# Only run one fixture (e.g. `./scripts/validate-fixtures-locally.sh migrate-candidate`).
ONLY_FIXTURE="${1:-}"

MATRIX_TSV="$(ruby -ryaml -e '
  workflow = YAML.load_file(ARGV[0])
  matrix = workflow.fetch("jobs").fetch("validate").fetch("strategy").fetch("matrix").fetch("include")
  matrix.each do |entry|
    puts [
      entry.fetch("fixture"),
      entry.fetch("tuist").to_s,
      entry.fetch("workspace"),
      entry.fetch("resolve_cmd"),
      entry.fetch("test_schemes"),
    ].join("\t")
  end
' "$WORKFLOW_FILE")"

if [ -z "$MATRIX_TSV" ]; then
  echo "Could not read any matrix entries from $WORKFLOW_FILE" >&2
  exit 1
fi

SIMULATOR_ID="$(xcrun simctl list devices available --json | ruby -rjson -e '
  devices = JSON.parse(STDIN.read).fetch("devices").values.flatten
  iphone = devices.find { |device| device["isAvailable"] && device["name"].start_with?("iPhone") }
  abort "No available iPhone simulator found" unless iphone
  print iphone.fetch("udid")
')"
echo "Using simulator: $SIMULATOR_ID"

RESULTS=()

while IFS=$'\t' read -r fixture tuist_version workspace resolve_cmd test_schemes; do
  if [ -n "$ONLY_FIXTURE" ] && [ "$fixture" != "$ONLY_FIXTURE" ]; then
    continue
  fi

  echo ""
  echo "=================================================================="
  echo "Fixture: $fixture (Tuist $tuist_version, workspace $workspace.xcworkspace, resolve via '$resolve_cmd')"
  echo "=================================================================="

  cd "$REPO_ROOT/tests/fixtures/$fixture" || { RESULTS+=("$fixture: FAIL (cd)"); continue; }

  echo "--- mise install tuist@$tuist_version ---"
  mise install "tuist@$tuist_version" || { RESULTS+=("$fixture: FAIL (mise install)"); continue; }

  actual_version="$(mise exec "tuist@$tuist_version" -- tuist version)"
  if [ "$actual_version" != "$tuist_version" ]; then
    echo "Version pin mismatch: expected $tuist_version, got $actual_version"
    RESULTS+=("$fixture: FAIL (version pin: got $actual_version)")
    continue
  fi

  echo "--- tuist $resolve_cmd ---"
  mise exec "tuist@$tuist_version" -- tuist "$resolve_cmd" || { RESULTS+=("$fixture: FAIL (tuist $resolve_cmd)"); continue; }

  echo "--- tuist generate --no-open ---"
  mise exec "tuist@$tuist_version" -- tuist generate --no-open || { RESULTS+=("$fixture: FAIL (tuist generate)"); continue; }

  echo "--- xcodebuild build (scheme App) ---"
  xcodebuild -workspace "$workspace.xcworkspace" -scheme App \
    -destination 'generic/platform=iOS Simulator' build \
    | tail -20
  if [ "${PIPESTATUS[0]}" -ne 0 ]; then
    RESULTS+=("$fixture: FAIL (xcodebuild build)")
    continue
  fi

  fail=0
  for scheme in $test_schemes; do
    echo "--- xcodebuild test (scheme $scheme) ---"
    xcodebuild test \
      -workspace "$workspace.xcworkspace" \
      -scheme "$scheme" \
      -destination "id=$SIMULATOR_ID" \
      | tail -20
    if [ "${PIPESTATUS[0]}" -ne 0 ]; then
      fail=1
      echo "Test scheme $scheme FAILED"
    fi
  done

  rm -rf "$workspace.xcworkspace" "$workspace.xcodeproj" Derived

  if [ "$fail" -eq 0 ]; then
    RESULTS+=("$fixture: PASS")
  else
    RESULTS+=("$fixture: FAIL (test)")
  fi
done <<< "$MATRIX_TSV"

echo ""
echo "=================================================================="
echo "SUMMARY"
echo "=================================================================="
for r in "${RESULTS[@]}"; do
  echo "$r"
done

for r in "${RESULTS[@]}"; do
  case "$r" in
    *FAIL*) exit 1 ;;
  esac
done
