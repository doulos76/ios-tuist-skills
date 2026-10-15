# ios-tuist-skills v0.9.x Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Implementation owner: Codex.** This repo's Claude session produced the
> research and this plan. Codex's `workspace-write` sandbox cannot
> `git commit`, reach the network, or run `mise`/`tuist`/`xcodebuild`/`claude`/`codex`;
> steps marked **[hand-off]** are run by Claude or the user, and Codex
> continues from their pasted output. Steps marked **[Claude]** are research
> or writing done by Claude, not Codex.

**Goal:** Finish the v0.9 follow-ups, ordered so everything that can run unattended comes first: fix the routing stop rule for plan-mode plan files, add `--agent claude|codex` to the harnesses, add the large-graph fixture (WS-F), then the paid runs (routing re-baseline, WS-F trial), then the decision work (WS-G hooks), then release v0.9.1.

**Architecture:** Same bash + Ruby-stdlib scripts as v0.9.0. The routing observer learns the plans directory and records plan-file writes instead of stopping. The isolated benchmark harness records which agent ran; for Codex with-skill runs it installs the self-contained skill folders as Codex project skills (`.agents/skills`). The new fixture is a synthetic 16-target Tuist 4.206.0 project whose three SwiftPM packages are local path packages, so CI needs no network.

**Tech Stack:** bash 3.2, Ruby 2.6 stdlib, GitHub Actions (ubuntu-latest lint, macos-15 fixtures), mise, Tuist 4.206.0, Xcode (Swift Testing), Claude Code 2.1.296 headless, Codex CLI 0.160.0.

**Spec:** `docs/superpowers/specs/2026-10-02-ios-tuist-skills-v0.9-design.md` (PRD) §WS-C (routing), §WS-F, §WS-G, §6 open questions 3 and 4; plus the v0.9.0 CHANGELOG "Known limitations". PRD §0 working rules apply.

## Order: automation first

| Phase | Task | Runs unattended? | Usage | Needs the user for |
|---|---|---|---|---|
| A | 1. Routing stop rule ignores plan-file writes | yes (Codex + CI) | $0 | merge |
| A | 2. `--agent claude\|codex` in both harnesses | yes, plus one Codex check | $0 (Codex subscription) | merge |
| A | 3. WS-F `large-graph` fixture | yes (Codex + local build + CI) | $0 | merge |
| B | 4. Routing re-baseline with the fixed observer | yes, once started | Claude Max plan usage; capped at $13.50 equivalent (45 × $0.30) | go-ahead when plan usage allows; pass-threshold decision |
| B | 5. WS-F trial run (3 scenarios × Claude, Codex) | yes, once started | Claude Max plan usage, capped at $9 equivalent (3 × $3) + Codex subscription | go-ahead when plan usage allows |
| C | 6. WS-G hooks decision record | research yes, decision no | $0 | adopt / defer / reject |
| C | 7. Release v0.9.1 | no | $0 | merges, tag and Release |

Usage note: `claude` here is logged in with the user's Claude Max subscription (user, 2026-10-16), so headless runs draw on plan usage limits; the dollar caps are `--max-budget-usd` values (`total_cost_usd` equivalents), not separate charges.

Phase A tasks are independent of each other (different files) and can be merged in any order. Task 4 needs Task 1 merged. Task 5 needs Tasks 2 and 3 merged. Task 6 is independent. Task 7 comes last.

## Global Constraints

- Base: `develop` at `a9299a2` or later. One branch and one PR per task into `develop`: `fix/v0.9.x-routing-plan-writes`, `feature/v0.9.x-agent-arg`, `feature/v0.9.x-large-graph`, `docs/v0.9.x-routing-rebaseline`, `docs/v0.9.x-ws-f-trial`, `docs/v0.9.x-hooks-decision`, `chore/release-0.9.1`.
- Skill Decision Rules and SKILL.md files do not change in this plan (PRD §0.5). No skill `description:` changes, so the routing rule in README ("re-run on description change") is not triggered by Tasks 1-3.
- Bash 3.2-compatible (`#!/bin/bash`, no associative arrays, `mapfile`, `${x,,}`); Ruby 2.6-compatible stdlib only (macOS `/usr/bin/ruby` 2.6.10). Run every test once with `PATH=/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin` so `/usr/bin/ruby` is used.
- Tests print `ok   - <name>` / `FAIL - <name>: <detail>` and exit non-zero on any FAIL.
- New unit tests are steps of the required `ci scripts` job in `.github/workflows/lint.yml`.
- Required checks on `develop` and `main`: `fixtures-ok`, `ci scripts`, `golden tests`, `skill resources` (strict). `delete_branch_on_merge` is on.
- On develop→main PRs, wait for every check, not only the required ones: `fixtures-ok` can pass from the skipped-matrix run before the real matrix finishes.
- Every new file: run `git check-ignore -v <file>` before committing; the repo ignores `*.log`, `*.xcodeproj`, `.build/`, `Tuist/.build/`, `Derived/`.
- No company code in fixtures (PRD WS-F). Fixture packages are local path packages; `tuist install` must not need the network.
- Never claim a result without pasted output. Anything not run goes under "Unverified" in the PR body.
- Commit messages: Conventional Commits, ending with the attribution line of the session that commits.

## Evidence this plan relies on (checked 2026-10-16)

1. **Plan-file stops.** In `docs/superpowers/benchmarks/2026-10-13-routing/plugin-only/results.jsonl`, 7 of 45 cases stopped with `stop_reason: "write-tool"` and a `write_path` under `~/.claude/plans/` (`adj-feature-not-module`, `off-migrate-xcode-ko`, `off-generate-and-test`, `amb-latest-ko`, `amb-latest-tooling`, `amb-version-warning-ko`, `amb-modernize`). Plan mode (`--permission-mode plan`) writes its plan file there; that is planning, not acting without a skill. Only `adj-feature-not-module` (expected `ios-tuist-feature`) is a miss that may change; the other six expect `none`.
2. **Local path packages work offline on Tuist 4.206.0.** A scratch project with `Tuist/Package.swift` → `.package(path: "../Packages/LogKit")`, `PackageSettings(productTypes:)` and `.external(name: "LogKit")` passed `tuist install`, `tuist generate --no-open` and `xcodebuild build` (exit 0).
3. **The Task 3 fixture was built and tested.** The generator in Task 3 Step 1, run into a scratch directory: install, generate, `App` build and `xcodebuild test` for schemes `App`, `HomeFeature`, `CheckoutFeature`, `CatalogDomain`, `CoreNetworking` all exit 0 (6 tests). `xcodebuild -list` shows one scheme per non-test target (test targets have no scheme of their own). `git check-ignore --no-index` ignores none of its 32 files.
4. **Every code block in Tasks 1-3 was dry-run** in a `git archive HEAD` copy of `develop` `a9299a2`, in this plan's step order, with `/usr/bin/ruby` 2.6.10: new tests fail before the implementation step (Task 1: observer 12, summarize 2, run-routing-eval 1 FAIL lines; Task 2: prep-agent 7, run-routing-eval 2) and all suites pass after it, including `scripts/run-golden-tests.sh`, `check-fixture-pins.sh`, `tests/ci/test-select-fixtures.sh`, `tests/known-issues/test-known-issues.sh` and `check-routing-cases.sh`.
5. **Codex 0.160.0 flags** (`codex --help`, `codex exec --help`, `codex features list`): `--disable <FEATURE>` exists on both; feature `plugins` is `stable true`; `--ignore-user-config` skips `config.toml` but keeps auth; feature `plugin_hooks` is listed as `removed` (input for Task 6). Codex project skills live in `.agents/skills` (v0.9 research, codex-rs `ext/skills`). Whether `codex --disable plugins` still loads `.agents/skills` is **not yet verified** — Task 2 Step 7 checks it.
6. **`scripts/skill/check-consumer-edges.sh`** attributes edges by parsing inline `.target(name: ...)` blocks (line 92, 97), so the fixture declares every target inline (no helper functions).

## Review Focus

1. A plans directory given with a trailing slash, or taken from `CLAUDE_CONFIG_DIR` instead of `HOME`, must still match plan files; a sibling such as `~/.claude/plans-old/` must not. (Task 1 tests.)
2. Results written before Task 1 have no `plan_writes` field; `summarize` must still work on them (the 2026-10-13 baseline). (Task 1: four of the five sample rows have no field.)
3. A benchmark state written before Task 2 has no `.agent` file; `collect` must treat it as a Claude run. (Task 2 code comment; `collect` is not unit-tested because it runs tuist and xcodebuild — Claude checks it in Task 5.)
4. Codex with-skill copies ten skill folders, including bootstrap templates that contain `Project.swift`; the dependency-edge snapshot must not count them. (Task 2 test "edge snapshot ignores .agents", checked to fail without the exclusion.)
5. The large fixture must stay offline and deterministic in CI; a package reached over the network would make `tuist install` flaky. (Task 3: local path packages; CI run on the PR.)

---

### Task 1: Routing stop rule ignores plan-mode plan files (Phase A)

