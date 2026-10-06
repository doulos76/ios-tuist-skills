#!/bin/bash
# Fails when a fixture's .tool-versions tuist pin differs from the
# tests/fixtures/ci-matrix.json. Fixtures are copied out of the repo for
# isolated benchmarks, so the pin must live inside each fixture, and CI
# must not drift from it.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MATRIX_FILE="$REPO_ROOT/tests/fixtures/ci-matrix.json"
status=0

while IFS=$'\t' read -r fixture tuist; do
  pin_file="$REPO_ROOT/tests/fixtures/$fixture/.tool-versions"
  if [ ! -f "$pin_file" ]; then
    echo "MISSING  $fixture: no .tool-versions"
    status=1
    continue
  fi
  pinned="$(awk '$1 == "tuist" { print $2 }' "$pin_file")"
  if [ "$pinned" != "$tuist" ]; then
    echo "MISMATCH $fixture: matrix=$tuist .tool-versions=${pinned:-none}"
    status=1
  fi
done < <(ruby -rjson -e '
  JSON.parse(File.read(ARGV[0])).each do |e|
    puts [e.fetch("fixture"), e.fetch("tuist").to_s].join("\t")
  end
' "$MATRIX_FILE")

[ "$status" -eq 0 ] && echo "All fixture pins match the CI matrix."
exit "$status"
