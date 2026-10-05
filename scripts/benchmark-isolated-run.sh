#!/bin/bash
# Prep an isolated fixture copy, then collect metrics after a manual session.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)" || exit 1

usage() {
  echo "Usage: $0 prep <fixture> <baseline|with-skill> <run-N> [--plugin-dir DIR]" >&2
  echo "       $0 collect <fixture> <baseline|with-skill> <run-N>" >&2
  echo "Run number: N or run-N (positive integer). collect requires BENCH_DIR=<date>-<name>." >&2
  exit 2
}

[ "$#" -ge 4 ] || usage
command="$1"
fixture="$2"
condition="$3"
run="${4#run-}"
shift 4
case "$command" in prep|collect) ;; *) usage ;; esac
case "$fixture" in ""|*[!a-zA-Z0-9_-]*) usage ;; esac
case "$condition" in baseline|with-skill) ;; *) usage ;; esac
case "$run" in ""|*[!0-9]*|0*) usage ;; esac
PLUGIN_DIR="${PLUGIN_DIR:-}"
if [ "$command" = prep ] && [ "$#" -eq 2 ] && [ "$1" = --plugin-dir ]; then
  PLUGIN_DIR="$2"
  shift 2
fi
[ "$#" -eq 0 ] || usage
SRC="$REPO_ROOT/tests/fixtures/$fixture"
[ -d "$SRC" ] || { echo "No such fixture: tests/fixtures/$fixture" >&2; exit 2; }
if [ "$command" = collect ]; then
  [ -n "${BENCH_DIR:-}" ] || usage
  case "$BENCH_DIR" in .|..|*[!a-zA-Z0-9._-]*) usage ;; esac
fi
if [ "$command" = prep ] && [ "$condition" = with-skill ]; then
  [ -n "$PLUGIN_DIR" ] || usage
  PLUGIN_DIR="$(cd "$PLUGIN_DIR" && pwd -P)" || exit 2
fi
TMP_ROOT="$(cd "${TMPDIR:-/tmp}" && pwd -P)" || exit 1
STATE="$TMP_ROOT/state-$fixture-$condition-run$run"