**Files:**
- Modify: `scripts/routing-observe.sh` (replaced whole), `scripts/run-routing-eval.sh` (observer call, summary)
- Modify: `tests/routing/test-routing-observe.sh`, `tests/routing/test-routing-summarize.sh`, `tests/routing/test-run-routing-eval.sh`, `tests/routing/fixtures/write-first.jsonl`, `tests/routing/fixtures/results-sample.jsonl`
- Create: `tests/routing/fixtures/plan-write-then-skill.jsonl`, `tests/routing/fixtures/plan-write-then-result.jsonl`, `tests/routing/fixtures/plans-lookalike.jsonl`

**Interfaces:**
- Produces: `routing-observe.sh [plugin-name] [plans-dir]` (defaults `ios-tuist-skills`, `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plans`). Output JSON gains `"plan_writes": [<path>, ...]`. A Write/Edit/NotebookEdit whose path is under `plans-dir/` is appended there and reading continues; any other write still stops with `stop_reason: "write-tool"`.
- Produces: `results.json` aggregate gains `"plan_write_cases": [<id>, ...]`; `summary.md` gains a section `## Plan-mode plan files (recorded, not a stop)`.
- Consumes: nothing new.

- [ ] **Step 1: Branch.** `git switch develop && git pull --ff-only && git switch -c fix/v0.9.x-routing-plan-writes` **[hand-off]**

- [ ] **Step 2: Write the failing tests.** Save this as `$TMPDIR/t1-tests.rb` (outside the repo) and run `ruby "$TMPDIR/t1-tests.rb" .` from the repo root. It aborts with "anchor not found" if the repo differs from `a9299a2`; then stop and report.

```ruby
# Task 1 test edits: canned streams and assertions. Run from anywhere: ruby t1-tests.rb <repo>
Dir.chdir(ARGV[0])

def edit(path, old, new)
  s = File.read(path)
  abort "#{path}: anchor not found:\n#{old}" unless s.include?(old)
  abort "#{path}: anchor not unique" unless s.scan(old).size == 1
  File.write(path, s.sub(old) { new })
end

INIT = '{"type":"system","subtype":"init","claude_code_version":"2.1.296","model":"claude-opus-5","permissionMode":"plan","plugins":[{"name":"ios-tuist-skills","path":"/repo","source":"ios-tuist-skills@inline","version":"0.9.0"}],"skills":[]}'
def tool(id, name, input)
  %({"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"#{id}","name":"#{name}","input":#{input}}]},"parent_tool_use_id":null})
end

File.write("tests/routing/fixtures/write-first.jsonl", [
  INIT,
  tool("toolu_01", "Bash", '{"command":"ls"}'),
  tool("toolu_02", "Write", '{"file_path":"/work/App/Sources/Feature.swift","content":"struct Feature {}"}'),
].join("\n") + "\n")
File.write("tests/routing/fixtures/plan-write-then-skill.jsonl", [
  INIT,
  tool("toolu_01", "Bash", '{"command":"ls"}'),
  tool("toolu_02", "Write", '{"file_path":"/home/u/.claude/plans/p.md","content":"# plan"}'),
  tool("toolu_03", "Skill", '{"skill":"ios-tuist-skills:ios-tuist-feature"}'),
].join("\n") + "\n")
File.write("tests/routing/fixtures/plan-write-then-result.jsonl", [
  INIT,
  tool("toolu_01", "Write", '{"file_path":"/home/u/.claude/plans/p.md","content":"# plan"}'),
  tool("toolu_02", "Edit", '{"file_path":"/home/u/.claude/plans/p.md","old_string":"plan","new_string":"plan v2"}'),
  '{"type":"result","subtype":"success","is_error":false,"num_turns":3,"total_cost_usd":0.2}',
].join("\n") + "\n")
File.write("tests/routing/fixtures/plans-lookalike.jsonl", [
  INIT,
  tool("toolu_01", "Write", '{"file_path":"/home/u/.claude/plans-old/p.md","content":"# not a plan file"}'),
].join("\n") + "\n")

t = "tests/routing/test-routing-observe.sh"
edit(t, %q{  local out; out="$("$OBS" < "$FIX/$file" 2>&1)"},
        %q{  local out; out="$("$OBS" ios-tuist-skills /home/u/.claude/plans < "$FIX/$file" 2>&1)"})
edit(t, %q{  'selected="none"' 'stop_reason="write-tool"' 'write_path="/home/u/.claude/plans/p.md"' 'tools_before_stop=["Bash","Write"]'},
        %q{  'selected="none"' 'stop_reason="write-tool"' 'write_path="/work/App/Sources/Feature.swift"' 'tools_before_stop=["Bash","Write"]' 'plan_writes=[]'
check "plan-file write does not stop before a skill" plan-write-then-skill.jsonl \
  'selected="ios-tuist-feature"' 'stop_reason="skill"' 'plan_writes=["/home/u/.claude/plans/p.md"]' 'write_path=null'
check "plan-file write and edit, then result" plan-write-then-result.jsonl \
  'selected="none"' 'stop_reason="result"' 'plan_writes=["/home/u/.claude/plans/p.md","/home/u/.claude/plans/p.md"]' 'write_path=null'
check "sibling directory with the plans prefix still stops" plans-lookalike.jsonl \
  'selected="none"' 'stop_reason="write-tool"' 'write_path="/home/u/.claude/plans-old/p.md"' 'plan_writes=[]'})
edit(t, %q{# The observer must stop reading at the stop event},
        %q{# Without a plans-dir argument the default is $CLAUDE_CONFIG_DIR/plans, else $HOME/.claude/plans.
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

# The observer must stop reading at the stop event})

s = "tests/routing/fixtures/results-sample.jsonl"
edit(s, %q{"id":"neg-a","category":"negative","fixture":"modular","expected_skill":"none","forbidden_skills":[],"selected":"none","stop_reason":"result","nested":false,"tools_before_stop":[],"write_path":null,},
        %q{"id":"neg-a","category":"negative","fixture":"modular","expected_skill":"none","forbidden_skills":[],"selected":"none","stop_reason":"result","nested":false,"tools_before_stop":["Write"],"write_path":null,"plan_writes":["/home/u/.claude/plans/p.md"],})
u = "tests/routing/test-routing-summarize.sh"
edit(u, %q{want "plugin version recorded" "Plugin version: 0.9.0"
},
        %q{want "plugin version recorded" "Plugin version: 0.9.0"
want "plan-file writes listed"  "- neg-a: 1 plan-file write(s), then result"
})
edit(u, %q{exit(d["cases"].size == 5 && d["aggregate"]["correct"] == 3 ? 0 : 1)},
        %q{exit(d["cases"].size == 5 && d["aggregate"]["correct"] == 3 && d["aggregate"]["plan_write_cases"] == ["neg-a"] ? 0 : 1)})

e = "tests/routing/test-run-routing-eval.sh"
edit(e, %q{check "case stderr exists in caller output directory"},
        %q{check "observer receives the plans dir" ruby -rjson -e '
  row = JSON.parse(File.readlines(ARGV[0]).first)
  abort "plan_writes missing: #{row.keys.inspect}" unless row.key?("plan_writes")
' "$T/rel/out/results.jsonl"
check "case stderr exists in caller output directory"})
puts "task 1 test edits applied"
```

- [ ] **Step 3: Run the tests; they must fail.**

Run: `for f in tests/routing/test-routing-observe.sh tests/routing/test-routing-summarize.sh tests/routing/test-run-routing-eval.sh; do echo "$f: $(bash $f | grep -c '^FAIL')"; done`
Expected: `12`, `2`, `1` FAIL lines.

- [ ] **Step 4: Replace `scripts/routing-observe.sh` with this content** (keep the executable bit):

```bash
#!/bin/bash
# Reads `claude -p --output-format stream-json --verbose` on stdin and prints one JSON line:
# which skill was selected and why reading stopped. Exits at the stop event so the producer
# gets SIGPIPE instead of running (and spending) to the end.
#   routing-observe.sh [plugin-name] [plans-dir]
#   defaults: ios-tuist-skills, ${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plans
# Plan mode writes its own plan file under plans-dir. That write is planning, not acting
# without a skill: it is recorded in plan_writes and reading continues.
set -euo pipefail

exec ruby -rjson -e '
  plugin = ARGV[0] || "ios-tuist-skills"
  plans_dir = ARGV[1].to_s.sub(%r{/+\z}, "")
  info = {
    "selected" => nil, "stop_reason" => "eof", "nested" => false, "tools_before_stop" => [],
    "write_path" => nil, "plan_writes" => [], "plugin_version" => nil, "claude_code_version" => nil,
    "model" => nil, "permission_mode" => nil, "cost_usd" => nil, "result_subtype" => nil
  }
  emit = lambda do
    info["selected"] ||= "none"
    puts JSON.generate(info)
    STDOUT.flush
    exit 0
  end
  STDIN.each_line do |line|
    event = (JSON.parse(line) rescue nil)
    next unless event.is_a?(Hash)
    case event["type"]
    when "system"
      next unless event["subtype"] == "init"
      entry = (event["plugins"] || []).find { |p| p["name"] == plugin }
      info["plugin_version"] = entry && entry["version"]
      info["claude_code_version"] = event["claude_code_version"]
      info["model"] = event["model"]
      info["permission_mode"] = event["permissionMode"]
    when "assistant"
      (event.dig("message", "content") || []).each do |item|
        next unless item.is_a?(Hash) && item["type"] == "tool_use"
        name = item["name"].to_s
        if name == "Skill"
          skill = item.dig("input", "skill").to_s
          info["selected"] = skill.start_with?("#{plugin}:") ? skill.delete_prefix("#{plugin}:") : "other:#{skill}"
          info["nested"] = !event["parent_tool_use_id"].nil?
          info["stop_reason"] = "skill"
          emit.call
        end
        info["tools_before_stop"] << name
        # A write before any skill means the model chose to act without one.
        if %w[Write Edit NotebookEdit].include?(name)
          path = item.dig("input", "file_path") || item.dig("input", "notebook_path")
          if !plans_dir.empty? && path.to_s.start_with?(plans_dir + "/")
            info["plan_writes"] << path
            next
          end
          info["write_path"] = path
          info["stop_reason"] = "write-tool"
          emit.call
        end
      end
    when "result"
      info["stop_reason"] = "result"
      info["result_subtype"] = event["subtype"]
      info["cost_usd"] = event["total_cost_usd"]
      emit.call
    end
  end
  emit.call
' "${1:-ios-tuist-skills}" "${2:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plans}"
```

