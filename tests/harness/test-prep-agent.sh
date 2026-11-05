#!/bin/bash
# prep --agent: Codex with-skill gets project skills in .agents/skills; Claude stays the default.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd -P)"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
T="$(cd "$T" && pwd -P)"
fail=0
ok() { echo "ok   - $1"; }
bad() { echo "FAIL - $1"; fail=1; }
workdir_of() { printf '%s\n' "$1" | sed -n 's/^Workdir: //p'; }

out="$(TMPDIR="$T" "$ROOT/scripts/benchmark-isolated-run.sh" prep modular with-skill 991 --plugin-dir "$ROOT" --agent codex 2>&1)"
work="$(workdir_of "$out")"
if [ -n "$work" ] && [ -f "$work/.agents/skills/ios-tuist-feature/SKILL.md" ]; then ok "codex with-skill installs project skills"; else bad "codex with-skill installs project skills: $out"; fi
if [ -n "$work" ] && [ -z "$(git -C "$work" status --porcelain)" ]; then ok "project skills are in the baseline commit"; else bad "project skills are in the baseline commit"; fi
if [ -n "$work" ] && [ -s "$work/../edges-before.txt" ] && ! grep -q '\.agents/' "$work/../edges-before.txt"; then ok "edge snapshot ignores .agents"; else bad "edge snapshot ignores .agents"; fi
if printf '%s\n' "$out" | grep -q 'codex --disable plugins'; then ok "prints the codex command"; else bad "prints the codex command: $out"; fi
if [ "$(cat "$T/state-modular-with-skill-run991.agent" 2>/dev/null)" = codex ]; then ok "state records the agent"; else bad "state records the agent"; fi

out="$(TMPDIR="$T" "$ROOT/scripts/benchmark-isolated-run.sh" prep modular baseline 992 --agent codex 2>&1)"
work="$(workdir_of "$out")"
if [ -n "$work" ] && [ ! -e "$work/.agents" ]; then ok "codex baseline has no project skills"; else bad "codex baseline has no project skills: $out"; fi

out="$(TMPDIR="$T" "$ROOT/scripts/benchmark-isolated-run.sh" prep modular baseline 993 2>&1)"
if printf '%s\n' "$out" | grep -q 'claude --setting-sources project' &&
  [ "$(cat "$T/state-modular-baseline-run993.agent" 2>/dev/null)" = claude ]; then
  ok "default agent is claude"
else
  bad "default agent is claude: $out"
fi

status=0
TMPDIR="$T" "$ROOT/scripts/benchmark-isolated-run.sh" prep modular baseline 994 --agent gemini > /dev/null 2>&1 || status=$?
if [ "$status" -eq 2 ]; then ok "unknown agent is a usage error"; else bad "unknown agent exit $status (want 2)"; fi

[ "$fail" -eq 0 ] && echo "all prep --agent tests passed"
exit "$fail"
