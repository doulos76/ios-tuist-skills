#!/bin/bash
# prep must not leave EXPECTATIONS.md (the grader's answer key) in the agent's workdir.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
fail=0
out="$(TMPDIR="$T" "$ROOT/scripts/benchmark-isolated-run.sh" prep extract-candidate baseline 990 2>&1)"
work="$(printf '%s\n' "$out" | sed -n 's/^Workdir: //p')"
if [ -n "$work" ] && [ -d "$work" ]; then echo "ok   - prep created workdir"; else echo "FAIL - prep created workdir: $out"; fail=1; fi
if [ -n "$work" ] && [ ! -e "$work/EXPECTATIONS.md" ]; then echo "ok   - EXPECTATIONS.md absent"; else echo "FAIL - EXPECTATIONS.md absent"; fail=1; fi
if [ -n "$work" ] && [ -z "$(git -C "$work" ls-files EXPECTATIONS.md)" ]; then echo "ok   - not in baseline commit"; else echo "FAIL - not in baseline commit"; fail=1; fi
if [ -n "$work" ] && [ -f "$work/Project.swift" ]; then echo "ok   - fixture content copied"; else echo "FAIL - fixture content copied"; fail=1; fi
[ "$fail" -eq 0 ] && echo "all prep tests passed"
exit "$fail"