- [ ] **Step 5: Edit the runner.** Save as `$TMPDIR/t1-runner.rb` and run `ruby "$TMPDIR/t1-runner.rb" .`

```ruby
# Task 1 runner edits (routing-observe.sh is replaced whole). Run: ruby t1-runner.rb <repo>
Dir.chdir(ARGV[0])

def edit(path, old, new)
  s = File.read(path)
  abort "#{path}: anchor not found:\n#{old}" unless s.include?(old)
  abort "#{path}: anchor not unique" unless s.scan(old).size == 1
  File.write(path, s.sub(old) { new })
end

r = "scripts/run-routing-eval.sh"
edit(r, %q{| tee "$out/raw/$id.jsonl" | "$REPO_ROOT/scripts/routing-observe.sh" > "$out/observe/$id.json"},
        %q{| tee "$out/raw/$id.jsonl" | "$REPO_ROOT/scripts/routing-observe.sh" ios-tuist-skills "$plans_dir" > "$out/observe/$id.json"})
edit(r, %q{    anomalies = rows.select { |r| r["stop_reason"] == "eof" || r["nested"] }
},
        %q{    anomalies = rows.select { |r| r["stop_reason"] == "eof" || r["nested"] }
    plan_cases = rows.reject { |r| (r["plan_writes"] || []).empty? }
})
edit(r, %q{"violations" => violations.map { |r| r["id"] }, "anomalies" => anomalies.map { |r| r["id"] },},
        %q{"violations" => violations.map { |r| r["id"] }, "anomalies" => anomalies.map { |r| r["id"] },
      "plan_write_cases" => plan_cases.map { |r| r["id"] },})
edit(r, %q{    md << (anomalies.empty? ? "- none" : anomalies.map { |r| r["nested"] ? "- #{r["id"]}: skill selected inside a subagent" : "- #{r["id"]}: stop_reason eof" })
    md << ""
},
        %q{    md << (anomalies.empty? ? "- none" : anomalies.map { |r| r["nested"] ? "- #{r["id"]}: skill selected inside a subagent" : "- #{r["id"]}: stop_reason eof" })
    md << ""
    md << "## Plan-mode plan files (recorded, not a stop)"
    md << (plan_cases.empty? ? "- none" : plan_cases.map { |r| "- #{r["id"]}: #{r["plan_writes"].size} plan-file write(s), then #{r["stop_reason"]}" })
    md << ""
})

puts "task 1 runner edits applied"
```

- [ ] **Step 6: Run all routing tests; they must pass, also on Ruby 2.6.**

Run: `for f in tests/routing/test-*.sh; do bash $f | tail -1; done` and the same with `PATH=/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin`.
Expected: four `all ... tests passed` lines each time. Also `bash -n scripts/routing-observe.sh scripts/run-routing-eval.sh`.

- [ ] **Step 7: README.** In `README.md` section "Routing evaluation", after the sentence ending "`forbidden-skill violations). Each case is capped with `--max-budget-usd` (default 0.30).", add one paragraph:

```markdown
Plan mode writes its own plan file under `~/.claude/plans/` (or
`$CLAUDE_CONFIG_DIR/plans/`). Those writes are listed under "Plan-mode plan
files" and do not end a case; any other write before a `Skill` call still
counts as acting without a skill.
```

- [ ] **Step 8: Commit and PR** **[hand-off]**: `fix(routing): record plan-mode plan files instead of stopping`. PR body: Step 3 and Step 6 outputs; note that the 2026-10-13 baseline is not re-run here (Task 4).

---

### Task 2: `--agent claude|codex` in the benchmark and routing harnesses (Phase A, WS-F change 3)

**Files:**
- Modify: `scripts/benchmark-isolated-run.sh`, `scripts/run-routing-eval.sh`, `.github/workflows/lint.yml`, `tests/routing/test-run-routing-eval.sh`
- Create: `tests/harness/test-prep-agent.sh`

**Interfaces:**
- Produces: `benchmark-isolated-run.sh prep <fixture> <baseline|with-skill> <run-N> [--plugin-dir DIR] [--agent claude|codex]` (default `claude`; options in any order; unknown agent → exit 2). State file `$TMPDIR/state-<fixture>-<condition>-run<N>.agent`. `prep` prints `Agent: <agent>` after `Workdir:` and, for Codex, `cd <workdir> && codex --disable plugins`. Codex with-skill copies `<plugin-dir>/skills/.` into `<workdir>/.agents/skills/` before the baseline commit. `collect` prints `Agent:` and `Codex:` or `Claude:` version lines.
- Produces: `run-routing-eval.sh run ... --agent codex` → exit 3 with `unsupported: codex exec --json (0.160.0) emits no skill-selection event, so routing cannot be observed` (PRD WS-F acceptance allows "unsupported").
- Consumes: nothing from Task 1 (both edit `run-routing-eval.sh`, different lines; whichever merges second rebases cleanly — if not, stop and report).

- [ ] **Step 1: Branch.** `git switch develop && git pull --ff-only && git switch -c feature/v0.9.x-agent-arg` **[hand-off]**

- [ ] **Step 2: Create `tests/harness/test-prep-agent.sh`** (mode 755):

```bash
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
```

- [ ] **Step 3: Add the routing test.** Save as `$TMPDIR/t2-tests.rb` and run `ruby "$TMPDIR/t2-tests.rb" .`

```ruby
# Task 2 test edits (test-prep-agent.sh is a new file). Run: ruby t2-tests.rb <repo>
Dir.chdir(ARGV[0])

def edit(path, old, new)
  s = File.read(path)
  abort "#{path}: anchor not found:\n#{old}" unless s.include?(old)
  abort "#{path}: anchor not unique" unless s.scan(old).size == 1
  File.write(path, s.sub(old) { new })
end

e = "tests/routing/test-run-routing-eval.sh"
edit(e, %q{if [ "$failures" -eq 0 ]; then
  echo "all run-routing-eval tests passed"},
        %q{status=0
(cd "$T" && PATH="$T/bin:$PATH" TMPDIR="$T" "$REPO_ROOT/scripts/run-routing-eval.sh" run \
  --condition plugin-only --out codex/out --agent codex) > "$T/codex.log" 2>&1 || status=$?
check "codex agent is reported unsupported (exit 3)" ruby -e 'abort "exit #{ARGV[0]}" unless ARGV[0] == "3"' "$status"
check "unsupported message names the missing event" grep -q 'no skill-selection event' "$T/codex.log"
check "unsupported run writes no results" test ! -e "$T/codex/out/results.jsonl"

if [ "$failures" -eq 0 ]; then
  echo "all run-routing-eval tests passed"})
puts "task 2 test edits applied"
```

- [ ] **Step 4: Run the tests; they must fail.**

Run: `bash tests/harness/test-prep-agent.sh | grep -c '^FAIL'; bash tests/routing/test-run-routing-eval.sh | grep -c '^FAIL'`
Expected: `7` and `2`.

- [ ] **Step 5: Implement.** Save as `$TMPDIR/t2-scripts.rb` and run `ruby "$TMPDIR/t2-scripts.rb" .`

