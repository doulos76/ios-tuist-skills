#!/bin/bash
# Prep one benchmark comparison run: resets the named fixture to a clean
# state, cds into it, and prints the exact prompt to paste into `claude`.
#
# Usage:
#   ./scripts/benchmark-prep-run.sh <fixture> [scenario]
#
# Examples:
#   ./scripts/benchmark-prep-run.sh new-project
#   ./scripts/benchmark-prep-run.sh extract-candidate networking
#   ./scripts/benchmark-prep-run.sh extract-candidate settingsrow
#   ./scripts/benchmark-prep-run.sh restyle-candidate cleanfeature
#   ./scripts/benchmark-prep-run.sh restyle-candidate excludefeature
#   ./scripts/benchmark-prep-run.sh test-target-candidate featurea
#   ./scripts/benchmark-prep-run.sh test-target-candidate featureb
#
# Run this from inside EITHER .worktrees/benchmark-baseline or
# .worktrees/benchmark-with-skill (it operates on the worktree it's run
# from — it never crosses into the other one). After it prints the
# prompt, start the session yourself:
#   - baseline worktree:    claude
#   - with-skill worktree:  claude --plugin-dir /Users/dave/Documents/GitHub/ios-tuist-skills
# then paste the printed prompt verbatim.
set -uo pipefail

FIXTURE="${1:-}"
SCENARIO="${2:-}"

if [ -z "$FIXTURE" ]; then
  echo "Usage: $0 <fixture> [scenario]" >&2
  echo "Run '$0 --list' to see all 14 comparisons." >&2
  exit 1
fi

if [ "$FIXTURE" = "--list" ]; then
  "$(dirname "${BASH_SOURCE[0]}")/benchmark-list-comparisons.sh"
  exit 0
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE_DIR="$REPO_ROOT/tests/fixtures/$FIXTURE"

if [ ! -d "$FIXTURE_DIR" ]; then
  echo "No such fixture: tests/fixtures/$FIXTURE" >&2
  exit 1
fi

# key = "<fixture>" or "<fixture>:<scenario>" (scenario lowercase, no spaces)
key="$FIXTURE"
if [ -n "$SCENARIO" ]; then
  key="$FIXTURE:$(echo "$SCENARIO" | tr '[:upper:]' '[:lower:]')"
fi

case "$key" in
  "new-project")
    PROMPT="Create a new SwiftUI iOS app using Tuist with a feature-modular structure." ;;
  "legacy-tuist")
    PROMPT="Add LoginFeature." ;;
  "version-mismatch")
    PROMPT="Add a simple settings screen to this project." ;;
  "modular")
    PROMPT="Add Kingfisher only to ProfileFeature." ;;
  "extract-candidate:networking")
    PROMPT="Extract the networking code into its own module called NetworkingKit." ;;
  "extract-candidate:settingsrow")
    PROMPT="Extract SettingsRow into its own module." ;;
  "architecture-smells")
    PROMPT="Review this project's architecture." ;;
  "ci-gaps")
    PROMPT="Check the CI workflow for tests/fixtures/ci-gaps." ;;
  "migrate-candidate")
    PROMPT="Migrate this project's Tuist manifests from 3.42.2 to 4.206.0." ;;
  "restyle-candidate:cleanfeature")
    PROMPT="Review CleanFeature's folder integration and switch it to buildable folders if it's safe." ;;
  "restyle-candidate:excludefeature")
    PROMPT="Review ExcludeFeature's folder integration and switch it to buildable folders if it's safe." ;;
  "test-target-candidate:featurea")
    PROMPT="Create a unit test target for FeatureA and wire it into the existing App scheme." ;;
  "test-target-candidate:featureb")
    PROMPT="Create a unit test target for FeatureB and wire it into the existing App scheme." ;;
  "scaffold-candidate")
    PROMPT="Add a scaffold template that generates a labeled-enum Swift file from a name." ;;
  *)
    echo "Unknown fixture/scenario combination: '$key'" >&2
    echo "Run '$0 --list' to see all 14 valid combinations." >&2
    exit 1
    ;;
esac

echo "== Resetting tests/fixtures/$FIXTURE in $(basename "$REPO_ROOT") =="
git -C "$REPO_ROOT" checkout -- "tests/fixtures/$FIXTURE"
git -C "$REPO_ROOT" clean -fd "tests/fixtures/$FIXTURE"

CONDITION="baseline"
case "$REPO_ROOT" in
  *benchmark-with-skill) CONDITION="with-skill" ;;
esac

echo
echo "== Condition: $CONDITION =="
echo "== cd: $FIXTURE_DIR =="
echo
echo "Next steps:"
echo "  cd \"$FIXTURE_DIR\""
if [ "$CONDITION" = "with-skill" ]; then
  echo "  claude --plugin-dir /Users/dave/Documents/GitHub/ios-tuist-skills"
else
  echo "  claude"
fi
echo
echo "Paste this prompt verbatim once the session starts:"
echo "----------------------------------------------------------------"
echo "$PROMPT"
echo "----------------------------------------------------------------"
echo
echo "After the response finishes, capture (from a separate terminal,"
echo "without cd'ing away from $FIXTURE_DIR):"
echo "  git -C \"$REPO_ROOT\" diff -- \"tests/fixtures/$FIXTURE\""
echo "then save the transcript + diff + any re-run build/test output into:"
echo "  .worktrees/benchmark-report/docs/superpowers/benchmarks/2026-09-20-skill-effectiveness/raw/${FIXTURE}${SCENARIO:+-$SCENARIO}-$CONDITION.md"
