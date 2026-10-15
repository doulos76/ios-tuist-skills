#!/bin/bash
# Regression test for relative --out across the fixture-directory change (no real claude or git).
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
export REPO_ROOT
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
mkdir -p "$T/bin" "$T/home/.claude/plans"
export HOME="$T/home"
unset CLAUDE_CONFIG_DIR

cat > "$T/bin/claude" <<'SH'
#!/bin/bash
if [ "$1" = "--version" ]; then
  echo '2.1.296 (Claude Code)'
else
  cat "$REPO_ROOT/tests/routing/fixtures/skill-first.jsonl"
fi
SH
# The runner records a revision; keep this test entirely independent of real git.
cat > "$T/bin/git" <<'SH'
#!/bin/bash
echo test-revision
SH
chmod +x "$T/bin/claude" "$T/bin/git"
failures=0

check() {
  local name="$1" detail
  shift
  if detail="$("$@" 2>&1)"; then
    echo "ok   - $name"
  else
    echo "FAIL - $name: ${detail:-command failed ($*)}"
    failures=$((failures + 1))
  fi
}

status=0
(cd "$T" && PATH="$T/bin:$PATH" TMPDIR="$T" "$REPO_ROOT/scripts/run-routing-eval.sh" run \
  --condition plugin-only --out rel/out --only pos-archreview-en) > "$T/run.log" 2>&1 || status=$?
check "relative output run exits zero" ruby -e 'abort "exit #{ARGV[0]}" unless ARGV[0] == "0"' "$status"
check "results.jsonl exists" test -f "$T/rel/out/results.jsonl"
check "single result selects architecture review and stops at skill" ruby -rjson -e '
  lines = File.readlines(ARGV[0])
  abort "expected one result, got #{lines.size}" unless lines.size == 1
  row = JSON.parse(lines.first)
  abort "selected=#{row["selected"].inspect}, stop_reason=#{row["stop_reason"].inspect}" unless
    row["selected"] == "ios-tuist-architecture-review" && row["stop_reason"] == "skill"
' "$T/rel/out/results.jsonl"
check "observer receives the plans dir" ruby -rjson -e '
  row = JSON.parse(File.readlines(ARGV[0]).first)
  abort "plan_writes missing: #{row.keys.inspect}" unless row.key?("plan_writes")
' "$T/rel/out/results.jsonl"
check "case stderr exists in caller output directory" test -f "$T/rel/out/stderr/pos-archreview-en.txt"
check "meta.json records Claude and current plugin versions" ruby -rjson -e '
  meta = JSON.parse(File.read(ARGV[0]))
  version = JSON.parse(File.read(ARGV[1])).fetch("version")
  abort "claude_version=#{meta["claude_version"].inspect}" unless meta["claude_version"].to_s.include?("2.1.296")
  abort "expected plugin_version=#{version.inspect}, got #{meta["plugin_version"].inspect}" unless meta["plugin_version"] == version
' "$T/rel/out/meta.json" "$REPO_ROOT/.claude-plugin/plugin.json"

status=0
(cd "$T" && PATH="$T/bin:$PATH" TMPDIR="$T" "$REPO_ROOT/scripts/run-routing-eval.sh" run \
  --condition plugin-only --out codex/out --agent codex) > "$T/codex.log" 2>&1 || status=$?
check "codex agent is reported unsupported (exit 3)" ruby -e 'abort "exit #{ARGV[0]}" unless ARGV[0] == "3"' "$status"
check "unsupported message names the missing event" grep -q 'no skill-selection event' "$T/codex.log"
check "unsupported run writes no results" test ! -e "$T/codex/out/results.jsonl"

if [ "$failures" -eq 0 ]; then
  echo "all run-routing-eval tests passed"
else
  cat "$T/run.log"
  echo "$failures run-routing-eval test(s) failed"
fi
exit "$failures"