```ruby
# Task 2 script and workflow edits. Run: ruby t2-scripts.rb <repo>
Dir.chdir(ARGV[0])

def edit(path, old, new)
  s = File.read(path)
  abort "#{path}: anchor not found:\n#{old}" unless s.include?(old)
  abort "#{path}: anchor not unique" unless s.scan(old).size == 1
  File.write(path, s.sub(old) { new })
end

b = "scripts/benchmark-isolated-run.sh"
edit(b, %q{  echo "Usage: $0 prep <fixture> <baseline|with-skill> <run-N> [--plugin-dir DIR]" >&2
},
        %q{  echo "Usage: $0 prep <fixture> <baseline|with-skill> <run-N> [--plugin-dir DIR] [--agent claude|codex]" >&2
})
edit(b, %q{  echo "Optional for collect: BENCH_TRANSCRIPT=<saved final response> parses its ios-tuist-result block." >&2
},
        %q{  echo "Optional for collect: BENCH_TRANSCRIPT=<saved final response> parses its ios-tuist-result block." >&2
  echo "--agent codex with-skill copies the plugin's skills into <workdir>/.agents/skills (Codex project skills)." >&2
})
edit(b, %q{PLUGIN_DIR="${PLUGIN_DIR:-}"
if [ "$command" = prep ] && [ "$#" -eq 2 ] && [ "$1" = --plugin-dir ]; then
  PLUGIN_DIR="$2"
  shift 2
fi
[ "$#" -eq 0 ] || usage
},
        %q{PLUGIN_DIR="${PLUGIN_DIR:-}"
AGENT=claude
if [ "$command" = prep ]; then
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --plugin-dir) [ "$#" -ge 2 ] || usage; PLUGIN_DIR="$2"; shift 2 ;;
      --agent) [ "$#" -ge 2 ] || usage; AGENT="$2"; shift 2 ;;
      *) usage ;;
    esac
  done
fi
[ "$#" -eq 0 ] || usage
case "$AGENT" in claude|codex) ;; *) usage ;; esac
})
edit(b, %q{        next if path.split("/").include?(".git") || !File.file?(path)},
        %q{        next if path.split("/").include?(".git") || path.start_with?(".agents/") || !File.file?(path)})
edit(b, %q{    rm -rf -- "$WORKDIR_PARENT"
    exit 1
  fi
  git -C "$WORKDIR" init -q &&},
        %q{    rm -rf -- "$WORKDIR_PARENT"
    exit 1
  fi
  if [ "$AGENT" = codex ] && [ "$condition" = with-skill ]; then
    # Codex reads project skills from .agents/skills; each skill folder is self-contained (v0.9 WS-B).
    mkdir -p "$WORKDIR/.agents/skills" && cp -R "$PLUGIN_DIR/skills/." "$WORKDIR/.agents/skills/" || exit 1
  fi
  git -C "$WORKDIR" init -q &&})
edit(b, %q{  printf '%s\n' "${PLUGIN_DIR:-$REPO_ROOT}" > "$STATE.plugin-dir" || exit 1
  echo "Workdir: $WORKDIR"
  # The user-scope installed plugin would otherwise leak into the baseline.
  printf 'cd %q && claude --setting-sources project' "$WORKDIR"
  if [ "$condition" = with-skill ]; then
    printf ' --plugin-dir %q' "$PLUGIN_DIR"
  fi
},
        %q{  printf '%s\n' "${PLUGIN_DIR:-$REPO_ROOT}" > "$STATE.plugin-dir" || exit 1
  printf '%s\n' "$AGENT" > "$STATE.agent" || exit 1
  echo "Workdir: $WORKDIR"
  echo "Agent: $AGENT"
  if [ "$AGENT" = codex ]; then
    # Both conditions disable plugins, so the only difference is the project skills above.
    printf 'cd %q && codex --disable plugins' "$WORKDIR"
  else
    # The user-scope installed plugin would otherwise leak into the baseline.
    printf 'cd %q && claude --setting-sources project' "$WORKDIR"
    if [ "$condition" = with-skill ]; then
      printf ' --plugin-dir %q' "$PLUGIN_DIR"
    fi
  fi
})
edit(b, %q{IFS= read -r PLUGIN_DIR < "$STATE.plugin-dir" || exit 1
},
        %q{IFS= read -r PLUGIN_DIR < "$STATE.plugin-dir" || exit 1
# States written before --agent existed have no .agent file; they were Claude runs.
AGENT=claude
[ ! -f "$STATE.agent" ] || IFS= read -r AGENT < "$STATE.agent" || exit 1
})
edit(b, %q{  echo "Claude: $(claude --version 2>&1)"
},
        %q{  echo "Agent: $AGENT"
  if [ "$AGENT" = codex ]; then
    echo "Codex: $(codex --version 2>&1)"
  else
    echo "Claude: $(claude --version 2>&1)"
  fi
})

r = "scripts/run-routing-eval.sh"
edit(r, %q{#       [--cases FILE] [--only id1,id2] [--budget USD] [--official-plugin-dir DIR] [--yes]},
        %q{#       [--agent claude|codex] [--cases FILE] [--only id1,id2] [--budget USD] [--official-plugin-dir DIR] [--yes]})
edit(r, %q{  local condition="" out="" cases="$REPO_ROOT/tests/routing/cases.yaml" only="" budget="0.30" official="" yes=0
},
        %q{  local condition="" out="" cases="$REPO_ROOT/tests/routing/cases.yaml" only="" budget="0.30" official="" yes=0 agent=claude
})
edit(r, %q{      --condition) condition="$2"; shift 2 ;;
},
        %q{      --condition) condition="$2"; shift 2 ;;
      --agent) agent="$2"; shift 2 ;;
})
edit(r, %q{  [ -n "$condition" ] && [ -n "$out" ] || usage
},
        %q{  [ -n "$condition" ] && [ -n "$out" ] || usage
  case "$agent" in
    claude) ;;
    codex)
      echo "unsupported: codex exec --json (0.160.0) emits no skill-selection event, so routing cannot be observed" >&2
      exit 3 ;;
    *) usage ;;
  esac
})


l = ".github/workflows/lint.yml"
edit(l, %q{      - name: Benchmark prep excludes answer key
        run: ./tests/harness/test-prep-excludes-expectations.sh
},
        %q{      - name: Benchmark prep excludes answer key
        run: ./tests/harness/test-prep-excludes-expectations.sh
      - name: Benchmark prep --agent
        run: ./tests/harness/test-prep-agent.sh
})
puts "task 2 script edits applied"
```

- [ ] **Step 6: Run the tests; they must pass, also on Ruby 2.6.**

Run: `for f in tests/harness/*.sh tests/routing/test-run-routing-eval.sh; do bash $f | tail -1; done` (and again with the `/usr/bin` PATH), plus `bash -n scripts/benchmark-isolated-run.sh scripts/run-routing-eval.sh`.
Expected: four `all ... passed` lines each time.

- [ ] **Step 7: Verify Codex sees the project skills with plugins disabled** **[hand-off, Claude]**. This is the PRD's "[검증 필요] Codex headless 실행·관측 방법" for the benchmark path.

```bash
SCRATCH="$(mktemp -d)"
W="$(TMPDIR="$SCRATCH" scripts/benchmark-isolated-run.sh prep modular with-skill 1 --plugin-dir "$PWD" --agent codex | sed -n 's/^Workdir: //p')"
B="$(TMPDIR="$SCRATCH" scripts/benchmark-isolated-run.sh prep modular baseline 1 --agent codex | sed -n 's/^Workdir: //p')"
for d in "$W" "$B"; do
  codex exec --disable plugins -s read-only -C "$d" -o "$d/../skills.txt" \
    "List the names of every skill available to you, one per line. Do not run any command." > /dev/null
  echo "$d: $(grep -c 'ios-tuist-' "$d/../skills.txt") ios-tuist skills"
done
```

Expected: with-skill `10`, baseline `0`. If with-skill is `0`: Codex does not load `.agents/skills` with plugins disabled — stop, keep the code (it is correct for the documented location), and record "Codex with-skill: unverified (skills not discovered)" in the PR and CHANGELOG; Task 5 then runs Claude only. If baseline is not `0`: a user-scope copy leaks — stop and report which skills appeared. Delete `$SCRATCH` afterwards.

- [ ] **Step 8: README.** In "Skill effectiveness benchmark", append:

```markdown
`scripts/benchmark-isolated-run.sh prep ... --agent codex` prepares the same
isolated workdir for Codex CLI: with-skill copies the skill folders into
`.agents/skills/` (Codex project skills), and both conditions run
`codex --disable plugins` so an installed plugin cannot leak into the
baseline. The routing evaluation does not support Codex
(`--agent codex` exits 3): `codex exec --json` has no skill-selection event.
```

- [ ] **Step 9: Commit and PR** **[hand-off]**: `feat(harness): add --agent claude|codex to benchmark and routing harnesses`. PR body: Step 4, 6 and 7 outputs; "Unverified: a full Codex benchmark run (Task 5)".

---

### Task 3: WS-F `large-graph` fixture (Phase A, WS-F changes 1-2)

**Files:**
- Create: `tests/fixtures/large-graph/**` (32 files from the generator, plus `EXPECTATIONS.md`)
- Create: `tests/golden/version-evidence/large-graph.expected.json`
- Modify: `tests/fixtures/ci-matrix.json` (new row), `README.md` (fixture list)

**Interfaces:**
- Produces: matrix row `{ "fixture": "large-graph", "tuist": "4.206.0", "workspace": "LargeGraph", "resolve_cmd": "install", "test_schemes": "App HomeFeature CheckoutFeature CatalogDomain CoreNetworking" }`. Tasks 2 and 5 use `large-graph` as a fixture name; scenarios and prompts are in its `EXPECTATIONS.md`.
- Consumes: nothing. `ci-select-fixtures.sh`, `check-fixture-pins.sh`, `validate-fixtures-locally.sh`, the golden version-evidence loop and `test-read-only.sh` all read the matrix or `tests/fixtures/*/`, so no script changes are needed.

