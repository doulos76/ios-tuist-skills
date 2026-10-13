#!/bin/bash
# Re-checks the build-observable entries of references/tuist-known-issues.md
# for one Tuist version, on throwaway copies of tests/fixtures/restyle-candidate.
# Prints "<probe>=<result>" lines; never edits the repository.
# Usage: known-issues-probe.sh <tuist-version>
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${1:?usage: known-issues-probe.sh <tuist-version>}"
FIXTURE="$REPO_ROOT/tests/fixtures/restyle-candidate"
# macOS mktemp ignores TMPDIR unless the template says so.
WORK="$(mktemp -d "${TMPDIR:-/tmp}/known-issues.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

tuist_() { mise exec "tuist@$VERSION" -- tuist "$@"; }

prepare() { # the fixture's own pin is removed so tuist@VERSION is the only version in play
  cp -R "$FIXTURE" "$WORK/$1"
  rm -f "$WORK/$1/.tool-versions"
}

build_app() { # build_app <dir>; log in <dir>/build.log
  (cd "$1" && tuist_ install && tuist_ generate --no-open &&
    xcodebuild -workspace RestyleCandidate.xcworkspace -scheme App \
      -destination 'generic/platform=iOS Simulator' -derivedDataPath "$1/dd" build) > "$1/build.log" 2>&1
}

echo "tuist_version=$(tuist_ version 2>/dev/null | tail -1)"

prepare baseline
if build_app "$WORK/baseline"; then
  echo "restyle-baseline-build=pass"
else
  echo "restyle-baseline-build=fail"
  tail -20 "$WORK/baseline/build.log" >&2
fi

prepare converted
# The documented conversion shape from ios-tuist-restyle, applied to CleanFeature
# (.staticFramework with resources:), the combination behind the static-framework entries.
if ! ruby -e '
  path = ARGV[0]
  s = File.read(path)
  before = %(sources: ["CleanFeature/Sources/**"],\n            resources: ["CleanFeature/Resources/**"])
  after = %(buildableFolders: ["CleanFeature/Sources", "CleanFeature/Resources"])
  n = s.scan(before).size
  abort "conversion anchor found #{n} times" unless n == 1
  File.write(path, s.sub(before, after))
' "$WORK/converted/Project.swift"; then
  echo "cleanfeature-buildablefolders-build=error"
  echo "cleanfeature-resource-in-app=not-run"
  exit 0
fi
if build_app "$WORK/converted"; then
  echo "cleanfeature-buildablefolders-build=pass"
  app="$WORK/converted/dd/Build/Products/Debug-iphonesimulator/App.app"
  if [ -n "$(find "$app" -name dummy.txt -print -quit 2>/dev/null)" ]; then
    echo "cleanfeature-resource-in-app=present"
  else
    echo "cleanfeature-resource-in-app=absent"
  fi
else
  echo "cleanfeature-buildablefolders-build=fail"
  echo "cleanfeature-resource-in-app=not-run"
  tail -20 "$WORK/converted/build.log" >&2
fi