isolation_guard() {
  local path
  WORKDIR="$(cd "$WORKDIR" && pwd -P)" || return 1
  case "$WORKDIR" in
    "$REPO_ROOT"|"$REPO_ROOT"/*)
      echo "ISOLATION VIOLATION: $WORKDIR" >&2
      return 1 ;;
  esac
  path="$WORKDIR"
  while :; do
    if { [ -d "$path/skills" ] && [ -d "$path/references" ]; } || [ -e "$path/CLAUDE.md" ]; then
      echo "ISOLATION VIOLATION: $path" >&2
      return 1
    fi
    [ "$path" = / ] && break
    path="$(dirname "$path")"
  done
}

# Relative, sorted paths keep snapshots comparable; Ruby avoids GNU grep flags.
snapshot_edges() {
  ruby -e '
    Dir.chdir(ARGV[0]) do
      Dir.glob("**/{Project,Tuist,Package}.swift", File::FNM_DOTMATCH).sort.each do |path|
        next if path.split("/").include?(".git") || !File.file?(path)
        File.foreach(path).with_index(1) do |line, number|
          puts "#{path}:#{number}:#{line.chomp}" if line.match?(/dependencies|\.target\(|\.project\(|\.external\(/)
        end
      end
    end
  ' "$WORKDIR"
}

if [ "$command" = prep ]; then
  [ ! -e "$STATE" ] || { echo "State already exists: $STATE; use a fresh run number." >&2; exit 2; }
  WORKDIR_PARENT="$(mktemp -d "$TMP_ROOT/tuist-bench.XXXXXX")" || exit 1
  WORKDIR="$WORKDIR_PARENT/$fixture"
  cp -R "$SRC" "$WORKDIR" || exit 1
  if ! isolation_guard; then
    rm -rf -- "$WORKDIR_PARENT"
    exit 1
  fi
  git -C "$WORKDIR" init -q &&
    git -C "$WORKDIR" add -A &&
    git -C "$WORKDIR" -c user.name=bench -c user.email=bench@example.invalid commit -qm baseline || exit 1
  snapshot_edges > "$WORKDIR/../edges-before.txt" || exit 1
  printf '%s\n' "$WORKDIR" > "$STATE" || exit 1
  printf '%s\n' "${PLUGIN_DIR:-$REPO_ROOT}" > "$STATE.plugin-dir" || exit 1
  echo "Workdir: $WORKDIR"
  # The user-scope installed plugin would otherwise leak into the baseline.
  printf 'cd %q && claude --setting-sources project' "$WORKDIR"
  if [ "$condition" = with-skill ]; then
    printf ' --plugin-dir %q' "$PLUGIN_DIR"
  fi
  printf '\nCollect (from another terminal, with BENCH_DIR set):\n'
  printf '%q collect %q %q %q\n' "$REPO_ROOT/scripts/benchmark-isolated-run.sh" "$fixture" "$condition" "$run"
  exit 0
fi

[ -f "$STATE" ] && [ -f "$STATE.plugin-dir" ] || { echo "No saved prep state: $STATE" >&2; exit 2; }
IFS= read -r WORKDIR < "$STATE" || exit 1
IFS= read -r PLUGIN_DIR < "$STATE.plugin-dir" || exit 1
isolation_guard || exit 1
MATRIX_FILE="$REPO_ROOT/tests/fixtures/ci-matrix.json"
MATRIX_TSV="$(ruby -rjson -e '
  JSON.parse(File.read(ARGV[0])).each do |entry|
    next unless entry.fetch("fixture") == ARGV[1]
    puts [
      entry.fetch("fixture"),
      entry.fetch("tuist").to_s,
      entry.fetch("workspace"),
      entry.fetch("resolve_cmd"),
      entry.fetch("test_schemes"),
    ].join("\t")
  end
' "$MATRIX_FILE" "$fixture")" || exit 1
OUTPUT_DIR="$REPO_ROOT/docs/superpowers/benchmarks/$BENCH_DIR/raw"
mkdir -p "$OUTPUT_DIR" || exit 1
REPORT="$OUTPUT_DIR/$fixture-$condition-run$run.md"
cd "$WORKDIR" || exit 1
resolve=skipped
generate=skipped
build=skipped
test=skipped
{
  echo "# $fixture — $condition — run$run"
  echo
  echo "Date: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  echo "Condition: $condition"
  echo "Claude: $(claude --version 2>&1)"
  echo "Model: ${BENCH_MODEL:-unrecorded}"
  echo "Workdir: $WORKDIR"
  if [ "$condition" = baseline ]; then
    echo 'Plugin repo: none (baseline)'
    echo 'Plugin revision: n/a'
  else
    echo "Plugin repo: $PLUGIN_DIR"
    echo "Plugin revision: $(git -C "$PLUGIN_DIR" rev-parse HEAD 2>&1)"
  fi
  echo
  echo '```text'
  echo '--- git diff --stat HEAD ---'
  git diff --stat HEAD
  echo '--- changed-file count (including untracked) ---'
  git status --porcelain | wc -l
  snapshot_edges > "$WORKDIR/../edges-after.txt" || exit 1
  echo '--- dependency edges (before / after) ---'
  diff "$WORKDIR/../edges-before.txt" "$WORKDIR/../edges-after.txt"
  edge_status="$?"
  [ "$edge_status" -le 1 ] || exit 1
  if [ -n "$MATRIX_TSV" ]; then
    IFS=$'\t' read -r fixture tuist_version workspace resolve_cmd test_schemes <<< "$MATRIX_TSV"
    echo "--- mise exec -- tuist $resolve_cmd ---"
    resolve=fail
    if mise exec -- tuist "$resolve_cmd"; then
      resolve=pass
    fi
  else
    echo 'Resolve skipped: fixture has no CI matrix entry.'
  fi
  if [ "$resolve" = fail ]; then
    echo 'Generate/build/test skipped: dependency resolution failed.'
  elif {
    echo '--- mise exec -- tuist generate --no-open ---'
    generate=fail
    mise exec -- tuist generate --no-open
  }; then
    generate=pass
    if [ -n "$MATRIX_TSV" ]; then
      echo '--- xcodebuild build (scheme App) ---'
      xcodebuild -workspace "$workspace.xcworkspace" -scheme App \
        -destination 'generic/platform=iOS Simulator' build \
        | tail -20
      if [ "${PIPESTATUS[0]}" -eq 0 ]; then
        build=pass
        if [ -n "$test_schemes" ]; then
          SIMULATOR_ID="$(xcrun simctl list devices available --json | ruby -rjson -e '
            devices = JSON.parse(STDIN.read).fetch("devices").values.flatten
            iphone = devices.find { |device| device["isAvailable"] && device["name"].start_with?("iPhone") }
            abort "No available iPhone simulator found" unless iphone
            print iphone.fetch("udid")
          ')"
          if [ -n "$SIMULATOR_ID" ]; then
            test=pass
            for scheme in $test_schemes; do
              echo "--- xcodebuild test (scheme $scheme) ---"
              xcodebuild test \
                -workspace "$workspace.xcworkspace" \
                -scheme "$scheme" \
                -destination "id=$SIMULATOR_ID" \
                | tail -20
              if [ "${PIPESTATUS[0]}" -ne 0 ]; then
                test=fail
              fi
            done
          else
            echo 'Tests skipped: no available iPhone simulator.'
          fi
        fi
      else
        build=fail
      fi
    else
      echo 'Build/test skipped: fixture has no CI matrix entry; no workspace/schemes invented.'
    fi
  fi
  echo '```'
  echo
  echo "Resolve: $resolve"
  echo "Generate: $generate"
  echo "Build: $build"
  echo "Test: $test"
} > "$REPORT" 2>&1
echo "Report: $REPORT"
if [ "$resolve" = fail ] || [ "$generate" = fail ] || [ "$build" = fail ] || [ "$test" = fail ]; then
  exit 1
fi