- [ ] **Step 1: Branch.** `git switch develop && git pull --ff-only && git switch -c feature/v0.9.x-large-graph` **[hand-off]**

- [ ] **Step 2: Generate the fixture.** Save this generator as `$TMPDIR/make-large-graph.sh` (outside the repo; it is not committed) and run `bash "$TMPDIR/make-large-graph.sh" tests/fixtures/large-graph`. Expected last line: `wrote 32 files into tests/fixtures/large-graph`.

```bash
#!/bin/bash
# Writes the large-graph fixture into $1 (default tests/fixtures/large-graph). One-off; not committed.
set -euo pipefail
D="${1:-tests/fixtures/large-graph}"
[ ! -e "$D" ] || { echo "refusing to overwrite $D" >&2; exit 1; }
mkdir -p "$D"
w() { mkdir -p "$(dirname "$D/$1")"; cat > "$D/$1"; }

w .tool-versions <<'EOF'
tuist 4.206.0
EOF

w Tuist.swift <<'EOF'
import ProjectDescription

let tuist = Tuist()
EOF

w Tuist/Package.swift <<'EOF'
// swift-tools-version: 5.9
import PackageDescription

#if TUIST
    import ProjectDescription

    let packageSettings = PackageSettings(
        productTypes: [
            "LogKit": .staticFramework,
            "KeyValueStore": .staticFramework,
            "RetryKit": .staticFramework,
        ]
    )
#endif

let package = Package(
    name: "LargeGraphDependencies",
    dependencies: [
        .package(path: "../Packages/LogKit"),
        .package(path: "../Packages/KeyValueStore"),
        .package(path: "../Packages/RetryKit"),
    ]
)
EOF

for pkg in LogKit KeyValueStore RetryKit; do
  w "Packages/$pkg/Package.swift" <<EOF
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "$pkg",
    platforms: [.iOS(.v17)],
    products: [.library(name: "$pkg", targets: ["$pkg"])],
    targets: [.target(name: "$pkg")]
)
EOF
done

w Packages/LogKit/Sources/LogKit/Log.swift <<'EOF'
public enum Log {
    public static func message(_ text: String) -> String {
        "[log] " + text
    }
}
EOF

w Packages/KeyValueStore/Sources/KeyValueStore/KVStore.swift <<'EOF'
public struct KVStore {
    private var storage: [String: String] = [:]

    public init() {}

    public mutating func set(_ value: String, for key: String) {
        storage[key] = value
    }

    public func value(for key: String) -> String? {
        storage[key]
    }
}
EOF

w Packages/RetryKit/Sources/RetryKit/RetryPolicy.swift <<'EOF'
public struct RetryPolicy: Equatable {
    public let limit: Int

    public init(limit: Int) {
        self.limit = limit < 1 ? 1 : limit
    }

    public var attempts: [Int] {
        Array(1...limit)
    }
}
EOF

w Project.swift <<'EOF'
import ProjectDescription

let project = Project(
    name: "LargeGraph",
    targets: [
        .target(
            name: "App",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.ios-tuist-skills.large-graph",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: ["UILaunchScreen": [:]]),
            buildableFolders: ["App/Sources"],
            dependencies: [
                .target(name: "HomeFeature"),
                .target(name: "SearchFeature"),
                .target(name: "ProfileFeature"),
                .target(name: "SettingsFeature"),
                .target(name: "CheckoutFeature"),
                .target(name: "CoreUtilities"),
                .target(name: "LegacyHelpers"),
            ]
        ),
        .target(
            name: "AppTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.large-graph.app-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["App/Tests"],
            dependencies: [.target(name: "App")]
        ),
        .target(
            name: "HomeFeature",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.large-graph.home-feature",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["HomeFeature/Sources"],
            dependencies: [
                .target(name: "CatalogDomain"),
                .target(name: "CoreUI"),
                .target(name: "CoreAnalytics"),
            ]
        ),
        .target(
            name: "HomeFeatureTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.large-graph.home-feature-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["HomeFeature/Tests"],
            dependencies: [.target(name: "HomeFeature")]
        ),
        .target(
            name: "SearchFeature",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.large-graph.search-feature",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["SearchFeature/Sources"],
            dependencies: [
                .target(name: "CatalogDomain"),
                .target(name: "CoreUI"),
                .target(name: "CoreNetworking"),
            ]
        ),
        .target(
            name: "ProfileFeature",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.large-graph.profile-feature",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["ProfileFeature/Sources"],
            dependencies: [
                .target(name: "UserDomain"),
                .target(name: "CoreUI"),
            ]
        ),
        .target(
            name: "SettingsFeature",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.large-graph.settings-feature",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["SettingsFeature/Sources"],
            dependencies: [
                .target(name: "UserDomain"),
                .target(name: "CoreUI"),
            ]
        ),
        .target(
            name: "CheckoutFeature",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.large-graph.checkout-feature",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Checkout/**/*.swift"],
            dependencies: [
                .target(name: "OrderDomain"),
                .target(name: "CoreUI"),
            ]
        ),
        .target(
            name: "CheckoutFeatureTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.large-graph.checkout-feature-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["CheckoutTests/**/*.swift"],
            dependencies: [.target(name: "CheckoutFeature")]
        ),
        .target(
            name: "UserDomain",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.large-graph.user-domain",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["UserDomain/Sources"],
            dependencies: [
                .target(name: "CoreNetworking"),
                .target(name: "CorePersistence"),
            ]
        ),
        .target(
            name: "CatalogDomain",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.large-graph.catalog-domain",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["CatalogDomain/Sources"],
            dependencies: [.target(name: "CoreNetworking")]
        ),
        .target(
            name: "CatalogDomainTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.large-graph.catalog-domain-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["CatalogDomain/Tests"],
            dependencies: [.target(name: "CatalogDomain")]
        ),
        .target(
            name: "OrderDomain",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.large-graph.order-domain",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["OrderDomain/Sources"],
            dependencies: [
                .target(name: "CoreNetworking"),
                .target(name: "CorePersistence"),
            ]
        ),
        .target(
            name: "CoreNetworking",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.large-graph.core-networking",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["CoreNetworking/Sources"],
            dependencies: [.external(name: "LogKit")]
        ),
        .target(
            name: "CoreNetworkingTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.large-graph.core-networking-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["CoreNetworking/Tests"],
            dependencies: [.target(name: "CoreNetworking")]
        ),
        .target(
            name: "CorePersistence",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.large-graph.core-persistence",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["CorePersistence/Sources"],
            dependencies: [.external(name: "KeyValueStore")]
        ),
        .target(
            name: "CoreUI",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.large-graph.core-ui",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["CoreUI/Sources"],
            dependencies: [.target(name: "DesignSystem")]
        ),
        .target(
            name: "CoreUtilities",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.large-graph.core-utilities",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["CoreUtilities/Sources"],
            dependencies: []
        ),
        .target(
            name: "CoreAnalytics",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.large-graph.core-analytics",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["CoreAnalytics/Sources"],
            dependencies: [.external(name: "LogKit")]
        ),
        .target(
            name: "DesignSystem",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.large-graph.design-system",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["DesignSystem/Sources"],
            dependencies: []
        ),
        .target(
            name: "LegacyHelpers",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.example.legacy-helpers",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["LegacyHelpers/**/*.swift"],
            dependencies: [.target(name: "CoreUtilities")]
        ),
    ]
)
EOF

w App/Sources/LargeGraphApp.swift <<'EOF'
import CheckoutFeature
import CoreUtilities
import HomeFeature
import LegacyHelpers
import ProfileFeature
import SearchFeature
import SettingsFeature
import SwiftUI

@main
struct LargeGraphApp: App {
    var body: some Scene {
        WindowGroup {
            Text(AppConfiguration.title)
        }
    }
}

enum AppConfiguration {
    static let title = TextUtilities.trimmed("  Large Graph  ")
}
EOF

w App/Tests/AppTests.swift <<'EOF'
import Testing
@testable import App

@Test func appTitleIsTrimmed() {
    #expect(AppConfiguration.title == "Large Graph")
}
EOF

w HomeFeature/Sources/HomeViewModel.swift <<'EOF'
import CatalogDomain
import CoreAnalytics
import CoreUI

public struct HomeViewModel {
    public init() {}

    public func featuredTitle(for product: Product) -> String {
        _ = Analytics.event("home_featured")
        return product.title
    }

    public var padding: Double {
        Layout.padded(4)
    }
}
EOF

w HomeFeature/Tests/HomeFeatureTests.swift <<'EOF'
import CatalogDomain
import Testing
@testable import HomeFeature

@Test func featuredTitleUsesTheProductTitle() {
    let product = Product(id: "p1", title: "Lamp", priceCents: 1999)
    #expect(HomeViewModel().featuredTitle(for: product) == "Lamp")
}
EOF

w SearchFeature/Sources/SearchViewModel.swift <<'EOF'
import CatalogDomain
import CoreNetworking
import CoreUI

public struct SearchViewModel {
    private let client = HTTPClient()
    private let catalog = CatalogService()

    public init() {}

    public func requestDescription(for query: String) -> String {
        client.describe(HTTPRequest(path: "/search?q=" + query))
    }

    public func catalogRequest(for query: String) -> HTTPRequest {
        catalog.searchRequest(query)
    }
}
EOF

w ProfileFeature/Sources/ProfileViewModel.swift <<'EOF'
import CoreUI
import UserDomain

public struct ProfileViewModel {
    public let user: User

    public init(user: User) {
        self.user = user
    }

    public var title: String {
        user.name
    }

    public var padding: Double {
        Layout.padded(2)
    }
}
EOF

w SettingsFeature/Sources/SettingsViewModel.swift <<'EOF'
import CoreUI
import UserDomain

public struct SettingsViewModel {
    public init() {}

    public func title(for user: User) -> String {
        "Settings - " + user.name
    }

    public func subscriptionPrice(cents: Int) -> String {
        let dollars = cents / 100
        let remainder = cents % 100
        return "$" + String(dollars) + "." + (remainder < 10 ? "0" : "") + String(remainder)
    }
}
EOF

w Checkout/Cart/Cart.swift <<'EOF'
import OrderDomain

public struct Cart {
    public private(set) var items: [String] = []
    public private(set) var totalCents = 0

    public init() {}

    public mutating func add(_ item: String, cents: Int) {
        items.append(item)
        totalCents += cents
    }

    public func order() -> Order {
        Order(items: items, totalCents: totalCents)
    }

    public var formattedTotal: String {
        PriceFormatter.format(cents: totalCents)
    }
}
EOF

w Checkout/Formatting/PriceFormatter.swift <<'EOF'
public enum PriceFormatter {
    public static func format(cents: Int) -> String {
        let dollars = cents / 100
        let remainder = cents % 100
        return "$" + String(dollars) + "." + (remainder < 10 ? "0" : "") + String(remainder)
    }
}
EOF

w CheckoutTests/PriceFormatterTests.swift <<'EOF'
import Testing
@testable import CheckoutFeature

@Test func formatsDollarsAndCents() {
    #expect(PriceFormatter.format(cents: 1205) == "$12.05")
    #expect(PriceFormatter.format(cents: 7) == "$0.07")
}

@Test func cartTotalIsFormatted() {
    var cart = Cart()
    cart.add("Lamp", cents: 1999)
    cart.add("Bulb", cents: 1)
    #expect(cart.formattedTotal == "$20.00")
}
EOF

w UserDomain/Sources/User.swift <<'EOF'
import CoreNetworking
import CorePersistence

public struct User: Equatable {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public struct UserRepository {
    public init() {}

    public func request(for id: String) -> HTTPRequest {
        HTTPRequest(path: "/users/" + id)
    }

    public func cache(_ user: User) -> Cache {
        var cache = Cache()
        cache.save(user.name, key: user.id)
        return cache
    }
}
EOF

w CatalogDomain/Sources/Catalog.swift <<'EOF'
import CoreNetworking

public struct Product: Equatable {
    public let id: String
    public let title: String
    public let priceCents: Int

    public init(id: String, title: String, priceCents: Int) {
        self.id = id
        self.title = title
        self.priceCents = priceCents
    }
}

public struct CatalogService {
    public init() {}

    public func searchRequest(_ query: String) -> HTTPRequest {
        HTTPRequest(path: "/catalog/search?q=" + query)
    }
}
EOF

w CatalogDomain/Tests/CatalogDomainTests.swift <<'EOF'
import CoreNetworking
import Testing
@testable import CatalogDomain

@Test func searchRequestTargetsTheCatalog() {
    #expect(CatalogService().searchRequest("lamp") == HTTPRequest(path: "/catalog/search?q=lamp"))
}
EOF

w OrderDomain/Sources/Order.swift <<'EOF'
import CoreNetworking
import CorePersistence

public struct Order: Equatable {
    public let items: [String]
    public let totalCents: Int

    public init(items: [String], totalCents: Int) {
        self.items = items
        self.totalCents = totalCents
    }
}

public struct OrderService {
    public init() {}

    public func submitRequest(_ order: Order) -> HTTPRequest {
        HTTPRequest(path: "/orders?count=" + String(order.items.count))
    }

    public func draft(_ order: Order) -> Cache {
        var cache = Cache()
        cache.save(String(order.totalCents), key: "draft-total")
        return cache
    }
}
EOF

w CoreNetworking/Sources/HTTPClient.swift <<'EOF'
import LogKit

public struct HTTPRequest: Equatable {
    public let path: String

    public init(path: String) {
        self.path = path
    }
}

public struct HTTPClient {
    public init() {}

    public func describe(_ request: HTTPRequest) -> String {
        Log.message("GET " + request.path)
    }
}
EOF

w CoreNetworking/Tests/CoreNetworkingTests.swift <<'EOF'
import Testing
@testable import CoreNetworking

@Test func describeLogsTheRequest() {
    #expect(HTTPClient().describe(HTTPRequest(path: "/x")) == "[log] GET /x")
}
EOF

w CorePersistence/Sources/Cache.swift <<'EOF'
import KeyValueStore

public struct Cache {
    private var store = KVStore()

    public init() {}

    public mutating func save(_ value: String, key: String) {
        store.set(value, for: key)
    }

    public func load(_ key: String) -> String? {
        store.value(for: key)
    }
}
EOF

w CoreUI/Sources/Layout.swift <<'EOF'
import DesignSystem

public enum Layout {
    public static func padded(_ value: Double) -> Double {
        value + Tokens.spacing
    }
}
EOF

w CoreUtilities/Sources/TextUtilities.swift <<'EOF'
import Foundation

public enum TextUtilities {
    public static func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespaces)
    }
}
EOF

w CoreAnalytics/Sources/Analytics.swift <<'EOF'
import LogKit

public enum Analytics {
    public static func event(_ name: String) -> String {
        Log.message("event " + name)
    }
}
EOF

w DesignSystem/Sources/Tokens.swift <<'EOF'
public enum Tokens {
    public static let spacing: Double = 8
}
EOF

w LegacyHelpers/Helpers/LegacyStringHelper.swift <<'EOF'
import CoreUtilities

public enum LegacyStringHelper {
    public static func clean(_ text: String) -> String {
        TextUtilities.trimmed(text).lowercased()
    }
}
EOF

echo "wrote $(find "$D" -type f | wc -l | tr -d ' ') files into $D"
```

