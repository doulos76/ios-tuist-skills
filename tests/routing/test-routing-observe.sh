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
  local out; out="$("$OBS" ios-tuist-skills /home/u/.claude/plans < "$FIX/$file" 2>&1)"
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
  'selected="none"' 'stop_reason="write-tool"' 'write_path="/work/App/Sources/Feature.swift"' 'tools_before_stop=["Bash","Write"]' 'plan_writes=[]'
check "plan-file write does not stop before a skill" plan-write-then-skill.jsonl \
  'selected="ios-tuist-feature"' 'stop_reason="skill"' 'plan_writes=["/home/u/.claude/plans/p.md"]' 'write_path=null'
check "plan-file write and edit, then result" plan-write-then-result.jsonl \
  'selected="none"' 'stop_reason="result"' 'plan_writes=["/home/u/.claude/plans/p.md","/home/u/.claude/plans/p.md"]' 'write_path=null'
check "sibling directory with the plans prefix still stops" plans-lookalike.jsonl \
  'selected="none"' 'stop_reason="write-tool"' 'write_path="/home/u/.claude/plans-old/p.md"' 'plan_writes=[]'
check "answer without tools" no-tool.jsonl \
  'selected="none"' 'stop_reason="result"' 'cost_usd=0.1023225' 'result_subtype="success"'
check "skill from another plugin" other-skill.jsonl \
  'selected="other:tuist:migrate"' 'stop_reason="skill"'
check "eof without stop event, bad line skipped" truncated.jsonl \
  'selected="none"' 'stop_reason="eof"' 'tools_before_stop=["Bash"]' 'plugin_version=null'
check "skill inside a subagent" nested.jsonl \
  'selected="ios-tuist-module"' 'nested=true' 'tools_before_stop=["Task"]'

# Without a plans-dir argument the default is $CLAUDE_CONFIG_DIR/plans, else $HOME/.claude/plans.
default_out="$(env -u CLAUDE_CONFIG_DIR HOME=/home/u "$OBS" < "$FIX/plan-write-then-skill.jsonl" 2>&1)"
if [ "$(field "$default_out" selected 2>/dev/null)" = '"ios-tuist-feature"' ]; then
  echo "ok   - default plans dir from HOME"
else
  echo "FAIL - default plans dir from HOME: $default_out"; failures=$((failures + 1))
fi
config_out="$(env CLAUDE_CONFIG_DIR=/home/u/.claude HOME=/nowhere "$OBS" < "$FIX/plan-write-then-skill.jsonl" 2>&1)"
if [ "$(field "$config_out" selected 2>/dev/null)" = '"ios-tuist-feature"' ]; then
  echo "ok   - default plans dir from CLAUDE_CONFIG_DIR"
else
  echo "FAIL - default plans dir from CLAUDE_CONFIG_DIR: $config_out"; failures=$((failures + 1))
fi
slash_out="$("$OBS" ios-tuist-skills /home/u/.claude/plans/ < "$FIX/plan-write-then-skill.jsonl" 2>&1)"
if [ "$(field "$slash_out" selected 2>/dev/null)" = '"ios-tuist-feature"' ]; then
  echo "ok   - plans dir with a trailing slash"
else
  echo "FAIL - plans dir with a trailing slash: $slash_out"; failures=$((failures + 1))
fi

# The observer must stop reading at the stop event, so an endless producer is cut off (SIGPIPE).
if perl -e 'alarm 10; exec @ARGV' bash -c "(cat '$FIX/skill-first.jsonl'; yes '{\"type\":\"noop\"}') | '$OBS' > /dev/null"; then
  echo "ok   - stops reading after the stop event"
else
  echo "FAIL - observer did not exit within 10s on an endless stream"; failures=$((failures + 1))
fi

[ "$failures" -eq 0 ] && echo "all routing-observe tests passed" || echo "$failures routing-observe test(s) failed"
exit "$failures"
