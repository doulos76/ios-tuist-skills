#!/bin/bash
# Golden tests for scripts/skill/collect-version-evidence.sh. Command evidence
# (active versions) is environment-dependent, so comparisons run with
# --no-commands and drop project_root (user decision 2026-10-13).
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
COLLECT="$REPO_ROOT/scripts/skill/collect-version-evidence.sh"
GOLDEN="$REPO_ROOT/tests/golden/version-evidence"
# macOS mktemp ignores TMPDIR without a template.
TMP="$(mktemp -d "${TMPDIR:-/tmp}/golden-ve.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
failures=0

# compare <name> <expected.json> <project dir>
compare() {
  local name="$1" expected="$2" dir="$3"
  if "$COLLECT" --json --no-commands "$dir" > "$TMP/actual.json" 2> "$TMP/err" &&
    ruby -rjson -e '
      actual = JSON.parse(File.read(ARGV[0]))
      actual.delete("project_root")
      actual.delete("commands")
      expected = JSON.parse(File.read(ARGV[1]))
      exit 0 if actual == expected
      warn "expected:\n#{JSON.pretty_generate(expected)}\nactual:\n#{JSON.pretty_generate(actual)}"
      exit 1
    ' "$TMP/actual.json" "$expected"; then
    echo "ok   - $name"
  else
    echo "FAIL - $name"
    cat "$TMP/err" >&2
    failures=$((failures + 1))
  fi
}

# Every fixture in the CI matrix has an in-fixture pin (v0.8 WS3).
for fixture in $(ruby -rjson -e 'puts JSON.parse(File.read(ARGV[0])).map { |e| e["fixture"] }' "$REPO_ROOT/tests/fixtures/ci-matrix.json"); do
  compare "fixture $fixture" "$GOLDEN/$fixture.expected.json" "$REPO_ROOT/tests/fixtures/$fixture"
done

# Synthetic cases: inputs are created here so no pin file lives in the repo
# outside tests/fixtures (mise would pick it up when someone cd's there).
synthetic() {
  local name="$1"
  mkdir -p "$TMP/$name"
  printf '%s' "$TMP/$name"
}

d="$(synthetic no-pin)"
compare "synthetic no-pin" "$GOLDEN/synthetic/no-pin.expected.json" "$d"

d="$(synthetic mise-vs-tool-versions)"
printf '[tools]\ntuist = "4.206.0"\n' > "$d/mise.toml"
printf 'tuist 4.62.0\n' > "$d/.tool-versions"
compare "synthetic mise-vs-tool-versions" "$GOLDEN/synthetic/mise-vs-tool-versions.expected.json" "$d"

d="$(synthetic tuist-version-only)"
printf '3.42.2\n' > "$d/.tuist-version"
compare "synthetic tuist-version-only" "$GOLDEN/synthetic/tuist-version-only.expected.json" "$d"

d="$(synthetic tuist-version-conflict)"
printf 'tuist 4.206.0\n' > "$d/.tool-versions"
printf '3.42.2\n' > "$d/.tuist-version"
compare "synthetic tuist-version-conflict" "$GOLDEN/synthetic/tuist-version-conflict.expected.json" "$d"

d="$(synthetic config-swift-3x)"
printf 'tuist 3.42.2\n' > "$d/.tool-versions"
mkdir -p "$d/Tuist"
cat > "$d/Tuist/Config.swift" <<'SWIFT'
import ProjectDescription

let config = Config(
    swiftVersion: "5.5"
)
SWIFT
compare "synthetic config-swift-3x" "$GOLDEN/synthetic/config-swift-3x.expected.json" "$d"

tuist_swift_with_swift_version() {
  cat > "$1/Tuist.swift" <<'SWIFT'
import ProjectDescription

let tuist = Tuist(
    project: .tuist(
        compatibleXcodeVersions: .upToNextMajor("16.0"),
        swiftVersion: "5.9"
    )
)
SWIFT
}

d="$(synthetic tuist-swift-4-206-0)"
printf 'tuist 4.206.0\n' > "$d/.tool-versions"
tuist_swift_with_swift_version "$d"
compare "synthetic tuist-swift-4-206-0" "$GOLDEN/synthetic/tuist-swift-4-206-0.expected.json" "$d"

d="$(synthetic tuist-swift-4-62-0)"
printf 'tuist 4.62.0\n' > "$d/.tool-versions"
tuist_swift_with_swift_version "$d"
compare "synthetic tuist-swift-4-62-0" "$GOLDEN/synthetic/tuist-swift-4-62-0.expected.json" "$d"

d="$(synthetic swift-version-no-pin)"
tuist_swift_with_swift_version "$d"
compare "synthetic swift-version-no-pin" "$GOLDEN/synthetic/swift-version-no-pin.expected.json" "$d"

# Human output: an empty project must say "none detected", never blank/latest.
if "$COLLECT" --no-commands "$TMP/no-pin" | grep -q '^Effective project version: *none detected$'; then
  echo "ok   - human output says none detected"
else
  echo "FAIL - human output says none detected"
  failures=$((failures + 1))
fi

# Live commands are recorded with their cwd (values are not compared).
if "$COLLECT" --json "$TMP/no-pin" > "$TMP/cmds.json" && ruby -rjson -e '
    h = JSON.parse(File.read(ARGV[0]))
    names = h["commands"].map { |c| c["cmd"] }
    exit 1 unless names == ["tuist version", "xcodebuild -version", "swift --version"]
    exit 1 unless h["commands"].all? { |c| c["cwd"] == h["project_root"] && c.key?("exit") }
  ' "$TMP/cmds.json"; then
  echo "ok   - live commands recorded with cwd"
else
  echo "FAIL - live commands recorded with cwd"
  failures=$((failures + 1))
fi

[ "$failures" -eq 0 ] && echo "all version-evidence tests passed" || echo "$failures version-evidence test(s) failed"
exit "$failures"