- [ ] **Step 3: Write `tests/fixtures/large-graph/EXPECTATIONS.md`:**

````markdown
# Fixture: large-graph

**Exercises:** `ios-tuist-module`, `ios-tuist-dependency`,
`ios-tuist-architecture-review` (PRD v0.9 WS-F: external validity)

## Starting state

A synthetic, buildable Tuist 4.206.0 project (`LargeGraph`) with 16
non-test targets, 5 unit test targets and 3 SwiftPM packages integrated
through `Tuist/Package.swift` as `.external` dependencies. The packages
are local path packages under `Packages/`, so `tuist install` needs no
network. No company code is used.

Layers (manifest edges):

- `App` → `HomeFeature`, `SearchFeature`, `ProfileFeature`,
  `SettingsFeature`, `CheckoutFeature`, `CoreUtilities`, `LegacyHelpers`
- Features → domains: `HomeFeature` → `CatalogDomain`, `CoreUI`,
  `CoreAnalytics`; `SearchFeature` → `CatalogDomain`, `CoreUI`,
  `CoreNetworking`; `ProfileFeature` and `SettingsFeature` →
  `UserDomain`, `CoreUI`; `CheckoutFeature` → `OrderDomain`, `CoreUI`
- Domains → core: `UserDomain` and `OrderDomain` → `CoreNetworking`,
  `CorePersistence`; `CatalogDomain` → `CoreNetworking`
- Core → packages: `CoreNetworking` and `CoreAnalytics` →
  `.external(name: "LogKit")`; `CorePersistence` →
  `.external(name: "KeyValueStore")`; `CoreUI` → `DesignSystem`
- `LegacyHelpers` → `CoreUtilities`
- `RetryKit` is declared in `Tuist/Package.swift` but no target uses it.

Conventions that are deliberately not uniform (real projects drift):

- Most targets use `buildableFolders: ["<Target>/Sources"]`.
  `CheckoutFeature` uses `sources: ["Checkout/**/*.swift"]` (folder name
  differs from the target name) and its tests use
  `sources: ["CheckoutTests/**/*.swift"]`.
- `LegacyHelpers` is the only dynamic `.framework`, uses a `sources:`
  glob over `LegacyHelpers/Helpers`, and has a different bundle ID prefix
  (`com.example.`).
- `SettingsFeature.subscriptionPrice(cents:)` duplicates
  `CheckoutFeature`'s `PriceFormatter.format(cents:)`.
- `SearchViewModel.requestDescription(for:)` builds an `HTTPRequest`
  and calls `HTTPClient` directly although `CatalogDomain` already owns
  catalog requests.

Test schemes (CI matrix): `App`, `HomeFeature`, `CheckoutFeature`,
`CatalogDomain`, `CoreNetworking`.

## Scenario 1 — module extraction (`ios-tuist-module`)

### Prompt

