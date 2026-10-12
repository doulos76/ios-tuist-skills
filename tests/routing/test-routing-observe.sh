#!/bin/bash
# Unit tests for scripts/routing-observe.sh against canned stream-json (claude 2.1.296 shapes).
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OBS="$REPO_ROOT/scripts/routing-observe.sh"
FIX="$REPO_ROOT/tests/routing/fixtures"
failures=0

# field <json> <key> : prints the value as JSON
field() { ruby -rjson -e 'puts JSON.generate(JSON.parse(ARGV[0])[ARGV[1]])' "$1" "$2"; }
check() {
  local name="$1" file="$2"; shift 2
  local out; out="$("$OBS" < "$FIX/$file" 2>&1)"
  local ok=1 pair key want got
  for pair in "$@"; do
    key="${pair%%=*}"; want="${pair#*=}"
    got="$(field "$out" "$key" 2>/dev/null)"
    [ "$got" = "$want" ] || { ok=0; echo "FAIL - $name: $key expected $want, got $got (output: $out)"; }
  done
  if [ "$ok" -eq 1 ]; then echo "ok   - $name"; else failures=$((failures + 1)); fi
}

check "skill as first tool" skill-first.jsonl \
  'selected="ios-tuist-architecture-review"' 'stop_reason="skill"' 'plugin_version="0.8.1"' \
  'claude_code_version="2.1.296"' 'tools_before_stop=[]' 'nested=false'
check "explore then skill" explore-then-skill.jsonl \
  'selected="ios-tuist-feature"' 'stop_reason="skill"' 'tools_before_stop=["Bash","Read"]'
check "write before any skill" write-first.jsonl \
  'selected="none"' 'stop_reason="write-tool"' 'write_path="/home/u/.claude/plans/p.md"' 'tools_before_stop=["Bash","Write"]'
check "answer without tools" no-tool.jsonl \
  'selected="none"' 'stop_reason="result"' 'cost_usd=0.1023225' 'result_subtype="success"'
check "skill from another plugin" other-skill.jsonl \
  'selected="other:tuist:migrate"' 'stop_reason="skill"'
check "eof without stop event, bad line skipped" truncated.jsonl \
  'selected="none"' 'stop_reason="eof"' 'tools_before_stop=["Bash"]' 'plugin_version=null'
check "skill inside a subagent" nested.jsonl \
  'selected="ios-tuist-module"' 'nested=true' 'tools_before_stop=["Task"]'

# The observer must stop reading at the stop event, so an endless producer is cut off (SIGPIPE).
if perl -e 'alarm 10; exec @ARGV' bash -c "(cat '$FIX/skill-first.jsonl'; yes '{\"type\":\"noop\"}') | '$OBS' > /dev/null"; then
  echo "ok   - stops reading after the stop event"
else
  echo "FAIL - observer did not exit within 10s on an endless stream"; failures=$((failures + 1))
fi

[ "$failures" -eq 0 ] && echo "all routing-observe tests passed" || echo "$failures routing-observe test(s) failed"
exit "$failures"