> Extract `PriceFormatter` from CheckoutFeature into a new module called
> `PricingKit`, and make SettingsFeature use it instead of its own copy
> of the price formatting.

### Expected behavior

- The justification checklist is applied and cites the two concrete
  users (`Checkout/Formatting/PriceFormatter.swift`,
  `SettingsFeature/Sources/SettingsViewModel.swift`); extraction
  proceeds.
- A new `PricingKit` target exists and `PriceFormatter` moved into it.
  The new target's folder style is stated and matches a convention the
  project already uses (`buildableFolders` like most targets is
  expected; a `sources:` glob is acceptable only if the report says why).
- Edges to `PricingKit` are added only from targets with a verified
  usage site: `CheckoutFeature` and `SettingsFeature`. No edge from
  `App` or any other target.
- `SettingsViewModel.subscriptionPrice(cents:)` calls `PriceFormatter`
  instead of duplicating it, with the same output.
- `PriceFormatterTests` coverage is kept (moved to a `PricingKit` test
  target or kept in `CheckoutFeatureTests` through the new import).
  `CheckoutFeatureTests` is not emptied; if it were, it is reported, not
  deleted.
- `tuist install`, `tuist generate --no-open`, the `App` build and
  every pre-existing test scheme pass afterwards.

### What must NOT happen

- Changing `.tool-versions` or any package declaration.
- Converting `CheckoutFeature` or `LegacyHelpers` to
  `buildableFolders` (restyling is a different skill).
- An edge to `PricingKit` from a target that does not import it.

## Scenario 2 — dependency addition (`ios-tuist-dependency`)

### Prompt

> Add RetryKit to SearchFeature so its requests can be retried.

### Expected behavior

- `RetryKit` is already declared in `Tuist/Package.swift`; the skill
  says so and does not add a second `.package` entry.
- `.external(name: "RetryKit")` is added to `SearchFeature` only.
- `tuist install`, `tuist generate --no-open`, the `App` build and the
  test schemes pass.
- The report is honest that no `import RetryKit` exists yet if it does
  not add one (`scripts/skill/check-consumer-edges.sh` does not cover
  `.external` edges; that is a known limitation, not evidence of use).

### What must NOT happen

- `RetryKit` added to `App`, `CatalogDomain`, `CoreNetworking` or any
  other target.
- Edits under `Packages/`, to `.tool-versions`, or to `productTypes`
  beyond what the skill explains is required.

## Scenario 3 — architecture review (`ios-tuist-architecture-review`)

### Prompt

> Review this project's architecture and dependency direction. Report
> findings only.

### Expected behavior

- The report maps the graph (features → domains → core → packages)
  before making claims.
- Findings, each with file evidence:
  - `SearchFeature` depends on `CoreNetworking` directly and
    `SearchViewModel.requestDescription(for:)` builds requests itself,
    bypassing `CatalogDomain` (`Project.swift` `SearchFeature`
    dependencies; `SearchFeature/Sources/SearchViewModel.swift`).
  - Price formatting is duplicated between
    `Checkout/Formatting/PriceFormatter.swift` and
    `SettingsFeature/Sources/SettingsViewModel.swift`.
  - `LegacyHelpers` differs from the rest (dynamic `.framework`,
    `sources:` glob, `com.example.` bundle ID) — reported as an
    inconsistency to confirm, not as a required change.
- `App` → `CoreUtilities` and `App` → `LegacyHelpers` are either
  assessed with a reason or listed under "Not Flagged" with a reason.
- A "Not Flagged" section names areas checked and found sound (for
  example the domain → core direction).
- No file is modified.

### What must NOT happen

- Any edit to a manifest or source file.
- A finding not traceable to this fixture's manifests or sources.
- A recommendation that forces one architecture style instead of naming
  the rule or evidence.

## How to check

1. Scenario 1 and 2: `git diff --stat` in the workdir, then
   `tuist install && tuist generate --no-open`, the `App` build and the
   five test schemes (`scripts/benchmark-isolated-run.sh collect` does
   this).
2. Scenario 1: `grep -n 'PricingKit' Project.swift` shows the target and
   exactly two consumer edges.
3. Scenario 2: `grep -n 'RetryKit' Project.swift Tuist/Package.swift`
   shows one `.package` and one `.external` (in `SearchFeature`).
4. Scenario 3: `git status --short` is empty; read the findings against
   the list above.
````

- [ ] **Step 4: Register the fixture.** Save as `$TMPDIR/t3-register.rb` and run `ruby "$TMPDIR/t3-register.rb" .`

```ruby
# Task 3: registers large-graph in the CI matrix and README. Run: ruby t3-register.rb <repo>
Dir.chdir(ARGV[0])

def edit(path, old, new)
  s = File.read(path)
  abort "#{path}: anchor not found:\n#{old}" unless s.include?(old)
  abort "#{path}: anchor not unique" unless s.scan(old).size == 1
  File.write(path, s.sub(old) { new })
end

edit("tests/fixtures/ci-matrix.json",
  %q{  { "fixture": "scaffold-candidate",    "tuist": "4.206.0", "workspace": "ScaffoldCandidate",   "resolve_cmd": "install", "test_schemes": "App" }
},
  %q{  { "fixture": "scaffold-candidate",    "tuist": "4.206.0", "workspace": "ScaffoldCandidate",   "resolve_cmd": "install", "test_schemes": "App" },
  { "fixture": "large-graph",           "tuist": "4.206.0", "workspace": "LargeGraph",          "resolve_cmd": "install", "test_schemes": "App HomeFeature CheckoutFeature CatalogDomain CoreNetworking" }
})

edit("README.md",
  %q{  template `ios-tuist-scaffold` must be able to author and run
  correctly
},
  %q{  template `ios-tuist-scaffold` must be able to author and run
  correctly
- [large graph](tests/fixtures/large-graph/EXPECTATIONS.md): a synthetic
  16-target, layered project with three local SwiftPM packages and
  deliberately mixed conventions, for module extraction, dependency
  addition and architecture review at a realistic size
})
puts "task 3 registration edits applied"
```

- [ ] **Step 5: Golden file.** Run:

```bash
scripts/skill/collect-version-evidence.sh --json --no-commands tests/fixtures/large-graph \
  | ruby -rjson -e 'a = JSON.parse(STDIN.read); a.delete("project_root"); a.delete("commands"); puts JSON.generate(a)' \
  > tests/golden/version-evidence/large-graph.expected.json
```

Expected file content (one line):

```json
{"schema":"ios-tuist-version-evidence/1","tool_version":{"sources":[{"source":".tool-versions","path":".tool-versions","value":"4.206.0","conditional":false}],"effective":{"value":"4.206.0","source":".tool-versions"},"conflicts":[]},"xcode":{"compatible_xcode_versions":null,"xcode_version_file":null},"swift":{"swift_version":{"value":null,"path":null,"label":null,"label_basis":null},"package_swift_tools":null,"tuist_package_swift_tools":"5.9","swift_version_file":null}}
```

If it differs, stop and report the diff (do not hand-edit the golden file).

- [ ] **Step 6: Run the repo checks.**

Run: `scripts/run-golden-tests.sh | tail -1; scripts/check-fixture-pins.sh; tests/ci/test-select-fixtures.sh | tail -1; tests/known-issues/test-known-issues.sh | tail -1; scripts/check-routing-cases.sh`
Expected: `all golden suites passed` (with `ok   - fixture large-graph` above it), `All fixture pins match the CI matrix.`, `all selection tests passed`, the known-issues tests pass, `ok   cases.yaml: 45 cases ...`. (`golden tests` needs a git work tree for the consumer-edges suite.)

- [ ] **Step 7: Build and test the fixture locally** **[hand-off, Claude]**:

```bash
cd tests/fixtures/large-graph
mise exec -- tuist install && mise exec -- tuist generate --no-open
xcodebuild -workspace LargeGraph.xcworkspace -scheme App -destination 'generic/platform=iOS Simulator' build -quiet
SIM="$(xcrun simctl list devices available --json | ruby -rjson -e 'd = JSON.parse(STDIN.read)["devices"].values.flatten.find { |x| x["isAvailable"] && x["name"].start_with?("iPhone") }; print d["udid"]')"
for s in App HomeFeature CheckoutFeature CatalogDomain CoreNetworking; do
  xcodebuild test -workspace LargeGraph.xcworkspace -scheme "$s" -destination "id=$SIM" -quiet && echo "$s ok"
done
cd - && git status --porcelain --ignored tests/fixtures/large-graph   # only ignored generated output may appear
```

Expected: build exit 0, five `ok` lines. Then `git clean -fdX tests/fixtures/large-graph` removes only ignored output (look at `git clean -ndX` first).

- [ ] **Step 8: `git check-ignore`** **[hand-off]**: `git ls-files --others --exclude-standard tests/fixtures/large-graph | wc -l` must print `33` (32 generated files + `EXPECTATIONS.md`).

- [ ] **Step 9: Commit and PR** **[hand-off]**: `test(fixtures): add large-graph fixture for external validity (WS-F)`. The PR runs the `large-graph` matrix job on macos-15 (path selection). PR body: Step 6 and 7 outputs, the CI job result, and "Known: `check-consumer-edges.sh` does not cover `.external` edges (scenario 2 relies on the skill's own check)".

---

### Task 4: Routing re-baseline with the fixed observer (Phase B; needs Task 1 merged and the user's go-ahead)

**Files:**
- Create: `docs/superpowers/benchmarks/<YYYY-MM-DD>-routing/plugin-only/` (`meta.json`, `results.jsonl`, `results.json`, `summary.md`, `plans-created.txt`; `raw/`, `stderr/`, `observe/` stay ignored)
- Create: `docs/superpowers/benchmarks/<YYYY-MM-DD>-routing/COMPARISON.md`
- Modify: `README.md` (baseline link)

- [ ] **Step 1** **[hand-off, Claude]**: on `develop` with Task 1 merged, `git switch -c docs/v0.9.x-routing-rebaseline`, then run from the repo root:

```bash
D="docs/superpowers/benchmarks/$(date +%Y-%m-%d)-routing/plugin-only"
scripts/run-routing-eval.sh run --condition plugin-only --out "$D" --yes
```

- [ ] **Step 2: Validity checks** **[Claude]**: `results.jsonl` has 45 rows; no row has `stop_reason` `"no-output"`; `meta.json` `plugin_version` is the current `plugin.json` version; every `write_path` that is not null is outside `~/.claude/plans/`. If more than 5 rows are `eof`, treat the run as invalid (as with the 2026-10-13 relative `--out` failure), keep it out of the repo, and report.

- [ ] **Step 3: Plan files** **[Claude]**: `plans-created.txt` lists plan files the run created. Delete only those listed paths whose modification time is inside the run window (`meta.json` `date` to the end of the run); leave everything else.

- [ ] **Step 4: Comparison** **[Claude]**: write `COMPARISON.md` with: accuracy old (42/45) vs new; per-case changes (especially the seven cases in Evidence 1); forbidden-skill violations; Claude Code version of each run; and the note that N=1 per case.

- [ ] **Step 5: Pass threshold proposal (PRD open question 3)** **[Claude → user]**: propose in `COMPARISON.md`, for the user to accept or change: (a) forbidden-skill violations = 0; (b) accuracy not lower than the latest baseline by more than 2 cases; (c) no `negative` case selects a plugin skill. Ask the user; record the decision in README "Routing evaluation" only after they answer.

- [ ] **Step 6: README** — replace the "Baseline:" line with the new summary link and accuracy; keep a link to the 2026-10-13 baseline. Commit `docs(benchmarks): routing re-baseline with plan-file-aware observer`, PR.

---

### Task 5: WS-F trial run on `large-graph` (Phase B; needs Tasks 2 and 3 merged and the user's go-ahead)

**Files:**
- Create: `docs/superpowers/benchmarks/<YYYY-MM-DD>-large-graph-trial/` (`README.md`, `raw/<fixture>-<condition>-run<N>.md` from `collect`, `transcripts/`)

Scenario prompts are the three "Prompt" blocks in `tests/fixtures/large-graph/EXPECTATIONS.md`. One run each (PRD WS-F change 4: trial only; repeated runs are a later release).

- [ ] **Step 1: Claude runs** **[hand-off, Claude]** — for scenario `k` in 1..3 (run numbers 1, 2, 3):

```bash
REPO="$PWD"; SCRATCH="$(mktemp -d)"
BENCH_DIR="$(date +%Y-%m-%d)-large-graph-trial"
W="$(scripts/benchmark-isolated-run.sh prep large-graph with-skill $k --plugin-dir "$REPO" | sed -n 's/^Workdir: //p')"
(cd "$W" && claude -p "$PROMPT_k" --setting-sources project --plugin-dir "$REPO" \
   --permission-mode acceptEdits --allowedTools "Read Grep Glob Bash" \
   --max-budget-usd 3 --output-format json) > "$SCRATCH/claude-$k.json"
ruby -rjson -e 'print JSON.parse(File.read(ARGV[0]))["result"]' "$SCRATCH/claude-$k.json" > "$SCRATCH/claude-$k.md"
BENCH_DIR="$BENCH_DIR" BENCH_TRANSCRIPT="$SCRATCH/claude-$k.md" scripts/benchmark-isolated-run.sh collect large-graph with-skill $k
```

`--allowedTools "Read Grep Glob Bash"` is required: without it a headless run cannot read the skill's references (v0.9 WS-E finding). Scenario 3 is review-only; its diff must be empty.

- [ ] **Step 2: Codex runs** **[hand-off, Claude]** — only if Task 2 Step 7 showed 10 skills. Run numbers 11, 12, 13:

```bash
W="$(scripts/benchmark-isolated-run.sh prep large-graph with-skill 1$k --plugin-dir "$PWD" --agent codex | sed -n 's/^Workdir: //p')"
codex exec --disable plugins -s workspace-write -C "$W" -o "$SCRATCH/codex-$k.md" "$PROMPT_k" > /dev/null
BENCH_DIR="$BENCH_DIR" BENCH_TRANSCRIPT="$SCRATCH/codex-$k.md" scripts/benchmark-isolated-run.sh collect large-graph with-skill 1$k
```

Codex's sandbox blocks `tuist`/`xcodebuild`, so Codex cannot verify its own changes; `collect` verifies them. Record that limitation; do not widen the sandbox.

- [ ] **Step 3: Grade** **[Claude]**: for each run, compare the `collect` report and the transcript with the scenario's "Expected behavior" / "What must NOT happen" lists, item by item, citing report lines. Record whether the transcript has a valid `ios-tuist-result` block (`Block:` line in the report) — this answers PRD open question 4 for Codex.

- [ ] **Step 4: Write `README.md`** of the benchmark directory: setup (versions, budgets, allow-list), a table per run (scenario, agent, generate/build/test, tests executed, changed files, block validity, expectation items met/missed), findings, and limits (N=1, Codex cannot build in its sandbox). Copy the transcripts into `transcripts/`. Delete the scratch workdirs.

- [ ] **Step 5: Commit and PR** **[hand-off]**: `docs(benchmarks): add WS-F large-graph trial run`.

---

### Task 6: WS-G hooks decision record (Phase C; research by Claude, decision by the user)

**Files:**
- Create: `docs/superpowers/specs/<YYYY-MM-DD>-hooks-decision.md`

- [ ] **Step 1: Research** **[Claude]**: from official sources only, with links and the date checked: Claude Code plugin hooks (events, `hooks/hooks.json` in a plugin, how a `PreToolUse` hook blocks, matcher scope, whether a plugin hook applies to every session where the plugin is enabled); Codex 0.160.0 hooks (`~/.codex/hooks.json`, trust requirement, whether a plugin can ship hooks — `codex features list` shows `plugin_hooks removed`). Mark anything not confirmed as "Unverified".

- [ ] **Step 2: Evaluate the PRD candidates**: (a) warn when `.mise.toml` / `.tool-versions` / `.tuist-version` is edited outside `ios-tuist-migrate`; (b) after a manifest edit, suggest `scripts/skill/check-consumer-edges.sh`. For each: benefit, false positives and interference with normal work (a hook runs for every session where the plugin is enabled, not only when a skill is active), cross-agent consistency (Claude vs Codex), and maintenance cost.

- [ ] **Step 3: Recommendation and decision** **[Claude → user]**: write a recommended conclusion per candidate (adopt / defer / reject, with reasons), then ask the user. Record their decision in the document; no hook is implemented in this plan (PRD WS-G change 2).

- [ ] **Step 4: Commit and PR**: `docs(specs): record hooks decision (WS-G)`.

---

### Task 7: Release v0.9.1 (Claude + user)

- [ ] **Step 1**: on `develop` after Tasks 1-6 (or the subset the user chooses), branch `chore/release-0.9.1`; add `## [0.9.1] - <date>` under `## [Unreleased]` in `CHANGELOG.md` with: Fixed (Task 1), Added (Tasks 2, 3), benchmark and decision records (Tasks 4-6) with their results, Verification gates (Task 2 Step 7 result, Evidence 2-3), Known limitations (N=1; Codex cannot build inside its sandbox; `.external` edges not covered by `check-consumer-edges.sh`). Bump `.claude-plugin/plugin.json` to `0.9.1`; update README "Current release". PR into `develop`.
- [ ] **Step 2**: after the merge, PR `develop` → `main` titled `release: v0.9.1`; wait for every check including the fixture matrix (Global Constraints).
- [ ] **Step 3**: after the user merges and approves, annotated tag `v0.9.1` on the main merge commit (message `ios-tuist-skills 0.9.1`), push, `gh release create v0.9.1 --verify-tag --latest --title "v0.9.1 — Routing fix, cross-agent harness & large-graph fixture" --notes-file <CHANGELOG section + compare/v0.9.0...v0.9.1>`.

---

## Out of scope

- Routing misses `pos-feature-ko`, `pos-testtarget-en` (under-selection of `ios-tuist-feature`, `ios-tuist-test-target`): fixing them means changing skill descriptions, which needs its own change and a routing re-run. Task 4's comparison shows whether they persist.
- `plugin+official` and `none` routing conditions; repeated (N≥3) benchmark runs; `.external` support in `check-consumer-edges.sh`.
- Implementing any hook (WS-G records a decision only).
