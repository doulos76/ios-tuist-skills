# ios-tuist-skills v0.9 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Implementation owner: Codex.** This repo's Claude session only produced
> the research and this plan. Codex's `workspace-write` sandbox cannot
> `git commit`, reach the network, or run `mise`/`tuist`/`xcodebuild`/`claude`;
> steps marked **[hand-off]** are run by Claude or the user, and Codex
> continues from their pasted output.

**Goal:** Make the skills' deterministic checks executable and CI-tested, make each skill folder self-contained, make skill selection measurable, separate version-specific Tuist knowledge, and give skill output a machine-readable result block — without changing any skill's decision rules.

**Architecture:** Two read-only bash+ruby scripts (`scripts/skill/`) become the deterministic core, pinned by golden tests on the fixtures. A sync script copies every shared resource a skill links (references, templates, scripts) into that skill's folder, with a drift check in CI. A routing evaluation runs `claude -p` per case in fixture copies and records the first `Skill` tool_use. Version-specific defect knowledge moves to `references/tuist-known-issues.md` with a monthly recheck workflow. One task per workstream, one branch and PR each.

**Tech Stack:** bash, ruby stdlib (json, yaml), GitHub Actions (ubuntu-latest for lint/golden, macos-15 for fixtures), mise, Tuist 4.206.0 / 4.62.0 / 3.42.2 fixtures, Claude Code 2.1.296 headless (`claude -p --output-format stream-json`).

**Spec:** `docs/superpowers/specs/2026-10-02-ios-tuist-skills-v0.9-design.md` (PRD). Its §0 working rules apply. Where this plan and the PRD differ, the "Deviations from the PRD" section below is authoritative (all approved by the user on 2026-10-13); report any other conflict and stop.

## Global Constraints

- Base: `develop` at `a1dacba` (v0.8.1) or later. Branches `feature/v0.9-ws-<id>` cut from `develop`; one PR per task into `develop`.
- Order and dependencies: Task 1 (WS-H) → Task 2 (WS-A) → Task 3 (WS-B, needs Task 2 merged) → Task 4 (WS-E, needs Task 3) ; Task 5 (WS-C) is independent of Tasks 1-4 (it copies only the harness's isolation-guard rule; if Task 1 is merged first, follow Task 5 Step 11's `lint.yml` ordering note) ; Task 6 (WS-D) needs Task 3 ; Task 7 release.
- Scope: WS-H, WS-A, WS-B, WS-C, WS-D, WS-E. **WS-F and WS-G are out of scope** (v0.9.x).
- Skill Decision Rules keep their meaning (PRD §0.5). Scripts implement existing rules; they never add one. Prose procedures stay as the fallback.
- Scripts are read-only on the project they inspect: they never create, edit or delete files under the project root. Tests prove it.
- Languages: `#!/bin/bash` (`set -euo pipefail`, bash 3.2-compatible: no associative arrays, `mapfile`, `${x,,}`) + ruby stdlib only, **Ruby 2.6-compatible** (macOS `/usr/bin/ruby` is 2.6.10: no `filter_map`, `tally`, pattern matching, endless methods), as in `scripts/validate-fixtures-locally.sh`. No new runtimes, no gems, no Python in new code.
- Tests print `ok   - <name>` / `FAIL - <name>: <detail>` and exit non-zero on any FAIL (style of `tests/ci/test-select-fixtures.sh`).
- CI: unit tests of new scripts are **steps of the existing required `ci scripts` job** in `.github/workflows/lint.yml` (Tasks 1, 5). The golden tests (Task 2, job `golden tests`) and the skill-resource drift check (Task 3, job `skill resources`; Task 6 adds a step to it) are separate ubuntu jobs and are **not required** until the user adds them to branch protection on `develop` and `main` — each PR says so, and Task 7 asks the user.
- A script that `validate-fixtures.yml` calls must be added to the `everything` list in `scripts/ci-select-fixtures.sh` with a test case.
- Golden tests compare file-based evidence only; live command evidence (`tuist version`, `xcodebuild -version`, `swift --version`) is excluded (`--no-commands`) — user decision 2026-10-13.
- Routing baseline: `plugin-only` condition only, cap `$0.30` per case (`--max-budget-usd 0.30`) — user decision 2026-10-13. `plugin+official` and `none` are implemented but not run in this release.
- Never claim a result without pasted output. Anything not run goes under "Unverified" in the PR body.
- Commit messages: Conventional Commits, ending with the attribution line of the session that commits.

## Deviations from the PRD (approved 2026-10-13)

1. **WS-H added** (harness fixes found in the v0.8 WS6 smoke run): `Test: pass` was derived from the `xcodebuild test` exit code only, so a run with zero tests passed (`scripts/benchmark-isolated-run.sh` lines 189-197 at `a1dacba`); the changed-file count is raw `git status --porcelain | wc -l` (line 147) and counts generated artifacts. WS-H and WS-C are independent; WS-H is listed first because WS-E (Task 4) builds on its report fields.
2. **PRD WS-A change 3 (SKILL.md wiring) moves to WS-B.** The scripts are referenced as `${CLAUDE_SKILL_DIR}/scripts/<name>` (Claude Code docs, code.claude.com/docs/en/skills: "expands to the directory containing your skill's `SKILL.md` file"); that path only exists after WS-B's sync. Codex resolves relative paths against the SKILL.md directory (codex-rs `ext/skills/src/catalog_prompt.rs:29`, rust-v0.160.0).
3. **Script originals live in `scripts/skill/`**, not root `scripts/`, so CI/harness scripts are never synced into skills (PRD open question 1 kept as "root original + sync").
4. **WS-C observation method resolved by experiment** (2026-10-13, claude 2.1.296): skill use is a stream-json `tool_use` named `Skill` with input `{"skill":"ios-tuist-skills:<name>"}`; not documented, so the PR records it as "observed, undocumented". Stop rule = first `Skill` tool_use, first write tool, `result`, or budget cap (a positive case explored with `Bash` first). Codex: `codex exec --json` has no skill event type (rust-v0.160.0 `exec/src/exec_events.rs`) → Codex condition reported "unsupported".
5. **Numbers re-verified on `a1dacba`**: `../../` links = 46 (PRD: 42); fixture dirs = 12 (PRD: 11); 10 fixtures carry `.tool-versions`.
6. **More self-containment breaks than the PRD lists** (found while drafting Task 3): 7 sibling-skill links `../ios-tuist-x/SKILL.md` (restyle 1, scaffold 4, test-target 2); 9 skills say "same procedure as `ios-tuist-bootstrap`" for evidence-driven debugging → new shared `references/evidence-driven-debugging.md`; `references/testing.md:30` links `../templates/`. Same class of defect as PRD WS-B, so in scope.
7. **`check-consumer-edges.sh` covers local `.target`/`.project` edges only.** `ios-tuist-dependency` mostly adds package (`.external`) edges, whose product name can differ from the imported module, so packages keep the manual `import` check.
8. **Template copies carry no GENERATED header** (bootstrap copies templates into user projects); the sync manifest and the CI drift check record provenance.
9. **Version-evidence JSON**: `project_root` (absolute path) is excluded from golden comparison like `commands`; `swift.swift_version.label_basis` (`effective|active|none`) records which version the label used.
10. **Routing**: 45 cases (the PRD category minimums sum to 42); new files in `~/.claude/plans` during a case are listed in the results, never deleted or moved (another session may write there at the same time).

## Review Focus

1. A project with **no Tool Version source at all** (e.g. `tests/fixtures/new-project`) — `collect-version-evidence.sh` must print "none detected" / JSON `effective: null`, exit 0, not crash. Pinned in Task 2 synthetic golden case `no-pin`.
2. **`.tuist-version` present together with `.tool-versions` of a different value** — `.tool-versions` is effective, `.tuist-version` appears under conflicts with `conditional: true`. Pinned in Task 2 synthetic case.
3. **A skill folder copied alone** to a temp dir — every relative link and script path in it resolves; no `../`. Pinned in Task 3 standalone-copy test.
4. **A routing case whose prompt makes Claude explore before choosing** — the eval must not record `none` just because the first tool was `Bash`. Pinned in Task 5 parser test with the real event sequence.
5. **A test run where the scheme has zero tests** — the harness reports `pass-empty`, never `pass`. Pinned in Task 1 parser test with an `Executed 0 tests` log.

---

### Task 1: WS-H — benchmark harness fixes

**Why:** The WS6 smoke run (`docs/superpowers/benchmarks/2026-10-06-ws6-smoke/README.md:17`) found two harness defects. (1) `Test: pass` was reported when `xcodebuild test` ran 0 tests: `raw/extract-candidate-baseline-run1.md:75` says `Executed 0 tests` and `:88` says `Test: pass`. (2) The changed-file count is a raw `git status --porcelain | wc -l`, which counts Tuist/Xcode generation output and collapses untracked directories. WS-C and later benchmarks reuse this harness, so these get fixed first.

**Branch:** `feature/v0.9-ws-h` from `develop`.

**Files:**
- Create: `scripts/bench-summarize.sh`. Pure text helpers, so they can be tested on Linux without Xcode.
- Create: `tests/harness/test-bench-summarize.sh`
- Create: canned inputs under `tests/harness/fixtures/`: `xctest-zero.log`, `mixed-swift-testing.log`, `xctest-nested.log`, `swift-testing-fail.log`, `no-summary.log`, `status-porcelain.txt`
- Modify: `scripts/benchmark-isolated-run.sh`. Three regions: changed-file count (lines 144-147), test loop (lines 186-197), summary (lines 211-215). The line numbers are as of `develop` `a1dacba`.
- Modify: `.github/workflows/lint.yml`. Add two steps to the `ci-scripts` job.
- Create: `tests/harness/test-prep-excludes-expectations.sh`; modify `prep` in `scripts/benchmark-isolated-run.sh` (drop `EXPECTATIONS.md` from the workdir, Step 7b)
- Modify (footnotes only): `docs/superpowers/benchmarks/2026-09-20-skill-effectiveness/AGGREGATE-SUMMARY.md`, `docs/superpowers/benchmarks/2026-10-06-ws6-smoke/README.md`

**Interfaces:**
- Consumes: nothing from other v0.9 tasks.
- Produces. WS-C and WS-E rely on these exact strings.
  - `scripts/bench-summarize.sh tests <log>` prints one integer, or `unknown`.
  - `scripts/bench-summarize.sh changed <porcelain-file>` prints `<raw> <excluding-generated>`.
  - `scripts/bench-summarize.sh patterns` prints the generated-path patterns, one per line.
  - The collect report's final summary block gains these lines, in this order:
    ```text
    Resolve: <pass|fail|skipped>
    Generate: <pass|fail|skipped>
    Build: <pass|fail|skipped>
    Test: <pass|fail|pass-empty|skipped>
    Tests executed: <N|unknown>
    Changed files (raw): <N>
    Changed files (excluding generated): <M>
    ```
  - `pass-empty` means every scheme exited 0 and at least one scheme reported exactly 0 executed tests. It does **not** make the script exit non-zero; only `fail` does. That keeps the old exit semantics.

**Evidence to re-verify before editing.** Stop and report if any check differs.
```bash
sed -n 144,147p scripts/benchmark-isolated-run.sh   # must show the 4 lines quoted in Step 5
sed -n 186,197p scripts/benchmark-isolated-run.sh   # must show the loop quoted in Step 6
sed -n 211,215p scripts/benchmark-isolated-run.sh   # must show the summary quoted in Step 7
grep -n 'Executed 0 tests' docs/superpowers/benchmarks/2026-10-06-ws6-smoke/raw/extract-candidate-baseline-run1.md   # line 75
grep -n 'Test run with 1 test in 0 suites' docs/superpowers/benchmarks/2026-10-06-ws6-smoke/raw/extract-candidate-with-skill-run2.md  # line 66
```

**Counting rule.** It is a heuristic; the PR states it.
- XCTest prints nested suite summaries, `Executed N tests, with ...`: one per class, one per bundle, and `All tests`. The outermost one is the largest, so the rule takes the **max** of all XCTest `Executed N test(s)` numbers.
- Swift Testing prints `✔ Test run with N test(s) in M suite(s) passed …` (or `✘ … failed …`) once per run, so the rule takes the **max** of those too.
- A scheme with both frameworks gets the sum of the two maxima.
- If neither line appears, the count is `unknown`.

- [ ] **Step 1: Create the canned inputs.** Lines copied from real reports are marked; the rest are synthetic but follow the same formats.

`tests/harness/fixtures/xctest-zero.log`. Real: `extract-candidate-baseline-run1.md:72-82`.
```text
Test Suite 'All tests' started at 2026-10-06 05:10:16.122.
Test Suite 'All tests' passed at 2026-10-06 05:10:16.122.
	 Executed 0 tests, with 0 failures (0 unexpected) in 0.000 (0.000) seconds

Test session results, code coverage, and logs:
	/Users/example/Library/Developer/Xcode/DerivedData/App-x/Logs/Test/Test-App.xcresult

** TEST SUCCEEDED **
```

`tests/harness/fixtures/mixed-swift-testing.log`. Real: `extract-candidate-with-skill-run2.md:57-71`.
```text
Test Suite 'All tests' started at 2026-10-06 05:39:07.237.
Test Suite 'All tests' passed at 2026-10-06 05:39:07.237.
	 Executed 0 tests, with 0 failures (0 unexpected) in 0.000 (0.000) seconds
◇ Test run started.
↳ Testing Library Version: 2084
↳ Target Platform: arm64-apple-ios17.0-simulator
◇ Test requestBuilderComposesProfilePath() started.
✔ Test requestBuilderComposesProfilePath() passed after 0.001 seconds.
✔ Test run with 1 test in 0 suites passed after 0.001 seconds.

** TEST SUCCEEDED **
```

`tests/harness/fixtures/xctest-nested.log` (synthetic, XCTest format):
```text
Test Suite 'All tests' started at 2026-10-13 10:00:00.000.
Test Suite 'AppTests.xctest' started at 2026-10-13 10:00:00.001.
Test Suite 'AppTests' started at 2026-10-13 10:00:00.001.
Test Case '-[AppTests.AppTests testA]' passed (0.001 seconds).
Test Case '-[AppTests.AppTests testB]' passed (0.001 seconds).
Test Suite 'AppTests' passed at 2026-10-13 10:00:00.003.
	 Executed 2 tests, with 0 failures (0 unexpected) in 0.002 (0.002) seconds
Test Suite 'MoreTests' started at 2026-10-13 10:00:00.003.
Test Case '-[AppTests.MoreTests testC]' passed (0.001 seconds).
Test Case '-[AppTests.MoreTests testD]' passed (0.001 seconds).
Test Case '-[AppTests.MoreTests testE]' passed (0.001 seconds).
Test Suite 'MoreTests' passed at 2026-10-13 10:00:00.006.
	 Executed 3 tests, with 0 failures (0 unexpected) in 0.003 (0.003) seconds
Test Suite 'AppTests.xctest' passed at 2026-10-13 10:00:00.006.
	 Executed 5 tests, with 0 failures (0 unexpected) in 0.005 (0.005) seconds
Test Suite 'All tests' passed at 2026-10-13 10:00:00.006.
	 Executed 5 tests, with 0 failures (0 unexpected) in 0.005 (0.006) seconds

** TEST SUCCEEDED **
```

`tests/harness/fixtures/swift-testing-fail.log` (synthetic, Swift Testing format):
```text
◇ Test run started.
✘ Test featureFlagDefaults() recorded an issue at FeatureATests.swift:9:5: Expectation failed
✘ Test run with 3 tests in 1 suite failed after 0.004 seconds with 1 issue.

** TEST FAILED **
```

`tests/harness/fixtures/no-summary.log` (synthetic: build failed before testing):
```text
error: Unable to find module dependency: 'NetworkingKit'
** TEST FAILED **
```

`tests/harness/fixtures/status-porcelain.txt` holds `git status --porcelain --untracked-files=all` output. Every line starts with the two status columns plus a space:
```text
 M Project.swift
?? App.xcodeproj/project.pbxproj
?? App.xcworkspace/contents.xcworkspacedata
?? Derived/InfoPlists/App-Info.plist
?? Tuist/.build/workspace-state.json
?? NetworkingKit/Sources/Client.swift
R  App/Sources/Old.swift -> App/Sources/New.swift
?? "App/Sources/Weird Name.swift"
?? DerivedData/Logs/x.txt
?? Test-App.xcresult/Info.plist
```
Expected: raw `10`, excluding generated `4`. The 4 kept are `Project.swift`, `NetworkingKit/Sources/Client.swift`, `App/Sources/New.swift` and `App/Sources/Weird Name.swift`.

- [ ] **Step 2: Write the failing test** `tests/harness/test-bench-summarize.sh`, then `chmod +x` it.

```bash
#!/bin/bash
# Unit tests for scripts/bench-summarize.sh (bash + ruby only, no Xcode).
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SUM="$REPO_ROOT/scripts/bench-summarize.sh"
FIX="$REPO_ROOT/tests/harness/fixtures"
failures=0

expect() {
  local name="$1" want="$2"; shift 2
  local got; got="$("$@" 2>&1)"
  if [ "$got" = "$want" ]; then
    echo "ok   - $name"
  else
    echo "FAIL - $name: expected [$want], got [$got]"
    failures=$((failures + 1))
  fi
}

expect "xctest zero tests"              "0"       "$SUM" tests "$FIX/xctest-zero.log"
expect "xctest 0 + swift testing 1"     "1"       "$SUM" tests "$FIX/mixed-swift-testing.log"
expect "nested xctest summaries -> max" "5"       "$SUM" tests "$FIX/xctest-nested.log"
expect "swift testing failed run"       "3"       "$SUM" tests "$FIX/swift-testing-fail.log"
expect "no summary line -> unknown"     "unknown" "$SUM" tests "$FIX/no-summary.log"
expect "changed raw vs excluding gen"   "10 4"    "$SUM" changed "$FIX/status-porcelain.txt"
expect "empty status"                   "0 0"     "$SUM" changed /dev/null
expect "pattern list" "$(printf '%s\n' '*.xcodeproj/' '*.xcworkspace/' 'Derived/' '.build/' 'Tuist/.build/' 'DerivedData/' '*.xcresult/')" "$SUM" patterns

[ "$failures" -eq 0 ] && echo "all bench-summarize tests passed" || echo "$failures bench-summarize test(s) failed"
exit "$failures"
```

- [ ] **Step 3: Run it and confirm it fails**

Run: `./tests/harness/test-bench-summarize.sh`
Expected: every line `FAIL - …`, because `scripts/bench-summarize.sh` does not exist yet (`No such file or directory`). Exit code 8.

- [ ] **Step 4: Implement `scripts/bench-summarize.sh`, then `chmod +x` it**

```bash
#!/bin/bash
# Text-only helpers for benchmark-isolated-run.sh; no Xcode needed, so CI can test them.
#   bench-summarize.sh tests <xcodebuild-log>    -> executed test count, or "unknown"
#   bench-summarize.sh changed <porcelain-file>  -> "<raw> <excluding-generated>"
#   bench-summarize.sh patterns                  -> generated-path patterns, one per line
set -euo pipefail

usage() { echo "Usage: $0 tests <log> | changed <porcelain-file> | patterns" >&2; exit 2; }
[ "$#" -ge 1 ] || usage

case "$1" in
  tests)
    [ "$#" -eq 2 ] || usage
    ruby -e '
      text = File.read(ARGV[0], mode: "rb").force_encoding("UTF-8").scrub
      # XCTest nests suite summaries (class < bundle < "All tests"), so the outermost is the max.
      xctest = text.scan(/\bExecuted (\d+) tests?, with /).flatten.map(&:to_i)
      # Swift Testing prints one run summary: "Test run with N test(s) in M suite(s) passed|failed".
      swift_testing = text.scan(/\bTest run with (\d+) tests? in /).flatten.map(&:to_i)
      if xctest.empty? && swift_testing.empty?
        puts "unknown"
      else
        puts (xctest.max || 0) + (swift_testing.max || 0)
      end
    ' "$2"
    ;;
  changed)
    [ "$#" -eq 2 ] || usage
    ruby -e '
      generated = lambda do |path|
        parts = path.split("/")
        parts.any? { |p| p.end_with?(".xcodeproj", ".xcworkspace", ".xcresult") } ||
          parts.any? { |p| %w[Derived .build DerivedData].include?(p) }
      end
      raw = 0
      kept = 0
      File.foreach(ARGV[0]) do |line|
        line = line.chomp
        next if line.strip.empty?
        path = line[3..].to_s
        path = path.split(" -> ", 2).last if path.include?(" -> ")
        path = path[1..-2] if path.start_with?("\"") && path.end_with?("\"")
        raw += 1
        kept += 1 unless generated.call(path)
      end
      puts "#{raw} #{kept}"
    ' "$2"
    ;;
  patterns)
    [ "$#" -eq 1 ] || usage
    printf '%s\n' '*.xcodeproj/' '*.xcworkspace/' 'Derived/' '.build/' 'Tuist/.build/' 'DerivedData/' '*.xcresult/'
    ;;
  *) usage ;;
esac
```

(`Tuist/.build/` is listed for readers. The `.build` component rule already covers it.)

- [ ] **Step 5: Replace the changed-file count in `scripts/benchmark-isolated-run.sh`**

Replace these lines (144-147):
```bash
  echo '--- git diff --stat HEAD ---'
  git diff --stat HEAD
  echo '--- changed-file count (including untracked) ---'
  git status --porcelain | wc -l
```
with:
```bash
  echo '--- git diff --stat HEAD ---'
  git diff --stat HEAD
  # -uall lists files inside untracked dirs; generated Tuist/Xcode output is counted separately.
  git status --porcelain --untracked-files=all > "$WORKDIR/../status-after.txt"
  read -r changed_raw changed_filtered < <("$REPO_ROOT/scripts/bench-summarize.sh" changed "$WORKDIR/../status-after.txt")
  echo '--- changed files (untracked files listed individually) ---'
  cat "$WORKDIR/../status-after.txt"
  echo "Excluded as generated: $("$REPO_ROOT/scripts/bench-summarize.sh" patterns | tr '\n' ' ')"
```
Also add `tests_executed=unknown`, `changed_raw=unknown` and `changed_filtered=unknown` right after the existing `test=skipped` line (line 130), so every summary line has a value even on early failure:
```bash
test=skipped
tests_executed=unknown
changed_raw=unknown
changed_filtered=unknown
```

Note: raw counts from earlier reports used the collapsed `git status --porcelain`, so they cannot be compared one-to-one with the new raw count. The PR body says so.

- [ ] **Step 6: Replace the test loop**

Replace these lines (186-197):
```bash
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
```
with:
```bash
            test=pass
            tests_executed=0
            for scheme in $test_schemes; do
              echo "--- xcodebuild test (scheme $scheme) ---"
              # The full log is needed to count executed tests; the report keeps only its tail.
              test_log="$WORKDIR/../xcodebuild-test-$scheme.log"
              xcodebuild test \
                -workspace "$workspace.xcworkspace" \
                -scheme "$scheme" \
                -destination "id=$SIMULATOR_ID" \
                > "$test_log" 2>&1
              test_status=$?
              tail -20 "$test_log"
              echo "Full log: $test_log"
              scheme_count="$("$REPO_ROOT/scripts/bench-summarize.sh" tests "$test_log")"
              echo "Tests executed (scheme $scheme): $scheme_count"
              if [ "$test_status" -ne 0 ]; then
                test=fail
              elif [ "$scheme_count" = 0 ] && [ "$test" = pass ]; then
                # Exit 0 with nothing executed is not evidence that tests passed.
                test=pass-empty
              fi
              if [ "$scheme_count" = unknown ] || [ "$tests_executed" = unknown ]; then
                tests_executed=unknown
              else
                tests_executed=$((tests_executed + scheme_count))
              fi
            done
```

- [ ] **Step 7: Extend the summary**

Replace these lines (211-215):
```bash
  echo "Resolve: $resolve"
  echo "Generate: $generate"
  echo "Build: $build"
  echo "Test: $test"
} > "$REPORT" 2>&1
```
with:
```bash
  echo "Resolve: $resolve"
  echo "Generate: $generate"
  echo "Build: $build"
  echo "Test: $test"
  echo "Tests executed: $tests_executed"
  echo "Changed files (raw): $changed_raw"
  echo "Changed files (excluding generated): $changed_filtered"
} > "$REPORT" 2>&1
```
Leave the final `exit 1` condition unchanged: `pass-empty` is reported, not fatal.

- [ ] **Step 7b: Keep the answer key out of the agent's workdir (user decision 2026-10-13).** In the 2026-10-13 routing experiment the model read `EXPECTATIONS.md` from a fixture copy. `prep` copies the whole fixture, so the agent can read the expected outcome.

First write the failing test `tests/harness/test-prep-excludes-expectations.sh` (`chmod +x`). It needs only git and ruby: `prep` does not call tuist, xcodebuild or claude.
```bash
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
```
Run: `./tests/harness/test-prep-excludes-expectations.sh` → Expected now: `FAIL - EXPECTATIONS.md absent` and `FAIL - not in baseline commit`, exit 1.

Then in `scripts/benchmark-isolated-run.sh`, replace:
```bash
  cp -R "$SRC" "$WORKDIR" || exit 1
```
with:
```bash
  cp -R "$SRC" "$WORKDIR" || exit 1
  # EXPECTATIONS.md is the grader's answer key; an agent that reads it is no longer measured.
  rm -f -- "$WORKDIR/EXPECTATIONS.md"
```
Run the test again → Expected: four `ok   - …` lines and `all prep tests passed`.

`collect` and graders read `EXPECTATIONS.md` from the repo's `tests/fixtures/<fixture>/`, not from the workdir; confirm with `grep -n EXPECTATIONS scripts/benchmark-isolated-run.sh` (expected: only the new comment and `rm` line).

Add a footnote (scores unchanged, as in v0.8) to the two earlier evidence sets, since their agents could read the answer key:
- `docs/superpowers/benchmarks/2026-09-20-skill-effectiveness/AGGREGATE-SUMMARY.md`: append after the existing `‡` line:
  `§ Not verified: whether agents read the fixture's \`EXPECTATIONS.md\` (the expected outcome), which was present in every run's working copy; v0.9 WS-H removes it from harness workdirs. Scores above are unchanged.`
- `docs/superpowers/benchmarks/2026-10-06-ws6-smoke/README.md`: append at the end:
  `Note (v0.9 WS-H): each run's workdir contained the fixture's \`EXPECTATIONS.md\` (the expected outcome); whether the agent read it was not checked. Results above are unchanged.`

- [ ] **Step 8: Add the unit test to CI.** In `.github/workflows/lint.yml`, under job `ci-scripts`, after
```yaml
      - name: Fixture selection unit tests
        run: ./tests/ci/test-select-fixtures.sh
```
insert:
```yaml
      - name: Benchmark summarizer unit tests
        run: ./tests/harness/test-bench-summarize.sh
      - name: Benchmark prep excludes answer key
        run: ./tests/harness/test-prep-excludes-expectations.sh
```
Because the step is in the required `ci scripts` job, it gates merges without changing branch protection.

- [ ] **Step 9: Run the unit test and syntax checks; all must pass**

```bash
./tests/harness/test-bench-summarize.sh
./tests/harness/test-prep-excludes-expectations.sh
bash -n scripts/benchmark-isolated-run.sh && echo "syntax ok"
bash -n scripts/bench-summarize.sh && echo "syntax ok"
ruby -ryaml -e 'YAML.load_file(".github/workflows/lint.yml"); puts "yaml ok"'
./tests/ci/test-select-fixtures.sh | tail -1
```
Expected: 8 `ok   - …` lines and `all bench-summarize tests passed`, then `all prep tests passed`, then `syntax ok`, `syntax ok`, `yaml ok`, `all selection tests passed`. `tests/harness/**` is outside `tests/fixtures/`, so fixture selection does not change.

- [ ] **Step 10 [hand-off: Claude/user, needs mise/tuist/xcodebuild]: real harness run plus a check of the generated paths.** Run on the unchanged `extract-candidate`:
```bash
./scripts/benchmark-isolated-run.sh prep extract-candidate baseline 901
# No agent session: collect immediately on the untouched copy.
BENCH_DIR=2026-10-ws-h-check ./scripts/benchmark-isolated-run.sh collect extract-candidate baseline 901
tail -8 docs/superpowers/benchmarks/2026-10-ws-h-check/raw/extract-candidate-baseline-run901.md
```
Expected tail: `Resolve: pass`, `Generate: pass`, `Build: pass`, `Test: pass` (or `pass-empty` if `AppTests` runs nothing; record which), `Tests executed: <N>`, `Changed files (raw): 0`, `Changed files (excluding generated): 0`.

Then confirm the patterns cover what `tuist generate` writes. In the same workdir (path printed by `prep`), run:
```bash
cd <workdir> && mise exec -- tuist generate --no-open && git status --porcelain --untracked-files=all > /tmp/gen-status.txt
"$OLDPWD/scripts/bench-summarize.sh" changed /tmp/gen-status.txt
cat /tmp/gen-status.txt
```
Expected: `<raw> 0`. Every path generate creates is excluded. If any generated path survives the filter, add its pattern to both the `patterns` list and the `generated` lambda, plus a line to `status-porcelain.txt` with an updated expectation, and re-run Step 9. Paste the `cat` output in the PR.

Afterwards, delete the check output; it is not committed: `rm -rf docs/superpowers/benchmarks/2026-10-ws-h-check "$TMPDIR"/state-extract-candidate-baseline-run901* <workdir parent>`.

- [ ] **Step 11 [hand-off: Claude]: commit**
```bash
git add scripts/bench-summarize.sh scripts/benchmark-isolated-run.sh tests/harness .github/workflows/lint.yml docs/superpowers/benchmarks/2026-09-20-skill-effectiveness/AGGREGATE-SUMMARY.md docs/superpowers/benchmarks/2026-10-06-ws6-smoke/README.md
git commit -m "fix(bench): count executed tests, exclude generated files and the answer key"
```

- [ ] **Step 12 [hand-off: Claude]: PR into `develop`.** The body must contain:
  - What changed: the three report fields, the `pass-empty` meaning, and the exclusion patterns.
  - The Step 9 output, plus the Step 10 tail and generated-path listing.
  - Unverified:
    - The counting rule is a heuristic based on XCTest/Swift Testing log formats seen in Xcode on this machine (record `xcodebuild -version`).
    - Raw counts are not comparable with pre-v0.9 reports.
    - Whether agents in the 2026-09-20 benchmark and the 2026-10-06 smoke run read `EXPECTATIONS.md` (footnoted, scores unchanged).


---

### Task 2: WS-A — deterministic scripts + golden tests

**Branch:** `feature/v0.9-ws-a` from `develop` (after Task 1 is merged is NOT required; Task 2 is independent of Task 1).

**Goal:** Two read-only, deterministic scripts that compute what the skills currently derive in prose — version-safety evidence and newly added consumer edges — plus golden tests and a CI job. **This task does not edit any `SKILL.md`** (wiring moves to Task 3/WS-B, because `${CLAUDE_SKILL_DIR}/scripts/...` only exists after the sync).

**Files:**
- Create: `scripts/skill/collect-version-evidence.sh`
- Create: `scripts/skill/check-consumer-edges.sh`
- Create: `scripts/run-golden-tests.sh`
- Create: `tests/golden/test-version-evidence.sh`, `tests/golden/test-consumer-edges.sh`, `tests/golden/test-read-only.sh`
- Create: `tests/golden/version-evidence/<fixture>.expected.json` (10 files, one per `tests/fixtures/ci-matrix.json` entry)
- Create: `tests/golden/version-evidence/synthetic/<case>.expected.json` (8 files)
- Create: `tests/golden/consumer-edges/no-usage/after/Project.swift`, `tests/golden/consumer-edges/no-usage/expected.json`
- Create: `tests/golden/consumer-edges/with-usage/after/Project.swift`, `tests/golden/consumer-edges/with-usage/after/App/Sources/ExtractCandidateApp.swift`, `tests/golden/consumer-edges/with-usage/expected.json`
- Modify: `.github/workflows/lint.yml` (new job `golden tests`)

**Interfaces:**
- Consumes: `references/version-safety.md` as of v0.8.1 (develop `a1dacba`) — source order, `.tuist-version` conditional rule, `swiftVersion` label table.
- Produces (Tasks 3 and 4 rely on these exact names):
  - `scripts/skill/collect-version-evidence.sh [--json] [--no-commands] [PROJECT_ROOT]` → exit 0; exit 2 on usage error / missing dir. JSON schema `ios-tuist-version-evidence/1`, top-level keys `schema, project_root, tool_version{sources,effective,conflicts}, xcode, swift, commands`. `source` values: `mise`, `.tool-versions`, `.tuist-version`, `ci-workflow`, `script`. `swift.swift_version` = `{value, path, label, label_basis}` with `label ∈ {consumed, stored only, deprecated, ignored, unknown}` or `null` when no `swiftVersion`; `label_basis ∈ {effective, active, none}` or `null`.
  - `scripts/skill/check-consumer-edges.sh [--json] --before <dir|git-rev> [PROJECT_ROOT]` → exit 0; exit 2 on usage error / unknown revision. JSON schema `ios-tuist-consumer-edges/1`: `{schema, added:[{from,to,usage:"<file:line>"|null}], removed:[{from,to}], note}`.
  - `scripts/run-golden-tests.sh` — runs a fixed list of test scripts (Task 4 appends to the list).
  - CI job name `golden tests` (not a required check unless the user adds it).

**Contract deltas vs `scratchpad/v09/contracts.md` (made here, binding for Tasks 3–4):** (1) golden comparisons drop `project_root` as well as `commands` (absolute paths differ per machine); (2) `swift.swift_version` gains `label_basis` (version-safety.md says "use the active Tuist version and say so"); (3) `check-consumer-edges.sh --json` also emits the caveat as `"note"`; (4) Ruby code stays 2.6-compatible (macOS `/usr/bin/ruby` is 2.6.10; ubuntu-latest has 3.2).

**Evidence to re-verify before editing (stop and report if different):**

```bash
find skills -type f ! -name SKILL.md ! -name .gitkeep            # expect: no output
ls scripts/skill 2>/dev/null                                      # expect: no such directory
ls tests/golden 2>/dev/null                                       # expect: no such directory
ls tests/fixtures/*/.tool-versions | wc -l                        # expect: 10
ruby -rjson -e 'puts JSON.parse(File.read("tests/fixtures/ci-matrix.json")).size'   # expect: 10
find tests/fixtures -name Package.swift                           # expect: no output
cat tests/fixtures/ci-gaps/.github/workflows/ci.yml | sed -n 14,18p   # expect the mise-action step with "tuist 4.206.0"
```

Known limits (write them into the PR body, do not "fix" them): `.tuist-version` is read only at PROJECT_ROOT (tuistenv also walks parents); the order among mise's own config paths is a fixed list, not verified against mise's precedence; CI/script pins are found by regex (`tuist 1.2.3`, `tuist@1.2.3`, `TUIST_VERSION: 1.2.3`); the consumer-edge search is static (no `@_exported` re-exports, macros or resources).

- [ ] **Step 1: Write the golden data and the failing tests**

Create the test scripts exactly as below.

`tests/golden/test-version-evidence.sh`:

```bash
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
```

`tests/golden/test-consumer-edges.sh`:

```bash
#!/bin/bash
# Golden tests for scripts/skill/check-consumer-edges.sh on extract-candidate:
# an added App -> NetworkingKit edge without and with an import in App.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
EDGES="$REPO_ROOT/scripts/skill/check-consumer-edges.sh"
GOLDEN="$REPO_ROOT/tests/golden/consumer-edges"
FIXTURE="$REPO_ROOT/tests/fixtures/extract-candidate"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/golden-ce.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
failures=0

for case_name in no-usage with-usage; do
  work="$TMP/$case_name"
  cp -R "$FIXTURE" "$work"
  # The case's after/ tree overlays the fixture copy (the "after" state).
  cp -R "$GOLDEN/$case_name/after/." "$work/"
  if "$EDGES" --json --before "$FIXTURE" "$work" > "$TMP/actual.json" &&
    ruby -rjson -e '
      a = JSON.parse(File.read(ARGV[0])); e = JSON.parse(File.read(ARGV[1]))
      exit 0 if a == e
      warn "expected:\n#{JSON.pretty_generate(e)}\nactual:\n#{JSON.pretty_generate(a)}"
      exit 1
    ' "$TMP/actual.json" "$GOLDEN/$case_name/expected.json"; then
    echo "ok   - consumer edges $case_name"
  else
    echo "FAIL - consumer edges $case_name"
    failures=$((failures + 1))
  fi
done

# git-revision mode: an unchanged fixture has no added or removed edge.
if "$EDGES" --json --before HEAD "$FIXTURE" | ruby -rjson -e '
    h = JSON.parse(STDIN.read); exit(h["added"].empty? && h["removed"].empty? ? 0 : 1)'; then
  echo "ok   - --before HEAD on unchanged fixture"
else
  echo "FAIL - --before HEAD on unchanged fixture"
  failures=$((failures + 1))
fi

# The caveat is part of every human-readable report.
if "$EDGES" --before HEAD "$FIXTURE" | grep -qF 'note: no usage found != dependency unnecessary'; then
  echo "ok   - caveat line printed"
else
  echo "FAIL - caveat line printed"
  failures=$((failures + 1))
fi

# An unknown revision is a usage error, not an empty result.
"$EDGES" --before no-such-rev-v09 "$FIXTURE" > /dev/null 2>&1
status=$?
if [ "$status" -eq 2 ]; then
  echo "ok   - unknown revision exits 2"
else
  echo "FAIL - unknown revision exits 2 (got $status)"
  failures=$((failures + 1))
fi

[ "$failures" -eq 0 ] && echo "all consumer-edge tests passed" || echo "$failures consumer-edge test(s) failed"
exit "$failures"
```

`tests/golden/test-read-only.sh`:

```bash
#!/bin/bash
# Both skill scripts must leave every fixture untouched (PRD WS-A acceptance):
# same git status and the same file list (including untracked/ignored files).
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/golden-ro.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

state() {
  git -C "$REPO_ROOT" status --porcelain --ignored -- tests/fixtures
  (cd "$REPO_ROOT/tests/fixtures" && find . -print | LC_ALL=C sort)
}

state > "$TMP/before"
for dir in "$REPO_ROOT"/tests/fixtures/*/; do
  "$REPO_ROOT/scripts/skill/collect-version-evidence.sh" --no-commands "$dir" > /dev/null
  "$REPO_ROOT/scripts/skill/collect-version-evidence.sh" --json --no-commands "$dir" > /dev/null
  "$REPO_ROOT/scripts/skill/check-consumer-edges.sh" --before HEAD "$dir" > /dev/null
done
state > "$TMP/after"

if diff -u "$TMP/before" "$TMP/after"; then
  echo "ok   - scripts left tests/fixtures unchanged"
  exit 0
fi
echo "FAIL - scripts left tests/fixtures unchanged"
exit 1
```

`scripts/run-golden-tests.sh`:

```bash
#!/bin/bash
# Runs every golden/unit test of the deterministic skill scripts. CI: lint.yml "golden tests".
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
failed=0
for t in \
  tests/golden/test-version-evidence.sh \
  tests/golden/test-consumer-edges.sh \
  tests/golden/test-read-only.sh; do
  echo "## $t"
  "$REPO_ROOT/$t" || failed=$((failed + 1))
done
[ "$failed" -eq 0 ] && echo "all golden suites passed" || echo "$failed golden suite(s) failed"
exit "$failed"
```

Make them executable: `chmod +x tests/golden/*.sh scripts/run-golden-tests.sh`.

Golden JSON files. These were produced on 2026-10-13 by reading each fixture's real files at develop `a1dacba` (all 10 fixtures pin Tuist with `.tool-versions` only; only `ci-gaps` also pins it in a workflow; none declares `swiftVersion`, `compatibleXcodeVersions`, `.xcode-version`, `.swift-version` or a `Package.swift`). Write them byte-for-byte (single-line JSON; the test compares parsed JSON, so formatting does not matter, but keep these bytes so reviewers can diff):

```bash
mkdir -p tests/golden/version-evidence/synthetic
for f in architecture-smells extract-candidate legacy-tuist modular restyle-candidate scaffold-candidate test-target-candidate; do
  cat > "tests/golden/version-evidence/$f.expected.json" <<'JSON'
{"schema":"ios-tuist-version-evidence/1","tool_version":{"sources":[{"source":".tool-versions","path":".tool-versions","value":"4.206.0","conditional":false}],"effective":{"value":"4.206.0","source":".tool-versions"},"conflicts":[]},"xcode":{"compatible_xcode_versions":null,"xcode_version_file":null},"swift":{"swift_version":{"value":null,"path":null,"label":null,"label_basis":null},"package_swift_tools":null,"tuist_package_swift_tools":null,"swift_version_file":null}}
JSON
done
cat > tests/golden/version-evidence/ci-gaps.expected.json <<'JSON'
{"schema":"ios-tuist-version-evidence/1","tool_version":{"sources":[{"source":".tool-versions","path":".tool-versions","value":"4.206.0","conditional":false},{"source":"ci-workflow","path":".github/workflows/ci.yml","value":"4.206.0","conditional":false}],"effective":{"value":"4.206.0","source":".tool-versions"},"conflicts":[]},"xcode":{"compatible_xcode_versions":null,"xcode_version_file":null},"swift":{"swift_version":{"value":null,"path":null,"label":null,"label_basis":null},"package_swift_tools":null,"tuist_package_swift_tools":null,"swift_version_file":null}}
JSON
cat > tests/golden/version-evidence/migrate-candidate.expected.json <<'JSON'
{"schema":"ios-tuist-version-evidence/1","tool_version":{"sources":[{"source":".tool-versions","path":".tool-versions","value":"3.42.2","conditional":false}],"effective":{"value":"3.42.2","source":".tool-versions"},"conflicts":[]},"xcode":{"compatible_xcode_versions":null,"xcode_version_file":null},"swift":{"swift_version":{"value":null,"path":null,"label":null,"label_basis":null},"package_swift_tools":null,"tuist_package_swift_tools":null,"swift_version_file":null}}
JSON
cat > tests/golden/version-evidence/version-mismatch.expected.json <<'JSON'
{"schema":"ios-tuist-version-evidence/1","tool_version":{"sources":[{"source":".tool-versions","path":".tool-versions","value":"4.62.0","conditional":false}],"effective":{"value":"4.62.0","source":".tool-versions"},"conflicts":[]},"xcode":{"compatible_xcode_versions":null,"xcode_version_file":null},"swift":{"swift_version":{"value":null,"path":null,"label":null,"label_basis":null},"package_swift_tools":null,"tuist_package_swift_tools":null,"swift_version_file":null}}
JSON
cat > tests/golden/version-evidence/synthetic/no-pin.expected.json <<'JSON'
{"schema":"ios-tuist-version-evidence/1","tool_version":{"sources":[],"effective":null,"conflicts":[]},"xcode":{"compatible_xcode_versions":null,"xcode_version_file":null},"swift":{"swift_version":{"value":null,"path":null,"label":null,"label_basis":null},"package_swift_tools":null,"tuist_package_swift_tools":null,"swift_version_file":null}}
JSON
cat > tests/golden/version-evidence/synthetic/mise-vs-tool-versions.expected.json <<'JSON'
{"schema":"ios-tuist-version-evidence/1","tool_version":{"sources":[{"source":"mise","path":"mise.toml","value":"4.206.0","conditional":false},{"source":".tool-versions","path":".tool-versions","value":"4.62.0","conditional":false}],"effective":{"value":"4.206.0","source":"mise"},"conflicts":[{"source":".tool-versions","path":".tool-versions","value":"4.62.0","vs":"mise"}]},"xcode":{"compatible_xcode_versions":null,"xcode_version_file":null},"swift":{"swift_version":{"value":null,"path":null,"label":null,"label_basis":null},"package_swift_tools":null,"tuist_package_swift_tools":null,"swift_version_file":null}}
JSON
cat > tests/golden/version-evidence/synthetic/tuist-version-only.expected.json <<'JSON'
{"schema":"ios-tuist-version-evidence/1","tool_version":{"sources":[{"source":".tuist-version","path":".tuist-version","value":"3.42.2","conditional":true}],"effective":{"value":"3.42.2","source":".tuist-version"},"conflicts":[]},"xcode":{"compatible_xcode_versions":null,"xcode_version_file":null},"swift":{"swift_version":{"value":null,"path":null,"label":null,"label_basis":null},"package_swift_tools":null,"tuist_package_swift_tools":null,"swift_version_file":null}}
JSON
cat > tests/golden/version-evidence/synthetic/tuist-version-conflict.expected.json <<'JSON'
{"schema":"ios-tuist-version-evidence/1","tool_version":{"sources":[{"source":".tool-versions","path":".tool-versions","value":"4.206.0","conditional":false},{"source":".tuist-version","path":".tuist-version","value":"3.42.2","conditional":true}],"effective":{"value":"4.206.0","source":".tool-versions"},"conflicts":[{"source":".tuist-version","path":".tuist-version","value":"3.42.2","vs":".tool-versions"}]},"xcode":{"compatible_xcode_versions":null,"xcode_version_file":null},"swift":{"swift_version":{"value":null,"path":null,"label":null,"label_basis":null},"package_swift_tools":null,"tuist_package_swift_tools":null,"swift_version_file":null}}
JSON
cat > tests/golden/version-evidence/synthetic/config-swift-3x.expected.json <<'JSON'
{"schema":"ios-tuist-version-evidence/1","tool_version":{"sources":[{"source":".tool-versions","path":".tool-versions","value":"3.42.2","conditional":false}],"effective":{"value":"3.42.2","source":".tool-versions"},"conflicts":[]},"xcode":{"compatible_xcode_versions":null,"xcode_version_file":null},"swift":{"swift_version":{"value":"5.5","path":"Tuist/Config.swift","label":"consumed","label_basis":"effective"},"package_swift_tools":null,"tuist_package_swift_tools":null,"swift_version_file":null}}
JSON
cat > tests/golden/version-evidence/synthetic/tuist-swift-4-206-0.expected.json <<'JSON'
{"schema":"ios-tuist-version-evidence/1","tool_version":{"sources":[{"source":".tool-versions","path":".tool-versions","value":"4.206.0","conditional":false}],"effective":{"value":"4.206.0","source":".tool-versions"},"conflicts":[]},"xcode":{"compatible_xcode_versions":".upToNextMajor(\"16.0\")","xcode_version_file":null},"swift":{"swift_version":{"value":"5.9","path":"Tuist.swift","label":"deprecated, ignored","label_basis":"effective"},"package_swift_tools":null,"tuist_package_swift_tools":null,"swift_version_file":null}}
JSON
cat > tests/golden/version-evidence/synthetic/tuist-swift-4-62-0.expected.json <<'JSON'
{"schema":"ios-tuist-version-evidence/1","tool_version":{"sources":[{"source":".tool-versions","path":".tool-versions","value":"4.62.0","conditional":false}],"effective":{"value":"4.62.0","source":".tool-versions"},"conflicts":[]},"xcode":{"compatible_xcode_versions":".upToNextMajor(\"16.0\")","xcode_version_file":null},"swift":{"swift_version":{"value":"5.9","path":"Tuist.swift","label":"stored only","label_basis":"effective"},"package_swift_tools":null,"tuist_package_swift_tools":null,"swift_version_file":null}}
JSON
cat > tests/golden/version-evidence/synthetic/swift-version-no-pin.expected.json <<'JSON'
{"schema":"ios-tuist-version-evidence/1","tool_version":{"sources":[],"effective":null,"conflicts":[]},"xcode":{"compatible_xcode_versions":".upToNextMajor(\"16.0\")","xcode_version_file":null},"swift":{"swift_version":{"value":"5.9","path":"Tuist.swift","label":"unknown","label_basis":"none"},"package_swift_tools":null,"tuist_package_swift_tools":null,"swift_version_file":null}}
JSON
```

What each synthetic case pins (Review Focus): `no-pin` → `effective: null` ("none detected"); `mise-vs-tool-versions` → mise wins, `.tool-versions` is a conflict; `tuist-version-only` → `.tuist-version` gives the effective version and is `conditional: true`; `tuist-version-conflict` → `.tool-versions` wins, differing `.tuist-version` is a conflict; `config-swift-3x` → `Tuist/Config.swift` is read, label `consumed`; `tuist-swift-4-206-0` → `deprecated, ignored`; `tuist-swift-4-62-0` → `stored only`; `swift-version-no-pin` → label `unknown`, basis `none` (no effective version, commands not run).

Consumer-edge cases (extract-candidate has targets `App` and `AppTests` only; the "after" state adds a `NetworkingKit` target and an `App -> NetworkingKit` edge; `with-usage` also imports it in `App/Sources/ExtractCandidateApp.swift` line 2):

```bash
mkdir -p tests/golden/consumer-edges/no-usage/after tests/golden/consumer-edges/with-usage/after/App/Sources
cat > tests/golden/consumer-edges/no-usage/after/Project.swift <<'SWIFT'
import ProjectDescription

let project = Project(
    name: "App",
    targets: [
        .target(
            name: "App",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.ios-tuist-skills.extract-candidate",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: ["UILaunchScreen": [:]]),
            buildableFolders: ["App/Sources"],
            dependencies: [.target(name: "NetworkingKit")]
        ),
        .target(
            name: "NetworkingKit",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.extract-candidate.networkingkit",
            deploymentTargets: .iOS("17.0"),
            buildableFolders: ["NetworkingKit/Sources"],
            dependencies: []
        ),
        .target(
            name: "AppTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.extract-candidate-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["App/Tests"],
            dependencies: [.target(name: "App")]
        ),
    ]
)
SWIFT
cp tests/golden/consumer-edges/no-usage/after/Project.swift tests/golden/consumer-edges/with-usage/after/Project.swift
cat > tests/golden/consumer-edges/with-usage/after/App/Sources/ExtractCandidateApp.swift <<'SWIFT'
import SwiftUI
import NetworkingKit

@main
struct ExtractCandidateApp: App {
    var body: some Scene {
        WindowGroup {
            SettingsRow(title: "Notifications", isOn: true)
        }
    }
}
SWIFT
cat > tests/golden/consumer-edges/no-usage/expected.json <<'JSON'
{"schema":"ios-tuist-consumer-edges/1","added":[{"from":"App","to":"NetworkingKit","usage":null}],"removed":[],"note":"no usage found != dependency unnecessary (static search; @_exported, macros, resources not detected)"}
JSON
cat > tests/golden/consumer-edges/with-usage/expected.json <<'JSON'
{"schema":"ios-tuist-consumer-edges/1","added":[{"from":"App","to":"NetworkingKit","usage":"App/Sources/ExtractCandidateApp.swift:2"}],"removed":[],"note":"no usage found != dependency unnecessary (static search; @_exported, macros, resources not detected)"}
JSON
```

These `Project.swift` copies live under `tests/golden/`, not `tests/fixtures/`: `scripts/ci-select-fixtures.sh` selects no fixture for them (rule `\Atests/fixtures/([^/]+)/`), and they are never generated.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `./scripts/run-golden-tests.sh; echo "exit=$?"`
Expected: every case in the version-evidence and consumer-edge suites prints `FAIL - …` (the scripts don't exist yet: "No such file or directory"); the read-only suite passes vacuously (nothing ran, nothing changed); last line `2 golden suite(s) failed`, `exit=2`.

- [ ] **Step 3: Implement `scripts/skill/collect-version-evidence.sh`**

```bash
#!/bin/bash
# Collects the version-safety evidence of references/version-safety.md (v0.8.1).
# It reports, it never judges or edits: conflicts are listed, not resolved, and
# nothing under PROJECT_ROOT is written. The calling skill makes the decisions.
set -euo pipefail

usage() {
  echo "Usage: $0 [--json] [--no-commands] [PROJECT_ROOT]" >&2
  exit 2
}

json=0
commands=1
root=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --json) json=1 ;;
    --no-commands) commands=0 ;;
    -*) usage ;;
    *) [ -z "$root" ] || usage; root="$1" ;;
  esac
  shift
done
root="${root:-$PWD}"
[ -d "$root" ] || { echo "Not a directory: $root" >&2; exit 2; }
root="$(cd "$root" && pwd -P)"

# Ruby reads its program from stdin (the heredoc); commands get empty stdin.
# Syntax stays Ruby 2.6-compatible: macOS /usr/bin/ruby is 2.6.
exec ruby -rjson -ropen3 - "$root" "$json" "$commands" <<'RUBY'
root = ARGV[0]
json_mode = ARGV[1] == "1"
run_commands = ARGV[2] == "1"

def read_text(path)
  return nil unless File.file?(path)
  File.binread(path).force_encoding("UTF-8").scrub
end

def rel(root, path)
  path.sub(/\A#{Regexp.escape(root)}\//, "")
end

# Whole-line `//` comments only: `//` inside strings (e.g. URLs) must survive.
def code_lines(text)
  text.lines.reject { |l| l.strip.start_with?("//") }.join
end

def mise_tuist(text)
  in_tools = false
  text.each_line do |line|
    stripped = line.sub(/\s#.*/, "").sub(/\A#.*/, "").strip
    if stripped =~ /\A\[([^\]]+)\]\z/
      in_tools = ($1.strip == "tools")
      next
    end
    next unless in_tools
    m = stripped.match(/\A["']?(?:tuist|aqua:tuist\/tuist|asdf:tuist)["']?\s*=\s*(.+)\z/)
    next unless m
    value = m[1]
    return $1 if value =~ /\A["']([^"']+)["']/
    return $1 if value =~ /\A\[\s*["']([^"']+)["']/
    return $1 if value =~ /version\s*=\s*["']([^"']+)["']/
  end
  nil
end

PIN_RES = [
  /\btuist(?:\s*[@=:]\s*|\s+)v?(\d+\.\d+\.\d+)\b/i,
  /TUIST_VERSION["']?\s*[:=]\s*["']?v?(\d+\.\d+\.\d+)/i,
]

def pinned_values(text)
  values = []
  text.each_line { |line| PIN_RES.each { |re| line.scan(re) { |m| values << m[0] } } }
  values.uniq
end

sources = []
add = lambda do |source, path, value|
  sources << { "source" => source, "path" => path, "value" => value, "conditional" => source == ".tuist-version" }
end

# 1. mise. The order among mise's own config paths is not verified against the
# mise docs; files are read in this fixed order and differences become conflicts.
mise_files = %w[mise.local.toml .mise.local.toml mise.toml .mise.toml mise/config.toml .mise/config.toml .config/mise.toml .config/mise/config.toml]
mise_paths = mise_files.select { |p| File.file?(File.join(root, p)) }
mise_paths += Dir.glob(File.join(root, "{mise,.mise,.config/mise}/conf.d/*.toml")).sort.map { |p| rel(root, p) }
mise_paths.each do |p|
  value = mise_tuist(read_text(File.join(root, p)))
  add.call("mise", p, value) if value
end

# 2. .tool-versions
if (text = read_text(File.join(root, ".tool-versions")))
  text.each_line do |line|
    fields = line.sub(/#.*/, "").split
    if fields[0] == "tuist" && fields[1]
      add.call(".tool-versions", ".tool-versions", fields[1])
      break
    end
  end
end

# 3. .tuist-version (conditional: tuistenv <= 3.x, or mise idiomatic files)
if (text = read_text(File.join(root, ".tuist-version"))) && !text.strip.empty?
  add.call(".tuist-version", ".tuist-version", text.strip)
end

# 4. CI workflows
Dir.glob(File.join(root, ".github/workflows/*.{yml,yaml}")).sort.each do |p|
  pinned_values(read_text(p)).each { |v| add.call("ci-workflow", rel(root, p), v) }
end

# 5. Repository scripts
script_paths = Dir.glob(File.join(root, "{Scripts,scripts}/**/*"))
script_paths += %w[Makefile Brewfile].map { |n| File.join(root, n) }
script_paths += Dir.glob(File.join(root, "bootstrap*"))
script_paths.select { |p| File.file?(p) && File.size(p) < 1_000_000 }.uniq.sort.each do |p|
  text = read_text(p)
  next if text.include?("\0")
  pinned_values(text).each { |v| add.call("script", rel(root, p), v) }
end

effective = sources.first && { "value" => sources.first["value"], "source" => sources.first["source"] }
conflicts = []
if effective
  sources.drop(1).each do |s|
    next if s["value"] == effective["value"]
    conflicts << { "source" => s["source"], "path" => s["path"], "value" => s["value"], "vs" => effective["source"] }
  end
end

# Live commands (skipped with --no-commands; golden tests exclude them).
commands = []
run = lambda do |argv|
  begin
    out, status = Open3.capture2e(*argv, chdir: root, stdin_data: "")
    commands << { "cmd" => argv.join(" "), "cwd" => root, "output" => out.lines.first.to_s.strip, "exit" => status.exitstatus }
  rescue Errno::ENOENT
    commands << { "cmd" => argv.join(" "), "cwd" => root, "output" => "not found", "exit" => 127 }
  end
end
tuist_version_file = File.file?(File.join(root, ".tuist-version"))
if run_commands
  run.call(%w[tuist version])
  run.call(%w[mise exec -- tuist version]) unless mise_paths.empty?
  run.call(%w[mise settings get idiomatic_version_file_enable_tools]) if tuist_version_file
  run.call(%w[xcodebuild -version])
  run.call(%w[swift --version])
end
find_cmd = lambda { |name| commands.find { |c| c["cmd"] == name } }
active_tuist = (c = find_cmd.call("tuist version")) && c["exit"] == 0 ? c["output"][/\d+\.\d+\.\d+/] : nil

# Xcode axis
manifests = [["Tuist.swift", read_text(File.join(root, "Tuist.swift"))],
             ["Tuist/Config.swift", read_text(File.join(root, "Tuist/Config.swift"))]].select { |_, t| t }
compat = nil
manifests.each do |_, text|
  m = code_lines(text).match(/compatibleXcodeVersions:\s*(.+?),?[ \t]*$/)
  compat ||= m[1].strip if m
end
xcode_file = (t = read_text(File.join(root, ".xcode-version"))) && !t.strip.empty? ? t.strip : nil

# Swift axis
SWIFT_RE = /swiftVersion:\s*(?:"(\d+(?:\.\d+)*)"|Version\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)|\.init\(\s*"(\d+(?:\.\d+)*)"\s*\))/
swift_value = nil
swift_path = nil
manifests.each do |path, text|
  m = code_lines(text).match(SWIFT_RE)
  next unless m && swift_value.nil?
  swift_value = m[1] || (m[2] && "#{m[2]}.#{m[3]}.#{m[4]}") || m[5]
  swift_path = path
end

def swift_version_label(tuist)
  return "unknown" unless tuist =~ /\A\d+(\.\d+)*\z/
  v = Gem::Version.new(tuist)
  major = v.segments[0]
  return "consumed" if major == 2 || major == 3
  return "stored only" if major == 4 && v <= Gem::Version.new("4.184.0")
  return "deprecated, ignored" if major == 4
  "unknown"
end

label = nil
label_basis = nil
if swift_value
  if effective
    label_basis = "effective"
    label = swift_version_label(effective["value"])
  elsif active_tuist
    label_basis = "active"
    label = swift_version_label(active_tuist)
  else
    label_basis = "none"
    label = "unknown"
  end
end

def tools_version(text)
  text && text[/\A\s*\/\/\s*swift-tools-version:\s*(\d+(?:\.\d+)*)/, 1]
end
swift_file = (t = read_text(File.join(root, ".swift-version"))) && !t.strip.empty? ? t.strip : nil

result = {
  "schema" => "ios-tuist-version-evidence/1",
  "project_root" => root,
  "tool_version" => { "sources" => sources, "effective" => effective, "conflicts" => conflicts },
  "xcode" => { "compatible_xcode_versions" => compat, "xcode_version_file" => xcode_file },
  "swift" => {
    "swift_version" => { "value" => swift_value, "path" => swift_path, "label" => label, "label_basis" => label_basis },
    "package_swift_tools" => tools_version(read_text(File.join(root, "Package.swift"))),
    "tuist_package_swift_tools" => tools_version(read_text(File.join(root, "Tuist/Package.swift"))),
    "swift_version_file" => swift_file,
  },
  "commands" => commands,
}

if json_mode
  puts JSON.pretty_generate(result)
  exit 0
end

def cell(list)
  list.empty? ? "none" : list.map { |s| "#{s["value"]} (#{s["path"]})" }.join(", ")
end
def row(label, value, note = "")
  format("%-40s %-14s %s", label, value, note).rstrip
end
by = lambda { |name| sources.select { |s| s["source"] == name } }
primary = lambda { |name| effective && effective["source"] == name ? "PRIMARY" : "" }
cmd_cell = lambda do |name|
  c = find_cmd.call(name)
  next ["n/a", run_commands ? "(not run)" : "(--no-commands)"] unless c
  [c["exit"] == 0 ? c["output"] : "error (exit #{c["exit"]})", "cmd: #{c["cmd"]}  cwd: #{c["cwd"]}"]
end
idiomatic = if (c = find_cmd.call("mise settings get idiomatic_version_file_enable_tools")) && c["exit"] == 0
  c["output"].include?("tuist") ? "on" : "off"
else
  "n/a"
end

lines = []
lines << "Tool Version Evidence (Tuist CLI — decides the effective version)"
lines << "-----------------------------------------------------------------"
lines << row("mise.toml / .mise.toml", cell(by.call("mise")), primary.call("mise"))
lines << row(".tool-versions", cell(by.call(".tool-versions")), primary.call(".tool-versions"))
lines << row(".tuist-version", cell(by.call(".tuist-version")), "(conditional: tuistenv on Tuist <= 3.x; mise idiomatic #{idiomatic}) #{primary.call(".tuist-version")}")
lines << row("CI workflows", cell(by.call("ci-workflow")), primary.call("ci-workflow"))
lines << row("Scripts / Makefile", cell(by.call("script")), primary.call("script"))
lines << row("Active (plain)", *cmd_cell.call("tuist version"))
lines << row("Active (mise exec)", *cmd_cell.call("mise exec -- tuist version"))
lines << row("Effective project version:", effective ? "#{effective["value"]} (#{effective["source"]})" : "none detected")
lines << row("Conflicts:", conflicts.empty? ? "none" : conflicts.map { |c| "#{c["value"]} (#{c["path"]}) vs #{c["vs"]}" }.join("; "))
lines << ""
lines << "Xcode Evidence (compatibility risk only)"
lines << "----------------------------------------"
lines << row("compatibleXcodeVersions", compat || "none")
lines << row(".xcode-version", xcode_file || "none", "(Tuist does not consume; project intent)")
lines << row("Active", *cmd_cell.call("xcodebuild -version"))
lines << ""
lines << "Swift Evidence (compatibility risk only)"
lines << "----------------------------------------"
lines << row("Tuist.swift / Config.swift swiftVersion", swift_value ? "#{swift_value} (#{swift_path})" : "none",
             swift_value ? "#{label} (basis: #{label_basis})" : "")
lines << row("Package.swift swift-tools-version", result["swift"]["package_swift_tools"] || "none")
lines << row("Tuist/Package.swift swift-tools-version", result["swift"]["tuist_package_swift_tools"] || "none")
lines << row(".swift-version", swift_file || "none", "(Tuist does not consume; project intent)")
lines << row("Active", *cmd_cell.call("swift --version"))
lines << ""
lines << "Manifest Compatibility Evidence"
lines << "-------------------------------"
lines << row("Existing manifest syntax", "unknown", "(not inferred by this script; the skill records it)")
puts lines
RUBY
```

`chmod +x scripts/skill/collect-version-evidence.sh`

- [ ] **Step 4: Implement `scripts/skill/check-consumer-edges.sh`**

```bash
#!/bin/bash
# Lists target dependency edges added/removed between two manifest states and
# searches each added edge's consumer sources for an import of the dependency.
# Static evidence only: "no usage found" is reported, never acted on (WS1 rule:
# an edge is not removed because this script found no import).
set -euo pipefail

usage() {
  echo "Usage: $0 [--json] --before <dir|git-rev> [PROJECT_ROOT]" >&2
  exit 2
}

json=0
before=""
root=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --json) json=1 ;;
    --before) [ "$#" -ge 2 ] || usage; before="$2"; shift ;;
    -*) usage ;;
    *) [ -z "$root" ] || usage; root="$1" ;;
  esac
  shift
done
[ -n "$before" ] || usage
root="${root:-$PWD}"
[ -d "$root" ] || { echo "Not a directory: $root" >&2; exit 2; }
root="$(cd "$root" && pwd -P)"

exec ruby -rjson -ropen3 - "$root" "$before" "$json" <<'RUBY'
root, before, json_mode = ARGV[0], ARGV[1], ARGV[2] == "1"
NOTE = "no usage found != dependency unnecessary (static search; @_exported, macros, resources not detected)"
SKIP_DIRS = %w[.git .build Derived Tuist DerivedData]

def keep_manifest?(rel)
  File.basename(rel) == "Project.swift" && (rel.split("/")[0..-2] & SKIP_DIRS).empty?
end

def manifests_from_dir(dir)
  Dir.glob(File.join(dir, "**", "Project.swift")).sort.each_with_object({}) do |path, acc|
    rel = path.sub(/\A#{Regexp.escape(dir)}\//, "")
    acc[rel] = File.binread(path).force_encoding("UTF-8").scrub if keep_manifest?(rel)
  end
end

def manifests_from_rev(root, rev)
  list, status = Open3.capture2("git", "-C", root, "ls-tree", "-r", "--name-only", rev, "--", ".")
  unless status.success?
    warn "Not a directory or git revision: #{rev}"
    exit 2
  end
  list.lines.map(&:chomp).select { |rel| keep_manifest?(rel) }.sort.each_with_object({}) do |rel, acc|
    text, st = Open3.capture2("git", "-C", root, "show", "#{rev}:./#{rel}")
    acc[rel] = text.force_encoding("UTF-8").scrub if st.success?
  end
end

# Returns the text between the bracket at open_idx and its match; strings are skipped.
def balanced(text, open_idx)
  open = text[open_idx]
  close = open == "(" ? ")" : "]"
  depth = 0
  in_str = false
  i = open_idx
  while i < text.length
    c = text[i]
    if in_str
      in_str = false if c == '"' && text[i - 1] != "\\"
    elsif c == '"'
      in_str = true
    elsif c == open
      depth += 1
    elsif c == close
      depth -= 1
      return text[(open_idx + 1)...i] if depth.zero?
    end
    i += 1
  end
  nil
end

# A target definition is a `.target(`/`Target(` call that has `product:`; the
# same call without `product:` is a dependency reference and is skipped here.
def parse_targets(text)
  text = text.lines.reject { |l| l.strip.start_with?("//") }.join
  targets = []
  starts = []
  text.scan(/(?:\.target|\bTarget)\s*\(/) { starts << Regexp.last_match.end(0) - 1 }
  starts.each do |idx|
    body = balanced(text, idx)
    next unless body && body =~ /\bproduct:/
    name = body[/\bname:\s*"([^"]+)"/, 1]
    next unless name
    deps = []
    if (m = body.match(/\bdependencies:\s*\[/))
      dbody = balanced(body, m.end(0) - 1) || ""
      dbody.scan(/\.target\(\s*name:\s*"([^"]+)"/) { deps << $1 }
      dbody.scan(/\.project\(\s*target:\s*"([^"]+)"/) { deps << $1 }
    end
    dirs = []
    %w[buildableFolders sources].each do |key|
      if (m = body.match(/\b#{key}:\s*\[/))
        (balanced(body, m.end(0) - 1) || "").scan(/"([^"]+)"/) { dirs << $1 }
      elsif (m = body.match(/\b#{key}:\s*"([^"]+)"/))
        dirs << m[1]
      end
    end
    dirs = dirs.map { |d| d.split("*").first.to_s.chomp("/") }.reject(&:empty?)
    targets << { "name" => name, "deps" => deps.uniq, "dirs" => dirs.uniq }
  end
  targets
end

def edges(manifests)
  manifests.flat_map do |rel, text|
    parse_targets(text).flat_map { |t| t["deps"].map { |d| [rel, t["name"], d] } }
  end
end

def first_usage(root, manifest_rel, target, dep)
  project_dir = File.dirname(File.join(root, manifest_rel))
  dirs = target ? target["dirs"] : []
  if dirs.empty? && target
    dirs = [target["name"], "Targets/#{target["name"]}", "Sources/#{target["name"]}"]
  end
  re = /^\s*(?:@testable\s+|@_exported\s+|@_implementationOnly\s+)*import\s+(?:(?:class|struct|enum|protocol|func|var|let|typealias)\s+)?#{Regexp.escape(dep)}(?:\.|\s|$)/
  dirs.map { |d| File.join(project_dir, d) }.select { |d| File.directory?(d) }.each do |dir|
    Dir.glob(File.join(dir, "**", "*.swift")).sort.each do |file|
      File.foreach(file).with_index(1) do |line, n|
        return "#{file.sub(/\A#{Regexp.escape(root)}\//, "")}:#{n}" if line.scrub =~ re
      end
    end
  end
  nil
end

before_manifests = File.directory?(before) ? manifests_from_dir(File.expand_path(before)) : manifests_from_rev(root, before)
after_manifests = manifests_from_dir(root)
before_edges = edges(before_manifests)
after_edges = edges(after_manifests)

added = (after_edges - before_edges).map do |rel, from, to|
  target = parse_targets(after_manifests[rel]).find { |t| t["name"] == from }
  { "from" => from, "to" => to, "usage" => first_usage(root, rel, target, to) }
end
removed = (before_edges - after_edges).map { |_, from, to| { "from" => from, "to" => to } }

if json_mode
  puts JSON.pretty_generate("schema" => "ios-tuist-consumer-edges/1", "added" => added, "removed" => removed, "note" => NOTE)
else
  puts "Added edges (#{added.size}):"
  added.each { |e| puts "  #{e["from"]} -> #{e["to"]}: #{e["usage"] ? "usage found (#{e["usage"]})" : "no usage found"}" }
  puts "Removed edges (#{removed.size}):"
  removed.each { |e| puts "  #{e["from"]} -> #{e["to"]}" }
  puts "note: #{NOTE}"
end
RUBY
```

`chmod +x scripts/skill/check-consumer-edges.sh`

- [ ] **Step 5: Run the tests to verify they pass**

Run: `./scripts/run-golden-tests.sh; echo "exit=$?"`
Expected (order as printed):

```text
## tests/golden/test-version-evidence.sh
ok   - fixture legacy-tuist
ok   - fixture modular
ok   - fixture version-mismatch
ok   - fixture extract-candidate
ok   - fixture architecture-smells
ok   - fixture ci-gaps
ok   - fixture migrate-candidate
ok   - fixture restyle-candidate
ok   - fixture test-target-candidate
ok   - fixture scaffold-candidate
ok   - synthetic no-pin
ok   - synthetic mise-vs-tool-versions
ok   - synthetic tuist-version-only
ok   - synthetic tuist-version-conflict
ok   - synthetic config-swift-3x
ok   - synthetic tuist-swift-4-206-0
ok   - synthetic tuist-swift-4-62-0
ok   - synthetic swift-version-no-pin
ok   - human output says none detected
ok   - live commands recorded with cwd
all version-evidence tests passed
## tests/golden/test-consumer-edges.sh
ok   - consumer edges no-usage
ok   - consumer edges with-usage
ok   - --before HEAD on unchanged fixture
ok   - caveat line printed
ok   - unknown revision exits 2
all consumer-edge tests passed
## tests/golden/test-read-only.sh
ok   - scripts left tests/fixtures unchanged
all golden suites passed
exit=0
```

Then the Ruby 2.6 check (macOS system Ruby; skip and say so if `/usr/bin/ruby` is absent): `PATH=/usr/bin:/bin ./scripts/run-golden-tests.sh | tail -1` → `all golden suites passed`.

Then the negative check (proves the comparison bites; revert afterwards): `sed -i.bak 's/"4.62.0"/"4.63.0"/' tests/golden/version-evidence/version-mismatch.expected.json && ./tests/golden/test-version-evidence.sh 2>/dev/null | grep FAIL; mv tests/golden/version-evidence/version-mismatch.expected.json.bak tests/golden/version-evidence/version-mismatch.expected.json` → prints exactly `FAIL - fixture version-mismatch`.

Human-output smoke (paste into the PR): `./scripts/skill/collect-version-evidence.sh --no-commands tests/fixtures/ci-gaps` must show `.tool-versions … 4.206.0 (.tool-versions) PRIMARY`, `CI workflows … 4.206.0 (.github/workflows/ci.yml)`, `Effective project version: 4.206.0 (.tool-versions)`, `Conflicts: none`.

- [ ] **Step 6: Add the CI job**

In `.github/workflows/lint.yml`, append after the `check-pins` job (keep two-space indentation under `jobs:`):

```yaml
  golden-tests:
    name: golden tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - name: Golden tests for skill scripts
        run: ./scripts/run-golden-tests.sh
```

Verify: `ruby -ryaml -e 'puts YAML.load_file(".github/workflows/lint.yml")["jobs"].keys.join(",")'` → `ci-scripts,check-pins,golden-tests`. (On ubuntu `tuist`/`xcodebuild` are absent; the live-command test only checks that each command is recorded with its cwd, so exit 127 "not found" passes.)

- [ ] **Step 7: Commit** `[hand-off]` (Codex cannot run git)

```bash
git add scripts/skill scripts/run-golden-tests.sh tests/golden .github/workflows/lint.yml
git commit -m "feat(ws-a): deterministic version-evidence and consumer-edge scripts with golden tests"
```

- [ ] **Step 8: PR** `[hand-off]` — `feature/v0.9-ws-a` → `develop`. Body: the scripts' contracts (Interfaces above), Step 5 output pasted (both Ruby versions), the negative check output, the human-output smoke, the known limits list, and:
  - Unverified: GitHub Actions run of `golden tests` (check on the PR); behavior inside a real skill session (wired in Task 3); `mise` config-path precedence; `.tuist-version` in parent directories.
  - Note for the user: `golden tests` is not a required check; adding it to branch protection is the user's call.


---

### Task 3: WS-B — skill self-containment

Branch `feature/v0.9-ws-b` from `develop` **after Task 2 (WS-A) is merged** (the sync manifest copies `scripts/skill/*.sh`, which Task 2 creates). One PR, three commits (Step 13).

**Goal:** every `skills/<skill>/` folder works when installed alone: no link leaves the folder, no text says "same as <other skill>", shared root files are copied in by one script, CI fails on drift. Also wires the WS-A scripts into SKILL.md (moved here from PRD WS-A change 3, see contracts).

**Files:**
- Create: `scripts/sync-skill-resources.sh`, `scripts/skill-resources.manifest`, `scripts/check-skill-links.sh`
- Create: `references/output-contract.md`, `references/evidence-driven-debugging.md`
- Create: `tests/skills/test-sync-skill-resources.sh`, `tests/skills/test-standalone-copy.sh`, `tests/skills/test-self-containment.sh`
- Create (generated by the sync script, committed): `skills/*/references/*.md`, `skills/*/scripts/*.sh`, `skills/ios-tuist-bootstrap/templates/**`
- Delete: `skills/*/references/.gitkeep` (10 files; the sync script removes them)
- Modify: all 10 `skills/*/SKILL.md`; `references/testing.md:30`; `.github/workflows/lint.yml`

**Interfaces:**
- Consumes (Task 2): `scripts/skill/collect-version-evidence.sh`, `scripts/skill/check-consumer-edges.sh` exist, are executable, start with `#!/bin/bash`. CLI per contracts: `collect-version-evidence.sh [--json] [--no-commands] [PROJECT_ROOT]`, `check-consumer-edges.sh [--json] --before <dir-or-git-rev> [PROJECT_ROOT]`.
- Produces for Task 4 (WS-E): `references/output-contract.md` with heading `## Standard report sections`; WS-E appends a new `## ios-tuist-result block` section and adds manifest lines `<skill> references/output-contract.md` for the 7 skills that don't have it yet.
- Produces for Task 6 (WS-D): manifest line format `<skill> <source>`; `scripts/sync-skill-resources.sh` (no arguments, run from anywhere); `scripts/check-skill-links.sh [SKILLS_DIR]` which strips `#fragment` before resolving (anchor validity is Task 6's own test).
- Produces for everyone: the rule "root file is the original; `skills/*/{references,templates,scripts}/` are generated; edit the root file, then run `./scripts/sync-skill-resources.sh`".

**[검증 필요] result (research 2026-10-13):** Claude Code docs (code.claude.com/docs/en/skills): "`${CLAUDE_SKILL_DIR}` … expands to the directory containing your skill's `SKILL.md` file and resolves correctly regardless of where the skill is installed." Agent Skills spec (agentskills.io/specification): "use relative paths from the skill root … Keep file references one level deep"; paths escaping the skill folder are not documented. Codex 0.160.0 (`codex-rs/ext/skills/src/catalog_prompt.rs:29`): relative paths are resolved against the directory containing `SKILL.md`. So in-folder relative links + `${CLAUDE_SKILL_DIR}` are the supported forms. Whether `../../` actually breaks on a per-folder install is checked once in Step 12 ([hand-off]); the change proceeds either way (PRD).

#### Evidence to re-verify first (stop and report if any differs)

Run on the branch before editing:

```bash
grep -rhn '\.\./\.\./' skills/ | wc -l                     # 46
grep -rho '\.\./\.\./[a-z]*/[^) ]*' skills/ | sort | uniq -c | sort -rn
grep -rn '](\.\./ios-tuist-' skills/*/SKILL.md | wc -l     # 7 sibling-skill links
grep -rn 'Same structure as\|same procedure as\|Same Evidence-Driven' skills/ | wc -l   # 11
find skills -name .gitkeep | wc -l                          # 10
grep -n '](' references/*.md | grep -v http                 # 3 lines (below)
ls scripts/skill/                                           # collect-version-evidence.sh check-consumer-edges.sh
```

Expected per-skill `../../` targets on `a1dacba` (46 total):

| Skill | Count | Targets (line numbers) |
|---|---|---|
| ios-tuist-architecture-review | 3 | modularization (22, 60), version-safety (48) |
| ios-tuist-bootstrap | 11 | version-safety (16, 57, 63, 79), source-of-truth (71, 91, 94, 119), templates/minimal/ (98), templates/feature-modular/ (100), templates/clean/ (101) |
| ios-tuist-ci | 2 | version-safety (47, 60) |
| ios-tuist-dependency | 6 | dependencies (16, 68, 97), version-safety (50), source-of-truth (55), modularization (99) |
| ios-tuist-feature | 6 | version-safety (16, 47), source-of-truth (17, 49), testing (63), dependencies (87) |
| ios-tuist-migrate | 5 | version-safety (24, 49, 57, 63, 72) |
| ios-tuist-module | 7 | modularization (17, 64, 81), version-safety (52), source-of-truth (54), dependencies (120, 126) |
| ios-tuist-restyle | 2 | version-safety (65, 81) |
| ios-tuist-scaffold | 1 | version-safety (80) |
| ios-tuist-test-target | 3 | version-safety (68), testing (87, 112) |

Only `ios-tuist-bootstrap` uses `templates/`.

Other self-containment breaks found while reading (not in the PRD's evidence; fixed here because they fail the same standalone-copy test):
- 7 sibling-skill links `[`ios-tuist-x`](../ios-tuist-x/SKILL.md)`: restyle:50 (migrate), scaffold:52, 58 (feature), 61 (module), 69 (bootstrap), test-target:49 (feature), 53 (module).
- 9 Failure Handling sections say "same procedure as the other skills / as `ios-tuist-bootstrap` / as the v0.1 skills / as the other two skills" — the procedure text exists only in `ios-tuist-bootstrap` (lines 141-157).
- Root `references/` cross-links: `source-of-truth.md:63` and `testing.md:7` link `version-safety.md` (same dir — fine once both are synced into the skill); `testing.md:30` links `../templates/`, which does not exist in `ios-tuist-feature` / `ios-tuist-test-target` (the two skills that get `testing.md`).

Templates (`find templates -type f`): `Project.swift`, `Tuist.swift`, `README.md`, `TUIST_VERSION_USED_TO_AUTHOR.txt`, `App/Sources/*.swift`, `App/Tests/*.swift` (+ `ExampleFeature/` in feature-modular, `Domain/Data/Presentation` in clean). **Decision: templates are copied byte-for-byte with no GENERATED header.** They are project content that `ios-tuist-bootstrap` reproduces in a user's new project; a header comment would end up in the user's `Project.swift`/`README.md`. Provenance for templates is the manifest plus the CI drift check.

#### Steps

- [ ] **Step 1: Write the failing tests**

`tests/skills/test-self-containment.sh` (the PRD acceptance commands, plus the extra breaks above):

```bash
#!/bin/bash
# Acceptance checks for WS-B: each skill folder must be usable on its own.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"
failures=0
check() { # check <name> <command...>; passes when the command exits 0
  local name="$1"; shift
  if "$@" >/dev/null 2>&1; then echo "ok   - $name"; else echo "FAIL - $name"; failures=$((failures + 1)); fi
}
none() { ! grep -rn "$@"; }

check "no ../../ links in skills/" none '\.\./\.\./' skills/
check "no ../ markdown links in skills/" none '](\.\./' skills/
check "no 'Same structure as'" none 'Same structure as' skills/
check "no cross-skill debugging references" none -e 'same procedure as' -e 'Same Evidence-Driven' skills/
check "no .gitkeep left in skills/" test -z "$(find skills -name .gitkeep)"
check "all 10 SKILL.md run collect-version-evidence" test "$(grep -l 'collect-version-evidence.sh' skills/*/SKILL.md | wc -l | tr -d ' ')" = 10
check "module runs check-consumer-edges" grep -q 'check-consumer-edges.sh' skills/ios-tuist-module/SKILL.md
check "dependency runs check-consumer-edges" grep -q 'check-consumer-edges.sh' skills/ios-tuist-dependency/SKILL.md
check "every skill link resolves inside its skill" ./scripts/check-skill-links.sh

exit $((failures > 0))
```

`tests/skills/test-sync-skill-resources.sh`:

```bash
#!/bin/bash
# Unit tests for scripts/sync-skill-resources.sh, run on a scratch copy of the repo.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/sync-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
failures=0
pass() { echo "ok   - $1"; }
fail() { echo "FAIL - $1"; failures=$((failures + 1)); }

cp -R "$REPO_ROOT/references" "$REPO_ROOT/templates" "$REPO_ROOT/scripts" "$REPO_ROOT/skills" "$TMP/"
SYNC="$TMP/scripts/sync-skill-resources.sh"
MANIFEST="$TMP/scripts/skill-resources.manifest"

out="$("$SYNC" 2>&1)" && pass "first sync exits 0" || fail "first sync exits 0: $out"

missing=0
while read -r skill src; do
  case "$src" in
    references/*) dest="skills/$skill/$src" ;;
    templates/*) dest="skills/$skill/${src%/}" ;;
    scripts/skill/*) dest="skills/$skill/scripts/${src#scripts/skill/}" ;;
    *) dest="unsupported:$src" ;;
  esac
  [ -e "$TMP/$dest" ] || { echo "  missing $dest"; missing=1; }
done < <(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' "$MANIFEST")
[ "$missing" = 0 ] && pass "every manifest entry is synced" || fail "every manifest entry is synced"

head -1 "$TMP/skills/ios-tuist-ci/references/version-safety.md" | grep -q '^<!-- GENERATED by scripts/sync-skill-resources.sh from references/version-safety.md' \
  && pass "markdown copy starts with GENERATED comment" || fail "markdown copy starts with GENERATED comment"
tail -n +2 "$TMP/skills/ios-tuist-ci/references/version-safety.md" | cmp -s - "$TMP/references/version-safety.md" \
  && pass "markdown copy body is identical" || fail "markdown copy body is identical"

s="$TMP/skills/ios-tuist-ci/scripts/collect-version-evidence.sh"
{ head -1 "$s" | grep -q '^#!'; sed -n 2p "$s" | grep -q '^# GENERATED by scripts/sync-skill-resources.sh from scripts/skill/collect-version-evidence.sh'; } \
  && pass "script copy keeps shebang, GENERATED on line 2" || fail "script copy keeps shebang, GENERATED on line 2"
[ -x "$s" ] && pass "script copy is executable" || fail "script copy is executable"

cmp -s "$TMP/templates/minimal/Project.swift" "$TMP/skills/ios-tuist-bootstrap/templates/minimal/Project.swift" \
  && pass "template copied byte-for-byte" || fail "template copied byte-for-byte"
[ ! -e "$TMP/skills/ios-tuist-ci/templates" ] && pass "templates only where the manifest says" || fail "templates only where the manifest says"
[ -z "$(find "$TMP/skills" -name .gitkeep)" ] && pass ".gitkeep removed" || fail ".gitkeep removed"

out="$("$SYNC")"; [ "$(printf '%s\n' "$out" | tail -1)" = "sync: 0 change(s)" ] && pass "second sync is a no-op" || fail "second sync is a no-op: $out"

echo stray > "$TMP/skills/ios-tuist-ci/references/stray.md"
"$SYNC" >/dev/null; [ ! -e "$TMP/skills/ios-tuist-ci/references/stray.md" ] && pass "unlisted file is removed" || fail "unlisted file is removed"

echo "x" > "$TMP/templates/minimal/.DS_Store"
"$SYNC" >/dev/null; [ ! -e "$TMP/skills/ios-tuist-bootstrap/templates/minimal/.DS_Store" ] && pass ".DS_Store is never copied" || fail ".DS_Store is never copied"

cp "$MANIFEST" "$TMP/manifest.bak"
echo "ios-tuist-ci README.md" >> "$MANIFEST"
"$SYNC" >/dev/null 2>&1 && fail "unsupported source is rejected" || pass "unsupported source is rejected"
cp "$TMP/manifest.bak" "$MANIFEST"
echo "ios-tuist-nope references/testing.md" >> "$MANIFEST"
"$SYNC" >/dev/null 2>&1 && fail "unknown skill is rejected" || pass "unknown skill is rejected"

exit $((failures > 0))
```

`tests/skills/test-standalone-copy.sh`:

```bash
#!/bin/bash
# Each skill folder copied alone must still resolve every link (PRD WS-B acceptance).
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/standalone-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
failures=0

for skill in "$REPO_ROOT"/skills/*/; do
  name="$(basename "$skill")"
  mkdir -p "$TMP/$name/skills"
  cp -R "$skill" "$TMP/$name/skills/$name"
  if out="$("$REPO_ROOT/scripts/check-skill-links.sh" "$TMP/$name/skills")"; then
    echo "ok   - $name standalone"
  else
    echo "FAIL - $name standalone"; printf '%s\n' "$out" | sed 's/^/  /'; failures=$((failures + 1))
  fi
done

# The checker itself must catch the defects WS-B removes.
mkdir -p "$TMP/neg/skills/bad/references"
printf '%s\n' '---' 'name: bad' '---' '[x](../../references/version-safety.md)' '[y](references/nope.md)' \
  'Run `"${CLAUDE_SKILL_DIR}/scripts/nope.sh"`.' '```text' '[ignored](../in-a-fence.md)' '```' > "$TMP/neg/skills/bad/SKILL.md"
out="$("$REPO_ROOT/scripts/check-skill-links.sh" "$TMP/neg/skills")"; status=$?
if [ "$status" -ne 0 ] && grep -q 'uses \.\.' <<<"$out" && grep -q 'references/nope.md (missing)' <<<"$out" \
   && grep -q 'scripts/nope.sh (missing)' <<<"$out" && ! grep -q 'in-a-fence' <<<"$out"; then
  echo "ok   - checker rejects ../, missing files, missing \${CLAUDE_SKILL_DIR} paths; ignores fences"
else
  echo "FAIL - checker negative case"; printf '%s\n' "$out" | sed 's/^/  /'; failures=$((failures + 1))
fi

exit $((failures > 0))
```

`chmod +x tests/skills/*.sh`.

- [ ] **Step 2: Run them to verify they fail**

```bash
./tests/skills/test-self-containment.sh; echo "exit=$?"
./tests/skills/test-sync-skill-resources.sh; echo "exit=$?"
./tests/skills/test-standalone-copy.sh; echo "exit=$?"
```

Expected: `test-self-containment.sh` prints `FAIL` on every line (exit 1); the other two fail because `scripts/sync-skill-resources.sh` / `scripts/check-skill-links.sh` do not exist (`No such file or directory`, exit 1).

- [ ] **Step 3: Fix the one root reference link that cannot survive a sync**

`references/testing.md`, replace:

```markdown
*template* (see [`templates/`](../templates/)), whose purpose is to prove
```

with:

```markdown
*template* (the `templates/` bundled with `ios-tuist-bootstrap`), whose purpose is to prove
```

Meaning unchanged (it still points at the same templates); the link would resolve to nothing inside `ios-tuist-feature` / `ios-tuist-test-target`.

- [ ] **Step 4: Create the two shared references**

`references/evidence-driven-debugging.md` — the procedure moved verbatim from `skills/ios-tuist-bootstrap/SKILL.md:143-157`:

```markdown
# Evidence-Driven Debugging

The shared failure-handling procedure. Each skill's `## Failure Handling`
section links here and adds the first hypothesis specific to that skill.

1. **Observed facts** — record: Tuist version (project + active), Xcode
   version, Swift version, the exact failing command, the exact error
   text, the affected manifest file.
2. **Hypotheses** — when the cause isn't immediately obvious from the
   error, generate at least two plausible hypotheses (e.g. "H1: active
   Tuist version doesn't support this ProjectDescription API"; "H2: the
   deployment target is incompatible with a dependency's minimum OS
   version").
3. **Contradiction search** — try to disprove the leading hypothesis
   before changing code (e.g. check the Tuist changelog/docs for the
   active version before assuming an API is unsupported).
4. **Minimal change** — apply the smallest change that explains the
   observed failure. Do not make speculative unrelated changes.
```

`references/output-contract.md` (WS-E appends to this file later; keep the heading text exact):

````markdown
# Output Contract

Shared report structure. A skill's own `## Output Contract` section says
which structure it uses and adds its skill-specific fields and example.

## Standard report sections

Used by `ios-tuist-bootstrap`, `ios-tuist-feature` and
`ios-tuist-dependency`. Report, in this order:

```text
Version Context
Changes Made
Files Changed
Dependency Changes
Validation Performed
Build Result
Test Result
Unverified Items
Risks / Follow-up
```
````

The section list is copied from `skills/ios-tuist-bootstrap/SKILL.md:163-173`, which is identical to the inline lists in `ios-tuist-feature` (137-147) and `ios-tuist-dependency` (122-132). The inline lists stay in the three SKILL.md files (they are the contract the agent follows); the reference makes "the same structure" a link instead of a pointer to another skill.

- [ ] **Step 5: Replace cross-skill text in SKILL.md (exact before -> after)**

Each "before" must match exactly once; otherwise stop and report.

1. `skills/ios-tuist-bootstrap/SKILL.md` — Failure Handling (lines 143-157 move to the reference):

   before (the whole block from `Apply Evidence-Driven Debugging:` through `observed failure. Do not make speculative unrelated changes.`, i.e. lines 143-157)

   after:
   ```markdown
   Apply [Evidence-Driven Debugging](../../references/evidence-driven-debugging.md)
   (Observed Facts -> Hypotheses -> Contradiction Search -> Minimal Change).
   ```
   (Written with `../../` on purpose: Step 6 rewrites every `../../references/` link in one pass.)

2. `skills/ios-tuist-bootstrap/SKILL.md` Output Contract, before: `Report, in this order:` — after:
   ```markdown
   Report, in this order (the standard sections in
   [output-contract](../../references/output-contract.md)):
   ```

3. `skills/ios-tuist-feature/SKILL.md`, before:
   ```markdown
   Same Evidence-Driven Debugging procedure as `ios-tuist-bootstrap`
   (Observed Facts -> Hypotheses -> Contradiction Search -> Minimal Change).
   ```
   after:
   ```markdown
   Apply [Evidence-Driven Debugging](../../references/evidence-driven-debugging.md)
   (Observed Facts -> Hypotheses -> Contradiction Search -> Minimal Change).
   ```

4. `skills/ios-tuist-feature/SKILL.md`, before: `Same structure as \`ios-tuist-bootstrap\`:` — after:
   ```markdown
   Report, in this order (the standard sections in
   [output-contract](../../references/output-contract.md)):
   ```

5. `skills/ios-tuist-dependency/SKILL.md`, before: `Same Evidence-Driven Debugging procedure as the other two skills.` — after: `Apply [Evidence-Driven Debugging](../../references/evidence-driven-debugging.md).`

6. `skills/ios-tuist-dependency/SKILL.md`, before:
   ```markdown
   Same structure as the other two skills, with "Dependency Changes"
   populated with specifics:
   ```
   after:
   ```markdown
   Report, in this order (the standard sections in
   [output-contract](../../references/output-contract.md)), with
   "Dependency Changes" populated with specifics:
   ```

7. `ci`, `migrate`, `restyle`, `scaffold`, `test-target` — each has exactly one line starting `Evidence-Driven Debugging, same procedure as the other skills. First`. Replace the prefix `Evidence-Driven Debugging, same procedure as the other skills.` with `Apply [Evidence-Driven Debugging](../../references/evidence-driven-debugging.md).` (the rest of the line, ` First`, stays).

8. `skills/ios-tuist-module/SKILL.md`, before: `Evidence-Driven Debugging, same procedure as the v0.1 skills (Observed` — after: `Apply [Evidence-Driven Debugging](../../references/evidence-driven-debugging.md) (Observed`.

9. `skills/ios-tuist-architecture-review/SKILL.md`, before:
   ```markdown
   If `tuist graph` or manifest parsing fails, apply Evidence-Driven
   Debugging to that failure specifically (record the exact command and
   ```
   after:
   ```markdown
   If `tuist graph` or manifest parsing fails, apply
   [Evidence-Driven Debugging](../../references/evidence-driven-debugging.md)
   to that failure specifically (record the exact command and
   ```

10. Sibling-skill links (7) become plain names — the routing meaning ("use that skill instead") is unchanged, and the other mentions of sibling skills in the same files are already plain backticks:

```bash
ruby -i -pe 'gsub(%r{\[`(ios-tuist-[a-z-]+)`\]\(\.\./\1/SKILL\.md\)}, "`\\1`")' \
  skills/ios-tuist-restyle/SKILL.md skills/ios-tuist-scaffold/SKILL.md skills/ios-tuist-test-target/SKILL.md
grep -rn '](\.\./ios-tuist-' skills/ | wc -l   # 0
```

- [ ] **Step 6: Rewrite the root-relative links**

```bash
ruby -i -pe 'gsub("](../../references/", "](references/"); gsub("](../../templates/", "](templates/")' skills/*/SKILL.md
grep -rn '\.\./\.\./' skills/ | wc -l    # 0
```

Display text such as ``[`templates/minimal/`](templates/minimal/)`` keeps its label; only the target changes.

- [ ] **Step 7: Create the manifest**

`scripts/skill-resources.manifest` — derived from the links each SKILL.md has after Steps 5-6, plus the transitive links of the copied references (`source-of-truth.md` and `testing.md` link `version-safety.md`; every skill that has them already has `version-safety.md`). The `scripts/skill/` lines are the Step 9 wiring.

```text
# Shared files copied into each skill folder by scripts/sync-skill-resources.sh.
# Format: <skill> <source>. Sources: references/<file>.md, templates/<profile>/, scripts/skill/<file>.
# The root file is the original; never edit the copy under skills/.
ios-tuist-architecture-review references/evidence-driven-debugging.md
ios-tuist-architecture-review references/modularization.md
ios-tuist-architecture-review references/version-safety.md
ios-tuist-architecture-review scripts/skill/collect-version-evidence.sh

ios-tuist-bootstrap references/evidence-driven-debugging.md
ios-tuist-bootstrap references/output-contract.md
ios-tuist-bootstrap references/source-of-truth.md
ios-tuist-bootstrap references/version-safety.md
ios-tuist-bootstrap templates/clean/
ios-tuist-bootstrap templates/feature-modular/
ios-tuist-bootstrap templates/minimal/
ios-tuist-bootstrap scripts/skill/collect-version-evidence.sh

ios-tuist-ci references/evidence-driven-debugging.md
ios-tuist-ci references/version-safety.md
ios-tuist-ci scripts/skill/collect-version-evidence.sh

ios-tuist-dependency references/dependencies.md
ios-tuist-dependency references/evidence-driven-debugging.md
ios-tuist-dependency references/modularization.md
ios-tuist-dependency references/output-contract.md
ios-tuist-dependency references/source-of-truth.md
ios-tuist-dependency references/version-safety.md
ios-tuist-dependency scripts/skill/check-consumer-edges.sh
ios-tuist-dependency scripts/skill/collect-version-evidence.sh

ios-tuist-feature references/dependencies.md
ios-tuist-feature references/evidence-driven-debugging.md
ios-tuist-feature references/output-contract.md
ios-tuist-feature references/source-of-truth.md
ios-tuist-feature references/testing.md
ios-tuist-feature references/version-safety.md
ios-tuist-feature scripts/skill/collect-version-evidence.sh

ios-tuist-migrate references/evidence-driven-debugging.md
ios-tuist-migrate references/version-safety.md
ios-tuist-migrate scripts/skill/collect-version-evidence.sh

ios-tuist-module references/dependencies.md
ios-tuist-module references/evidence-driven-debugging.md
ios-tuist-module references/modularization.md
ios-tuist-module references/source-of-truth.md
ios-tuist-module references/version-safety.md
ios-tuist-module scripts/skill/check-consumer-edges.sh
ios-tuist-module scripts/skill/collect-version-evidence.sh

ios-tuist-restyle references/evidence-driven-debugging.md
ios-tuist-restyle references/version-safety.md
ios-tuist-restyle scripts/skill/collect-version-evidence.sh

ios-tuist-scaffold references/evidence-driven-debugging.md
ios-tuist-scaffold references/version-safety.md
ios-tuist-scaffold scripts/skill/collect-version-evidence.sh

ios-tuist-test-target references/evidence-driven-debugging.md
ios-tuist-test-target references/testing.md
ios-tuist-test-target references/version-safety.md
ios-tuist-test-target scripts/skill/collect-version-evidence.sh
```

Cross-check before moving on (every link target in each SKILL.md must be listed for that skill):

```bash
for f in skills/*/SKILL.md; do s=$(basename "$(dirname "$f")")
  grep -o '](references/[^)#]*\|](templates/[^)]*' "$f" | sed 's/^](//' | sort -u | while read -r t; do
    grep -qx "$s ${t}" scripts/skill-resources.manifest || echo "not in manifest: $s $t"; done; done
```

Expected: no output.

- [ ] **Step 8: Write the sync script and run it**

`scripts/sync-skill-resources.sh`:

```bash
#!/bin/bash
# Copies the shared root files listed in scripts/skill-resources.manifest into
# each skill folder, because a skill may be installed one folder at a time
# and must not link outside itself. The root files stay the only originals:
# copies get a GENERATED marker (except templates, which bootstrap reproduces
# verbatim in user projects), and files no longer listed are deleted so CI
# can detect drift with `git diff --exit-code`.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

ruby -rfileutils - scripts/skill-resources.manifest <<'RUBY'
manifest = ARGV[0]
MANAGED = %w[references templates scripts].freeze
JUNK = %w[.DS_Store].freeze

skills = Dir.glob("skills/*/SKILL.md").map { |p| File.basename(File.dirname(p)) }.sort
want = Hash.new { |h, k| h[k] = {} } # skill => { path inside skill => source path }

File.readlines(manifest, chomp: true).each.with_index(1) do |raw, n|
  line = raw.sub(/#.*/, "").strip
  next if line.empty?
  skill, src, extra = line.split(/\s+/)
  abort "#{manifest}:#{n}: expected '<skill> <source>'" if src.nil? || extra
  abort "#{manifest}:#{n}: unknown skill #{skill}" unless skills.include?(skill)
  abort "#{manifest}:#{n}: missing #{src}" unless File.exist?(src)
  files = File.directory?(src) ? Dir.glob("#{src.chomp('/')}/**/*", File::FNM_DOTMATCH).select { |f| File.file?(f) } : [src]
  files.reject { |f| JUNK.include?(File.basename(f)) }.each do |f|
    dest = case f
           when %r{\Areferences/[^/]+\.md\z}, %r{\Atemplates/[^/]+/} then f
           when %r{\Ascripts/skill/([^/]+)\z} then "scripts/#{Regexp.last_match(1)}"
           else abort "#{manifest}:#{n}: unsupported source #{f}"
           end
    want[skill][dest] = f
  end
end

def render(src)
  body = File.binread(src)
  note = "GENERATED by scripts/sync-skill-resources.sh from #{src}. Do not edit here; edit #{src} and re-run the script."
  return body if src.start_with?("templates/")
  if src.start_with?("scripts/skill/")
    first, rest = body.split("\n", 2)
    abort "#{src}: first line must be a shebang" unless first&.start_with?("#!")
    return "#{first}\n# #{note}\n#{rest}"
  end
  "<!-- #{note} -->\n#{body}"
end

changes = 0
skills.each do |skill|
  root = "skills/#{skill}"
  MANAGED.each do |dir|
    Dir.glob("#{root}/#{dir}/**/*", File::FNM_DOTMATCH).select { |f| File.file?(f) }.each do |f|
      next if want[skill].key?(f.delete_prefix("#{root}/"))
      File.delete(f)
      changes += 1
      puts "removed #{f}"
    end
  end
  want[skill].sort.each do |rel, src|
    dest = "#{root}/#{rel}"
    content = render(src)
    FileUtils.mkdir_p(File.dirname(dest))
    unless File.file?(dest) && File.binread(dest) == content
      File.binwrite(dest, content)
      changes += 1
      puts "wrote #{dest}"
    end
    mode = File.executable?(src) ? 0o755 : 0o644
    File.chmod(mode, dest) unless (File.stat(dest).mode & 0o777) == mode
  end
  MANAGED.each do |dir|
    Dir.glob("#{root}/#{dir}/**/").sort_by { |d| -d.length }.each { |d| Dir.rmdir(d) if Dir.empty?(d) }
  end
end
puts "sync: #{changes} change(s)"
RUBY
```

```bash
chmod +x scripts/sync-skill-resources.sh
./scripts/sync-skill-resources.sh | tail -1     # sync: <N> change(s), N > 0
./scripts/sync-skill-resources.sh | tail -1     # sync: 0 change(s)
find skills -name .gitkeep | wc -l              # 0
ls skills/ios-tuist-module/scripts              # check-consumer-edges.sh  collect-version-evidence.sh
```

- [ ] **Step 9: Write the link checker**

`scripts/check-skill-links.sh`:

```bash
#!/bin/bash
# Fails when a skill folder is not self-contained: every relative markdown
# link and every ${CLAUDE_SKILL_DIR}/... path in a skill's .md files must
# resolve inside that skill's own folder (skills can be installed one folder
# at a time; the Agent Skills spec only defines paths relative to the skill root).
# Usage: check-skill-links.sh [SKILLS_DIR]   (default: <repo>/skills)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="${1:-$REPO_ROOT/skills}"

ruby -rpathname - "$SKILLS_DIR" <<'RUBY'
skills_dir = Pathname(ARGV[0]).expand_path
abort "no such directory: #{skills_dir}" unless skills_dir.directory?
skill_dirs = skills_dir.children.select { |d| (d / "SKILL.md").file? }.sort
abort "no skills under #{skills_dir}" if skill_dirs.empty?
checked = 0
problems = []

skill_dirs.each do |skill|
  Dir.glob("**/*.md", base: skill.to_s).sort.each do |rel|
    file = skill / rel
    in_fence = false
    File.foreach(file).with_index(1) do |line, n|
      if line.lstrip.start_with?("```")
        in_fence = !in_fence
        next
      end
      next if in_fence
      line.scan(/\]\(([^)\s]+)\)/).flatten.each do |target|
        next if target.start_with?("#") || target.match?(/\A[a-z][a-z0-9+.-]*:/i)
        checked += 1
        path = target.sub(/#.*\z/, "")
        resolved = (file.dirname / path).expand_path
        problem =
          if path.start_with?("/") then "absolute path"
          elsif path.split("/").include?("..") then "uses .."
          elsif !resolved.to_s.start_with?("#{skill}/") then "outside the skill"
          elsif !resolved.exist? then "missing"
          end
        problems << "#{skill.basename}/#{rel}:#{n}: #{target} (#{problem})" if problem
      end
      line.scan(%r{\$\{CLAUDE_SKILL_DIR\}/([^\s`"')]+)}).flatten.each do |p|
        checked += 1
        problems << "#{skill.basename}/#{rel}:#{n}: ${CLAUDE_SKILL_DIR}/#{p} (missing)" unless (skill / p).exist?
      end
    end
  end
end

problems.each { |p| puts "FAIL #{p}" }
puts "checked #{checked} link(s) in #{skill_dirs.size} skill(s), #{problems.size} problem(s)"
exit(problems.empty? ? 0 : 1)
RUBY
```

Note: `${CLAUDE_SKILL_DIR}` paths are checked inside fences too (they are commands the agent runs); markdown links inside fences are examples and are skipped.

```bash
chmod +x scripts/check-skill-links.sh
./scripts/check-skill-links.sh | tail -1    # checked <N> link(s) in 10 skill(s), 0 problem(s)
```

- [ ] **Step 10: Wire the WS-A scripts into SKILL.md**

(a) Version evidence — all 10 skills. Insert one paragraph right after the **first paragraph** of each `## Version Safety` section (the paragraph that starts on the line after the heading's blank line). On `a1dacba` those paragraphs end with: architecture-review `finding, nothing more.`; bootstrap `not a blocker.`; ci `silently reconciles by picking one side.`; dependency `Xcode-native SwiftPM integration). Generate for the pinned version.`; feature `active one.`; migrate `required to know what actually needs to change between the two versions.`; module `manifest syntax for the pinned version, not the active one.`; restyle `Non-Trigger Conditions above).`; scaffold `accepts, per the repo-wide rule.`; test-target `syntax the pinned version actually accepts, per the repo-wide rule.`

```bash
ruby - skills/*/SKILL.md <<'RUBY'
BLOCK = <<~MD
  **Evidence script.** Collect the evidence with this skill's bundled
  script, run from the project root:
  `"${CLAUDE_SKILL_DIR}/scripts/collect-version-evidence.sh"` in Claude
  Code; other agents run `scripts/collect-version-evidence.sh` resolved
  against the directory that contains this SKILL.md. It only reads files
  and runs the version commands. Use its output as the Tool Version, Xcode
  and Swift evidence and add the Manifest compatibility axis yourself. If
  the script cannot run, follow the manual procedure in
  [version-safety](references/version-safety.md) and list "evidence script
  not used: <reason>" under Unverified Items.
MD
ARGV.each do |path|
  lines = File.readlines(path)
  h = lines.index { |l| l.chomp == "## Version Safety" } or abort "#{path}: no '## Version Safety'"
  start = (h + 1...lines.size).find { |i| !lines[i].strip.empty? }
  stop = (start...lines.size).find { |i| lines[i].strip.empty? } or abort "#{path}: paragraph never ends"
  abort "#{path}: already wired" if lines.join.include?("collect-version-evidence.sh")
  lines.insert(stop, "\n", *BLOCK.lines)
  File.write(path, lines.join)
  puts "#{path}: inserted after line #{stop} (#{lines[stop - 1].strip})"
end
RUBY
```

Expected: 10 lines, each naming the paragraph-ending text listed above. If any differs, `git checkout -- skills/` and stop.

(b) Edge check — `skills/ios-tuist-module/SKILL.md`. In Workflow step 5, before the bullet `   - Before changing files, run the pre-existing test schemes (at least`, insert:

```markdown
   - Record the pre-change state for the edge check in step 6: if the
     project is a git work tree whose `Project.swift` files have no
     uncommitted changes, note `git rev-parse HEAD`; otherwise copy every
     `Project.swift` (keeping relative paths) into a temporary directory.
```

After the line `   decision to remove the target or add tests to the user.` (end of step 6) insert:

```markdown
   Then run the bundled edge check from the project root —
   `"${CLAUDE_SKILL_DIR}/scripts/check-consumer-edges.sh" --before <rev-or-dir>`
   in Claude Code (other agents: `scripts/check-consumer-edges.sh`
   resolved against this SKILL.md's directory) — and put its per-edge
   result in Dependency Changes. Report a `no usage found` edge under
   Risks / Follow-up; never remove it automatically (the search is static
   and can miss `@_exported` imports, macros and resource-only use). If
   the script cannot run, rely on the usage-site search from step 5 and
   say so under Unverified Items.
```

(c) Edge check — `skills/ios-tuist-dependency/SKILL.md`. Append to Workflow step 4, after the line `   explicitly requires it.`:

```markdown
   Before step 5, record the pre-change state for step 9: `git rev-parse
   HEAD` when the `Project.swift` files have no uncommitted changes,
   otherwise a copy of every `Project.swift` in a temporary directory.
```

After the line `8. **Build** the affected target(s) and the app.` insert:

```markdown
9. **Edge check (local targets and projects only)** — if the change added
   a `.target(name:)` or `.project(target:path:)` dependency, run the
   bundled edge check from the project root:
   `"${CLAUDE_SKILL_DIR}/scripts/check-consumer-edges.sh" --before <rev-or-dir>`
   in Claude Code (other agents: `scripts/check-consumer-edges.sh`
   resolved against this SKILL.md's directory), with the state recorded
   in step 4. Put the result in Dependency Changes and report a
   `no usage found` edge under Risks / Follow-up instead of removing it.
   Package product dependencies are not covered by the script; verify
   their consumer with the `import` search from step 1, as before.
```

No Decision Rule changes: the module rule "edge only from targets with a verified usage site" and the dependency narrowest-target rule are unchanged; the script adds evidence and the manual procedure stays as the fallback (PRD WS-A change 3).

- [ ] **Step 11: Add the lint job**

Append to `.github/workflows/lint.yml` under `jobs:`:

```yaml
  skill-resources:
    name: skill resources
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - name: Sync is a no-op (copies match the root originals)
        run: |
          ./scripts/sync-skill-resources.sh
          git diff --exit-code -- skills
          test -z "$(git status --porcelain --untracked-files=all -- skills)"
      - name: Skill links stay inside each skill
        run: ./scripts/check-skill-links.sh
      - name: Self-containment tests
        run: |
          ./tests/skills/test-sync-skill-resources.sh
          ./tests/skills/test-standalone-copy.sh
          ./tests/skills/test-self-containment.sh
```

The job is not a required check; say so in the PR (the user decides whether to add `skill resources` to branch protection). No fixture job is affected: `skills/**` and `references/**` are not in `scripts/ci-select-fixtures.sh`'s `everything` list and that stays so.

- [ ] **Step 12: Run everything**

```bash
./tests/skills/test-self-containment.sh; echo "exit=$?"     # all ok, exit=0
./tests/skills/test-sync-skill-resources.sh; echo "exit=$?" # all ok, exit=0
./tests/skills/test-standalone-copy.sh; echo "exit=$?"      # 10 standalone ok + checker negative ok, exit=0
# PRD acceptance, verbatim:
grep -rn "\.\./\.\./" skills/                   # no output
grep -rn "Same structure as" skills/            # no output
./scripts/sync-skill-resources.sh && git diff --exit-code   # [hand-off] — needs git; Codex runs the sync twice and checks "sync: 0 change(s)" instead
./tests/ci/test-select-fixtures.sh              # unchanged, all ok
```

[hand-off] Install-path check (PRD [검증 필요], one path). Claude runs, after the files exist on the branch:

```bash
S="$(mktemp -d "${TMPDIR:-/tmp}/wsb-install.XXXXXX")"
cp -R tests/fixtures/architecture-smells "$S/proj"
mkdir -p "$S/proj/.claude/skills" && cp -R skills/ios-tuist-architecture-review "$S/proj/.claude/skills/"
cd "$S/proj" && claude -p "Review this Tuist project's target graph and dependency direction. Report findings only." \
  --setting-sources project --permission-mode plan --output-format stream-json --verbose --max-budget-usd 1.00 \
  < /dev/null > "$S/run.jsonl"
ruby -rjson -ne 'e = JSON.parse($_) rescue next; next unless e["type"] == "assistant"
  e["message"]["content"].each { |c| puts "#{c["name"]} #{c["input"].to_json[0, 160]}" if c["type"] == "tool_use" }' "$S/run.jsonl"
```

Record in the PR: whether a `Skill` tool_use names `ios-tuist-architecture-review` (project skill, no plugin prefix), whether `Read`/`Bash` calls reference `…/.claude/skills/ios-tuist-architecture-review/references/` and `…/scripts/collect-version-evidence.sh` (i.e. `${CLAUDE_SKILL_DIR}` expanded), and the cost line. Delete any new `~/.claude/plans/*.md` file the run created (list `~/.claude/plans` before and after). If the run shows the skill could not read its references, stop and report.

- [ ] **Step 13: Commit** ([hand-off] to Claude — three checkpoint commits)

SKILL.md edits from Steps 5, 6 and 10 touch the same files, so the commits are made at checkpoints instead of by splitting hunks. Codex stops after Step 5, after Step 9 and after Step 12 and prints the matching command; Claude runs it and Codex continues.

```bash
# after Step 5
git add references/testing.md references/evidence-driven-debugging.md references/output-contract.md skills/*/SKILL.md tests/skills
git commit -m "refactor(skills): replace cross-skill references with shared references (WS-B)"
# after Step 9
git add -A scripts/skill-resources.manifest scripts/sync-skill-resources.sh scripts/check-skill-links.sh skills
git commit -m "feat(skills): sync shared resources into each skill folder and check links (WS-B)"
# after Step 12
git add -A skills .github/workflows/lint.yml
git commit -m "feat(skills): run bundled version-evidence and consumer-edge scripts (WS-B)"
```

(The Step 1 tests are committed with checkpoint 1 even though they still fail there; CI on the PR only sees the final state.)

**PR body must include:** the per-skill link table above (before) and `check-skill-links.sh` output (after); the three test outputs; PRD acceptance command output; the install-path check result (Step 12); the decision that templates have no GENERATED header and why; the extra breaks fixed beyond the PRD (sibling links, Evidence-Driven Debugging, `testing.md:30`); that `skill resources` is not a required check.

**Unverified (list in PR):** Codex at runtime actually resolving `scripts/` relative to SKILL.md (source guidance only, not run); any install path other than the one checked in Step 12 (claude.ai upload, Codex `.agents/skills`); `${CLAUDE_SKILL_DIR}` behaviour with `--plugin-dir` vs marketplace install if only one was exercised.


---

### Task 4: WS-E — machine-readable Output Contract

**Branch:** `feature/v0.9-ws-e` from `develop` **after Task 3 (WS-B) is merged** (and Task 1, whose report lines the comparison reads).

**Goal:** Every skill ends its response with one `ios-tuist-result` YAML block; a parser turns it into JSON; the benchmark harness prints the skill's claims next to what it measured.

**Files:**
- Modify: `references/output-contract.md` (created by Task 3) — append section `## ios-tuist-result block`
- Modify: all 10 `skills/*/SKILL.md` — append `### Machine-readable result` at the end of the `## Output Contract` section (it is the last `## ` section in all 10 files, verified 2026-10-13)
- Regenerate: `skills/*/references/output-contract.md` via `scripts/sync-skill-resources.sh` (Task 3)
- Create: `scripts/parse-skill-result.sh`, `scripts/compare-skill-result.sh`
- Create: `tests/output-contract/test-parse-skill-result.sh`, `tests/output-contract/test-compare-skill-result.sh`, `tests/output-contract/samples/{valid.md,valid-module.md,missing.md,malformed.md,invalid-enum.md,two-blocks.md,report.md,edges.json,compare.expected.txt}`
- Modify: `scripts/run-golden-tests.sh` (Task 2) — add the two new suites
- Modify: `scripts/benchmark-isolated-run.sh` — optional `BENCH_TRANSCRIPT` parsing in `collect`

**Interfaces:**
- Consumes:
  - Task 3: `references/output-contract.md` exists; `scripts/sync-skill-resources.sh` copies every root `references/<file>` that a `SKILL.md` links as `references/<file>` into that skill's `references/`; `scripts/check-skill-links.sh` exits 0 when every relative link in `skills/*/SKILL.md` resolves inside the skill folder. **If Task 3 shipped different names or behavior, stop and report.**
  - Task 1: the collect report contains the lines `Changed files (excluding generated): <M>`, `Generate: <status>`, `Build: <status>`, `Tests executed: <N|unknown>`, `Test: <status>`.
  - Task 2: `scripts/skill/check-consumer-edges.sh --json --before HEAD <dir>`; `scripts/run-golden-tests.sh` loop list.
- Produces: `scripts/parse-skill-result.sh <response.md>` → JSON (`schema: ios-tuist-result/1` + the block's fields) on stdout; exit 2 `error: no ios-tuist-result block`, 3 YAML error, 4 schema violation (including more than one block), 64 usage. `scripts/compare-skill-result.sh <result.json> <report.md> [edges.json]` → 5 summary lines. Task 5 (WS-C) and later benchmark work use the parser.

**Evidence to re-verify before editing:**

```bash
for f in skills/*/SKILL.md; do n=$(grep -n '^## Output Contract' "$f" | cut -d: -f1); awk -v n="$n" 'NR>n && /^## /{print FILENAME": section after Output Contract: "$0; found=1} END{if(!found) print FILENAME": Output Contract is last"}' "$f"; done
# expect 10 lines ending "Output Contract is last"
test -f references/output-contract.md && echo present          # expect: present (Task 3)
grep -n 'Changed files (excluding generated)\|Tests executed' scripts/benchmark-isolated-run.sh   # expect matches (Task 1)
grep -n 'echo "Report: $REPORT"' scripts/benchmark-isolated-run.sh                                 # expect exactly one line
```

- [ ] **Step 1: Write the samples and failing tests**

````bash
mkdir -p tests/output-contract/samples
cat > tests/output-contract/samples/valid.md <<'MD'
Version Context
Tuist: 4.206.0 (project-pinned)

Findings
- FeatureA depends on CoreKit without importing it.

```ios-tuist-result
skill: ios-tuist-architecture-review
outcome: completed
version_evidence:
  effective: 4.206.0
  source: .tool-versions
  conflicts: []
  collected_by: script
files_changed: []
dependency_edges_added: []
dependency_edges_removed: []
validation: {generate: not-run, build: not-run, test: not-run}
unverified:
  - FeatureA -> CoreKit usage via @_exported import not checked
```
MD
cat > tests/output-contract/samples/valid-module.md <<'MD'
Extracted NetworkingKit.

```ios-tuist-result
skill: ios-tuist-module
outcome: completed
version_evidence: unavailable
files_changed: [Project.swift, NetworkingKit/Sources/Networking.swift]
dependency_edges_added:
  - {from: App, to: NetworkingKit, usage: "App/Sources/ExtractCandidateApp.swift:2"}
dependency_edges_removed: []
validation: {generate: pass, build: pass, test: pass}
unverified: []
```
MD
printf 'No block here.\n```text\nskill: ios-tuist-ci\n```\n' > tests/output-contract/samples/missing.md
cat > tests/output-contract/samples/malformed.md <<'MD'
```ios-tuist-result
skill: ios-tuist-ci
outcome: [completed
```
MD
cat > tests/output-contract/samples/invalid-enum.md <<'MD'
```ios-tuist-result
skill: ios-tuist-ci
outcome: done
version_evidence: unavailable
files_changed: []
dependency_edges_added: []
dependency_edges_removed: []
validation: {generate: not-run, build: not-run, test: skipped}
unverified: []
```
MD
{ cat tests/output-contract/samples/valid-module.md; echo; sed -n '/^```ios-tuist-result/,/^```$/p' tests/output-contract/samples/valid-module.md; } > tests/output-contract/samples/two-blocks.md
cat > tests/output-contract/samples/report.md <<'MD'
# extract-candidate — with-skill — run1

Changed files (raw): 9
Changed files (excluding generated): 3

Resolve: pass
Generate: pass
Build: pass
Tests executed: 0
Test: pass-empty
MD
cat > tests/output-contract/samples/edges.json <<'JSON'
{
  "schema": "ios-tuist-consumer-edges/1",
  "added": [
    {"from": "App", "to": "NetworkingKit", "usage": "App/Sources/ExtractCandidateApp.swift:2"},
    {"from": "AppTests", "to": "NetworkingKit", "usage": null}
  ],
  "removed": [],
  "note": "no usage found != dependency unnecessary (static search; @_exported, macros, resources not detected)"
}
JSON
cat > tests/output-contract/samples/compare.expected.txt <<'TXT'
Outcome: completed
Files changed: claimed 2; measured 3
Edges added: claimed 1; measured 2 (1 without usage found)
Validation: claimed generate=pass build=pass test=pass; harness Generate=pass Build=pass Test=pass-empty (tests executed: 0)
Unverified items: 0
TXT
````

`tests/output-contract/test-parse-skill-result.sh`:

```bash
#!/bin/bash
# Unit tests for scripts/parse-skill-result.sh.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
PARSE="$REPO_ROOT/scripts/parse-skill-result.sh"
SAMPLES="$REPO_ROOT/tests/output-contract/samples"
failures=0

# expect <name> <sample> <exit code> [ruby check on stdout JSON]
expect() {
  local name="$1" sample="$2" want="$3" check="${4:-}" out status
  out="$("$PARSE" "$SAMPLES/$sample" 2>/dev/null)"
  status=$?
  if [ "$status" -eq "$want" ] && { [ -z "$check" ] || printf '%s' "$out" | ruby -rjson -e "h = JSON.parse(STDIN.read); exit((${check}) ? 0 : 1)"; }; then
    echo "ok   - $name"
  else
    echo "FAIL - $name (exit $status, want $want)"
    failures=$((failures + 1))
  fi
}

expect "valid review block"          valid.md        0 'h["schema"] == "ios-tuist-result/1" && h["skill"] == "ios-tuist-architecture-review" && h["version_evidence"]["effective"] == "4.206.0"'
expect "valid module block"          valid-module.md 0 'h["dependency_edges_added"] == [{"from" => "App", "to" => "NetworkingKit", "usage" => "App/Sources/ExtractCandidateApp.swift:2"}] && h["validation"]["test"] == "pass"'
expect "missing block exits 2"       missing.md      2
expect "malformed YAML exits 3"      malformed.md    3
expect "bad enum values exit 4"      invalid-enum.md 4
expect "two blocks exit 4"           two-blocks.md   4

# pipefail would turn the expected exit 2 into a failed grep; capture first.
msg="$("$PARSE" "$SAMPLES/missing.md" 2>&1 >/dev/null)"
if [ "$msg" = "error: no ios-tuist-result block" ]; then
  echo "ok   - missing block message"
else
  echo "FAIL - missing block message"
  failures=$((failures + 1))
fi

[ "$failures" -eq 0 ] && echo "all parse-skill-result tests passed" || echo "$failures parse-skill-result test(s) failed"
exit "$failures"
```

`tests/output-contract/test-compare-skill-result.sh`:

```bash
#!/bin/bash
# Unit test for scripts/compare-skill-result.sh (claimed vs measured metrics).
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SAMPLES="$REPO_ROOT/tests/output-contract/samples"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/compare.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
failures=0

"$REPO_ROOT/scripts/parse-skill-result.sh" "$SAMPLES/valid-module.md" > "$TMP/result.json"
if "$REPO_ROOT/scripts/compare-skill-result.sh" "$TMP/result.json" "$SAMPLES/report.md" "$SAMPLES/edges.json" > "$TMP/out.txt" &&
  diff -u "$SAMPLES/compare.expected.txt" "$TMP/out.txt"; then
  echo "ok   - claimed vs measured summary"
else
  echo "FAIL - claimed vs measured summary"
  failures=$((failures + 1))
fi

if "$REPO_ROOT/scripts/compare-skill-result.sh" "$TMP/result.json" "$SAMPLES/report.md" | grep -qx 'Edges added: claimed 1; measured unavailable'; then
  echo "ok   - edges unavailable without edge JSON"
else
  echo "FAIL - edges unavailable without edge JSON"
  failures=$((failures + 1))
fi

[ "$failures" -eq 0 ] && echo "all compare-skill-result tests passed" || echo "$failures compare-skill-result test(s) failed"
exit "$failures"
```

`chmod +x tests/output-contract/*.sh`

In `scripts/run-golden-tests.sh` replace:

```bash
  tests/golden/test-read-only.sh; do
```

with:

```bash
  tests/golden/test-read-only.sh \
  tests/output-contract/test-parse-skill-result.sh \
  tests/output-contract/test-compare-skill-result.sh; do
```

- [ ] **Step 2: Run to verify failure**

Run: `./tests/output-contract/test-parse-skill-result.sh; echo "exit=$?"`
Expected: every line `FAIL - …` (parser missing), `exit=7`.

- [ ] **Step 3: Implement the parser and the comparison**

`scripts/parse-skill-result.sh`:

```bash
#!/bin/bash
# Extracts the single `ios-tuist-result` block (references/output-contract.md)
# from a skill's response and prints it as JSON. Exit codes: 0 ok, 2 no block,
# 3 YAML parse error, 4 schema violation (incl. more than one block).
set -euo pipefail

[ "$#" -eq 1 ] && [ -f "$1" ] || { echo "Usage: $0 <response.md>" >&2; exit 64; }

exec ruby -rjson -ryaml - "$1" <<'RUBY'
SKILLS = %w[ios-tuist-architecture-review ios-tuist-bootstrap ios-tuist-ci ios-tuist-dependency
            ios-tuist-feature ios-tuist-migrate ios-tuist-module ios-tuist-restyle
            ios-tuist-scaffold ios-tuist-test-target]
OUTCOMES = %w[completed refused blocked partial]
STEP = %w[pass fail not-run]

text = File.binread(ARGV[0]).force_encoding("UTF-8").scrub
blocks = text.scan(/^```ios-tuist-result[ \t]*\r?\n(.*?)^```[ \t]*\r?$/m).map(&:first)
if blocks.empty?
  warn "error: no ios-tuist-result block"
  exit 2
end
if blocks.size > 1
  warn "error: #{blocks.size} ios-tuist-result blocks (exactly one is required)"
  exit 4
end

begin
  data = YAML.safe_load(blocks.first)
rescue Psych::SyntaxError => e
  warn "error: ios-tuist-result is not valid YAML: #{e.message}"
  exit 3
end

errors = []
errors << "block must be a mapping" unless data.is_a?(Hash)
data = {} unless data.is_a?(Hash)
required = %w[skill outcome version_evidence files_changed dependency_edges_added
              dependency_edges_removed validation unverified]
(required - data.keys).each { |k| errors << "missing field: #{k}" }
(data.keys - required).each { |k| errors << "unknown field: #{k}" }
errors << "skill must be one of #{SKILLS.join(", ")}" if data.key?("skill") && !SKILLS.include?(data["skill"])
errors << "outcome must be one of #{OUTCOMES.join("|")}" if data.key?("outcome") && !OUTCOMES.include?(data["outcome"])

ve = data["version_evidence"]
if data.key?("version_evidence") && ve != "unavailable"
  if !ve.is_a?(Hash)
    errors << "version_evidence must be \"unavailable\" or a mapping"
  else
    (%w[effective source conflicts collected_by] - ve.keys).each { |k| errors << "version_evidence missing: #{k}" }
    errors << "version_evidence.conflicts must be a list" unless ve["conflicts"].is_a?(Array)
    errors << "version_evidence.collected_by must be script|manual" unless %w[script manual].include?(ve["collected_by"])
  end
end

%w[files_changed unverified].each do |k|
  next unless data.key?(k)
  errors << "#{k} must be a list of strings" unless data[k].is_a?(Array) && data[k].all? { |v| v.is_a?(String) }
end
{ "dependency_edges_added" => %w[from to usage], "dependency_edges_removed" => %w[from to] }.each do |k, keys|
  next unless data.key?(k)
  list = data[k]
  unless list.is_a?(Array) && list.all? { |e| e.is_a?(Hash) && (keys - e.keys).empty? }
    errors << "#{k} must be a list of {#{keys.join(", ")}}"
  end
end
if data.key?("validation")
  v = data["validation"]
  if v.is_a?(Hash) && %w[generate build test].all? { |k| STEP.include?(v[k]) } && v.keys.sort == %w[build generate test]
    # valid
  else
    errors << "validation must be {generate, build, test} each pass|fail|not-run"
  end
end

unless errors.empty?
  errors.each { |e| warn "error: #{e}" }
  exit 4
end
puts JSON.pretty_generate({ "schema" => "ios-tuist-result/1" }.merge(data))
RUBY
```

`scripts/compare-skill-result.sh`:

```bash
#!/bin/bash
# Prints deterministic metrics: what the skill claimed in ios-tuist-result
# (parsed JSON) next to what the harness measured (report lines + edge JSON).
set -euo pipefail

[ "$#" -ge 2 ] && [ "$#" -le 3 ] || { echo "Usage: $0 <result.json> <report.md> [edges.json]" >&2; exit 64; }

exec ruby -rjson - "$@" <<'RUBY'
result = JSON.parse(File.read(ARGV[0]))
report = File.read(ARGV[1])
edges = ARGV[2] && File.size?(ARGV[2]) ? JSON.parse(File.read(ARGV[2])) : nil
# Report labels are the ones benchmark-isolated-run.sh prints (Task 1 / WS-H).
measured = lambda { |label| report[/^#{Regexp.escape(label)}:[ \t]*(.+)$/, 1] || "unrecorded" }

puts "Outcome: #{result["outcome"]}"
puts "Files changed: claimed #{result["files_changed"].size}; measured #{measured.call("Changed files (excluding generated)")}"
claimed_edges = result["dependency_edges_added"].size
if edges
  no_usage = edges["added"].count { |e| e["usage"].nil? }
  puts "Edges added: claimed #{claimed_edges}; measured #{edges["added"].size} (#{no_usage} without usage found)"
else
  puts "Edges added: claimed #{claimed_edges}; measured unavailable"
end
v = result["validation"]
puts "Validation: claimed generate=#{v["generate"]} build=#{v["build"]} test=#{v["test"]}; " \
     "harness Generate=#{measured.call("Generate")} Build=#{measured.call("Build")} Test=#{measured.call("Test")} " \
     "(tests executed: #{measured.call("Tests executed")})"
puts "Unverified items: #{result["unverified"].size}"
RUBY
```

`chmod +x scripts/parse-skill-result.sh scripts/compare-skill-result.sh`

- [ ] **Step 4: Run to verify pass**

Run: `./tests/output-contract/test-parse-skill-result.sh && ./tests/output-contract/test-compare-skill-result.sh`
Expected:

```text
ok   - valid review block
ok   - valid module block
ok   - missing block exits 2
ok   - malformed YAML exits 3
ok   - bad enum values exit 4
ok   - two blocks exit 4
ok   - missing block message
all parse-skill-result tests passed
ok   - claimed vs measured summary
ok   - edges unavailable without edge JSON
all compare-skill-result tests passed
```

Also `PATH=/usr/bin:/bin ./tests/output-contract/test-parse-skill-result.sh | tail -1` → `all parse-skill-result tests passed` (Ruby 2.6), and `./scripts/run-golden-tests.sh | tail -1` → `all golden suites passed`.

- [ ] **Step 5: Field spec in `references/output-contract.md`**

Append to the end of `references/output-contract.md` (the file Task 3 created; do not edit its existing sections):

````markdown

## ios-tuist-result block

Every skill ends its response with exactly one fenced block whose info
string is `ios-tuist-result` and whose body is YAML. It restates facts
that are already in the human-readable sections, so that tools
(`scripts/parse-skill-result.sh`, the benchmark harness, the routing
evaluation) can read them without an LLM grader. It never replaces the
human-readable sections, and it never contains a claim those sections
do not support.

Shape (types, not a valid instance):

```text
skill: <skill name>
outcome: completed | refused | blocked | partial
version_evidence: unavailable | {effective, source, conflicts, collected_by}
files_changed: [<path>, ...]
dependency_edges_added: [{from, to, usage}, ...]
dependency_edges_removed: [{from, to}, ...]
validation: {generate: pass|fail|not-run, build: pass|fail|not-run, test: pass|fail|not-run}
unverified: [<item>, ...]
```

| Field | Rule |
|---|---|
| `skill` | The responding skill's folder name, e.g. `ios-tuist-module`. |
| `outcome` | `completed`: did what was asked. `refused`: a Decision Rule said no (e.g. the modularization checklist was not met). `blocked`: a precondition, permission or environment problem stopped the work. `partial`: some requested steps done, others not (list them in `unverified`). |
| `version_evidence` | `unavailable` when no Tuist Context was established. Otherwise a mapping: `effective` (the effective project version, or `null` for "none detected"), `source` (the Tool Version source that gave it, or `null`), `conflicts` (list of `"<path>: <value>"`, `[]` when none), `collected_by` (`script` when `scripts/collect-version-evidence.sh` output was used, `manual` when the prose procedure was followed). |
| `files_changed` | Paths, relative to the project root, that the skill created, modified or deleted. Exclude Tuist-generated artifacts (`*.xcodeproj`, `*.xcworkspace`, `Derived/`). `[]` for a read-only skill. |
| `dependency_edges_added` | One `{from, to, usage}` per target dependency the skill added. `usage` is the `file:line` reported by `scripts/check-consumer-edges.sh`, or `none-found`. |
| `dependency_edges_removed` | One `{from, to}` per removed target dependency. |
| `validation` | What actually ran: `pass`/`fail` only with the command's output shown above; otherwise `not-run`. |
| `unverified` | Every item the human-readable "Unverified" section lists, one string each; `[]` when none. |

Example:

```yaml
skill: ios-tuist-module
outcome: completed
version_evidence:
  effective: 4.206.0
  source: .tool-versions
  conflicts: []
  collected_by: script
files_changed: [Project.swift, NetworkingKit/Sources/Networking.swift]
dependency_edges_added:
  - {from: App, to: NetworkingKit, usage: "App/Sources/ExtractCandidateApp.swift:2"}
dependency_edges_removed: []
validation: {generate: pass, build: pass, test: pass}
unverified: []
```

(In a response the fence info string is `ios-tuist-result`, not `yaml`. The
example uses `yaml` so that this reference file is never parsed as a result.)
````

- [ ] **Step 6: Requirement in each SKILL.md**

Append the following to the end of each of the 10 `skills/<name>/SKILL.md` files, replacing `<name>` with the folder name (`ios-tuist-architecture-review`, `ios-tuist-bootstrap`, `ios-tuist-ci`, `ios-tuist-dependency`, `ios-tuist-feature`, `ios-tuist-migrate`, `ios-tuist-module`, `ios-tuist-restyle`, `ios-tuist-scaffold`, `ios-tuist-test-target`). Ensure exactly one blank line separates it from the previous last line:

```markdown
### Machine-readable result

After the sections above, end the response with exactly one
`ios-tuist-result` block as defined in
[references/output-contract.md](references/output-contract.md#ios-tuist-result-block),
with `skill: <name>`. The block repeats facts from the sections above for
tools; it never replaces them and never adds a claim they do not support.
```

Mechanical form (review the diff afterwards):

```bash
for d in skills/*/; do
  name="$(basename "$d")"
  printf '\n' >> "$d/SKILL.md"
  sed "s/<name>/$name/" <<'MD' >> "$d/SKILL.md"
### Machine-readable result

After the sections above, end the response with exactly one
`ios-tuist-result` block as defined in
[references/output-contract.md](references/output-contract.md#ios-tuist-result-block),
with `skill: <name>`. The block repeats facts from the sections above for
tools; it never replaces them and never adds a claim they do not support.
MD
done
```

Then refresh the synced copies and check links:

```bash
./scripts/sync-skill-resources.sh
./scripts/check-skill-links.sh; echo "links exit=$?"                       # expect links exit=0
grep -l '^### Machine-readable result$' skills/*/SKILL.md | wc -l          # expect 10
grep -c 'skill: ios-tuist-' skills/*/SKILL.md | grep -v ':1$'              # expect no output (one per file)
ls skills/*/references/output-contract.md | wc -l                          # expect 10
./scripts/sync-skill-resources.sh && git status --porcelain skills/         # run twice: second run must add no new change (drift-free)
```

Description and Decision Rules are untouched: `git diff develop -- skills | grep '^[-+]' | grep -v '^+++\|^---' | grep -v '^+'` → no output (only additions).

- [ ] **Step 7: Hook the parser into the benchmark harness**

In `scripts/benchmark-isolated-run.sh`, insert immediately **before** the line `echo "Report: $REPORT"`:

```bash
# WS-E: the skill's own ios-tuist-result claims next to what this harness measured.
if [ -n "${BENCH_TRANSCRIPT:-}" ]; then
  RESULT_JSON="$OUTPUT_DIR/$fixture-$condition-run$run.result.json"
  {
    echo
    echo "## Skill result (ios-tuist-result)"
    echo
    echo "Transcript: $BENCH_TRANSCRIPT"
    if "$REPO_ROOT/scripts/parse-skill-result.sh" "$BENCH_TRANSCRIPT" > "$RESULT_JSON" 2> "$RESULT_JSON.err"; then
      echo "Block: valid"
      "$REPO_ROOT/scripts/skill/check-consumer-edges.sh" --json --before HEAD "$WORKDIR" > "$RESULT_JSON.edges" 2> /dev/null ||
        : > "$RESULT_JSON.edges"
      "$REPO_ROOT/scripts/compare-skill-result.sh" "$RESULT_JSON" "$REPORT" "$RESULT_JSON.edges"
    else
      case "$?" in
        2) echo "Block: missing" ;;
        3) echo "Block: malformed (YAML)" ;;
        4) echo "Block: invalid (schema)" ;;
        *) echo "Block: not parsed" ;;
      esac
      sed 's/^/  /' "$RESULT_JSON.err"
      rm -f "$RESULT_JSON"
    fi
    rm -f "$RESULT_JSON.err" "$RESULT_JSON.edges"
  } >> "$REPORT"
else
  printf '\nSkill result: not collected (set BENCH_TRANSCRIPT to parse the ios-tuist-result block)\n' >> "$REPORT"
fi
```

And extend the `collect` usage line in `usage()` by replacing:

```bash
  echo "Run number: N or run-N (positive integer). collect requires BENCH_DIR=<date>-<name>." >&2
```

with:

```bash
  echo "Run number: N or run-N (positive integer). collect requires BENCH_DIR=<date>-<name>." >&2
  echo "Optional for collect: BENCH_TRANSCRIPT=<saved final response> parses its ios-tuist-result block." >&2
```

Verify syntax: `bash -n scripts/benchmark-isolated-run.sh && echo syntax-ok` → `syntax-ok`. (A full collect needs mise/tuist/xcodebuild → Step 8.)

- [ ] **Step 8: Real re-run** `[hand-off]` (Claude/user; needs claude, mise, tuist, xcodebuild; ~$1)

```bash
./scripts/benchmark-isolated-run.sh prep architecture-smells with-skill 1 --plugin-dir "$PWD"
# use the Workdir it prints:
(cd <Workdir> && claude -p "Review this Tuist project's target graph and dependency direction. Report findings only." \
  --setting-sources project --plugin-dir "$PWD" --permission-mode acceptEdits < /dev/null) > "${TMPDIR:-/tmp}/ws-e-transcript.md"
BENCH_DIR=2026-10-XX-ws-e-smoke BENCH_MODEL=<model id> BENCH_TRANSCRIPT="${TMPDIR:-/tmp}/ws-e-transcript.md" \
  ./scripts/benchmark-isolated-run.sh collect architecture-smells with-skill 1
```

Expected: the report `docs/superpowers/benchmarks/2026-10-XX-ws-e-smoke/raw/architecture-smells-with-skill-run1.md` ends with `## Skill result (ios-tuist-result)` and `Block: valid`, and `…-run1.result.json` exists. If the block is missing or invalid, record that as a finding in the PR (it is evidence about the skill instructions), do not loosen the parser.

- [ ] **Step 9: Commit** `[hand-off]`

```bash
git add references/output-contract.md skills scripts/parse-skill-result.sh scripts/compare-skill-result.sh \
  scripts/run-golden-tests.sh scripts/benchmark-isolated-run.sh tests/output-contract
git commit -m "feat(ws-e): machine-readable ios-tuist-result block, parser and harness comparison"
```

(Commit the Step 8 benchmark directory in the same PR as a separate commit: `docs(benchmarks): add WS-E smoke run`.)

- [ ] **Step 10: PR** `[hand-off]` — `feature/v0.9-ws-e` → `develop`. Body: Step 4 output, Step 6 check outputs, `bash -n` result, Step 8 report excerpt (or "Unverified" with reason). Mark as **output-format change** for the release notes (PRD §5). Unverified: Codex emitting the block (WS-F, deferred); skills other than architecture-review emitting a valid block (only one real run).

---

### Task 5: WS-C — routing evaluation set

**Why:** PRD WS-C. The repo measures how well a skill performs once chosen, but not whether the right skill is chosen. The [검증 필요] gate is resolved by experiment, not docs, on 2026-10-13 with claude 2.1.296; details are in the contracts file:
- A headless run emits skill use as a stream-json `assistant` content item: `{"type":"tool_use","name":"Skill","input":{"skill":"ios-tuist-skills:<name>"}}`.
- `system/init` lists `skills` and `plugins`, including the plugin `version`.
- A positive case may explore with Bash/Read first, so stopping at the first tool is wrong.
- Codex `exec --json` (0.160.0) has no skill event, so the codex condition is "unsupported" in this release.

**Branch:** `feature/v0.9-ws-c` from `develop`. It does not reuse `benchmark-isolated-run.sh` code. Its isolation rule is a copy of that script's `isolation_guard` (same conditions), so it can be developed in parallel with Task 1.

**Files:**
- Create: `tests/routing/cases.yaml` (45 cases, full content in Step 2)
- Create: `scripts/check-routing-cases.sh` (schema, references, category minimums)
- Create: `scripts/routing-observe.sh` (stream-json → one JSON line, stops reading at the stop event)
- Create: `scripts/run-routing-eval.sh` (`run` and `summarize` subcommands)
- Create: `tests/routing/test-check-routing-cases.sh`, `tests/routing/test-routing-observe.sh`, `tests/routing/test-routing-summarize.sh`
- Create: `tests/routing/fixtures/*.jsonl` (7 canned streams) and `tests/routing/fixtures/results-sample.jsonl`
- Modify: `.github/workflows/lint.yml` (add steps to `ci-scripts`)
- Modify: `.gitignore` (ignore routing raw streams)
- Modify: `README.md` (routing evaluation section and the description-change rule; the repo has no `CONTRIBUTING.md`)
- Create, by hand-off: `docs/superpowers/benchmarks/<YYYY-MM-DD>-routing/plugin-only/{meta.json,results.jsonl,results.json,summary.md,plans-created.txt}`

**Interfaces:**
- Consumes: `tests/fixtures/<name>/` directories, which must exist; `skills/<name>/SKILL.md` names.
- Produces:
  - `cases.yaml` schema: `version: 1`; `cases[]` with `id`, `prompt`, `fixture`, `expected_skill` (a `skills/` dir name or `none`), `category` (`positive|negative|adjacent|official-conflict|ambiguous`), `note`, and optional `forbidden_skills` (list of skill dir names).
  - Observer JSON, one line: `{"selected": "<skill-dir>|none|other:<name>", "stop_reason": "skill|write-tool|result|eof", "nested": bool, "tools_before_stop": [...], "write_path": str|null, "plugin_version": str|null, "claude_code_version": str|null, "model": str|null, "permission_mode": str|null, "cost_usd": num|null, "result_subtype": str|null}`.
  - `results.jsonl` rows are the observer JSON plus `id`, `category`, `fixture`, `expected_skill`, `forbidden_skills`, `elapsed_s`, `claude_exit`. WS-E may later add parsed `ios-tuist-result` data; it does not need these files.

**Evidence to re-verify**
```bash
ls skills          # exactly the 10 ios-tuist-* dirs
ls tests/fixtures  # the 12 dirs used in cases.yaml (architecture-smells ci-gaps existing-xcode extract-candidate legacy-tuist migrate-candidate modular new-project restyle-candidate scaffold-candidate test-target-candidate version-mismatch)
claude --version   # [hand-off] record; the event shapes were observed on 2.1.296
```
If `claude --version` is not 2.1.296 at baseline time, run the one-case smoke run in Step 12 first. Do not trust the canned shapes without that.

**Scoring rules.** `summarize` implements these exactly.
- A case is **correct** when `selected == expected_skill`.
- `forbidden_skills` violations (`selected ∈ forbidden_skills`) are listed separately, whatever the correctness.
- `ambiguous` cases must have `forbidden_skills`. Their main signal is "no violation".
- Per skill: `tp`/`fp`/`fn`, precision `tp/(tp+fp)`, recall `tp/(tp+fn)` (`n/a` on zero denominators). The confusion matrix has rows = expected and columns = selected, with `other:*` columns added when seen.
- `stop_reason: eof` counts as `none` but is listed as an anomaly.
- Pass thresholds are NOT set in this release (PRD open question 3: decided after the baseline).

- [ ] **Step 1: Write the failing schema test** `tests/routing/test-check-routing-cases.sh`, then `chmod +x` it.

```bash
#!/bin/bash
# Unit tests for scripts/check-routing-cases.sh: the real cases.yaml passes; broken copies fail.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHECK="$REPO_ROOT/scripts/check-routing-cases.sh"
CASES="$REPO_ROOT/tests/routing/cases.yaml"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
failures=0

# mutate <name> <ruby expression on `doc`> : writes $TMP/<name>.yaml
mutate() {
  ruby -ryaml -e 'doc = YAML.safe_load(File.read(ARGV[0])); eval(ARGV[1]); File.write(ARGV[2], doc.to_yaml)' \
    "$CASES" "$2" "$TMP/$1.yaml"
}
expect_pass() {
  if "$CHECK" "$2" > "$TMP/out" 2>&1; then echo "ok   - $1"; else echo "FAIL - $1: $(cat "$TMP/out")"; failures=$((failures + 1)); fi
}
expect_fail() {
  local name="$1" file="$2" pattern="$3"
  if "$CHECK" "$file" > "$TMP/out" 2>&1; then
    echo "FAIL - $name: expected failure, got pass"; failures=$((failures + 1))
  elif grep -q -- "$pattern" "$TMP/out"; then
    echo "ok   - $name"
  else
    echo "FAIL - $name: missing [$pattern] in: $(cat "$TMP/out")"; failures=$((failures + 1))
  fi
}

expect_pass "committed cases.yaml is valid" "$CASES"

mutate unknown-skill 'doc["cases"][0]["expected_skill"] = "ios-tuist-nonexistent"'
expect_fail "unknown expected_skill" "$TMP/unknown-skill.yaml" "unknown expected_skill"

mutate missing-fixture 'doc["cases"][0]["fixture"] = "no-such-fixture"'
expect_fail "missing fixture dir" "$TMP/missing-fixture.yaml" "unknown fixture"

mutate dup-id 'doc["cases"][1]["id"] = doc["cases"][0]["id"]'
expect_fail "duplicate id" "$TMP/dup-id.yaml" "duplicate id"

mutate few-negatives 'doc["cases"].reject! { |c| c["category"] == "negative" }'
expect_fail "negative minimum" "$TMP/few-negatives.yaml" "negative: 0 < 8"

mutate ambiguous-no-forbidden 'doc["cases"].find { |c| c["category"] == "ambiguous" }.delete("forbidden_skills")'
expect_fail "ambiguous needs forbidden_skills" "$TMP/ambiguous-no-forbidden.yaml" "ambiguous case needs forbidden_skills"

mutate positive-gap 'doc["cases"].reject! { |c| c["category"] == "positive" && c["expected_skill"] == "ios-tuist-ci" }'
expect_fail "per-skill positive minimum" "$TMP/positive-gap.yaml" "positive ios-tuist-ci: 0 < 2"

mutate bad-key 'doc["cases"][0]["expected"] = "x"'
expect_fail "unknown key" "$TMP/bad-key.yaml" "unknown keys"

[ "$failures" -eq 0 ] && echo "all routing-case tests passed" || echo "$failures routing-case test(s) failed"
exit "$failures"
```

- [ ] **Step 2: Write `tests/routing/cases.yaml`.** Use exactly this content.

The fixture directories are copied **without** `EXPECTATIONS.md` and `.gitkeep` (Step 6). In the 2026-10-13 experiment the model read `EXPECTATIONS.md` from the fixture copy, which would leak the expected answer.

Counts:

| Category | Cases | Notes |
|---|---|---|
| positive | 20 | 2 per skill |
| negative | 8 | |
| adjacent | 7 | |
| official-conflict | 6 | |
| ambiguous | 4 | |
| **Total** | **45** | 20 Korean, 25 English |

```yaml
# Routing evaluation cases (PRD v0.9 WS-C). Schema: scripts/check-routing-cases.sh.
# expected_skill: a skills/ directory name or "none". forbidden_skills: selecting one is a violation.
version: 1
cases:
  # --- positive: 2 per skill --------------------------------------------------
  - id: pos-bootstrap-en
    prompt: "Set up a new iOS app called Habit with Tuist in this empty folder."
    fixture: new-project
    expected_skill: ios-tuist-bootstrap
    category: positive
    note: "Empty directory, explicit new Tuist project."
  - id: pos-bootstrap-ko
    prompt: "이 빈 폴더에 Tuist로 새 iOS 앱 프로젝트를 만들어줘. 앱 이름은 Diary야."
    fixture: new-project
    expected_skill: ios-tuist-bootstrap
    category: positive
    note: "Korean variant of a new-project request."
  - id: pos-feature-en
    prompt: "Add a settings screen to the ProfileFeature target."
    fixture: modular
    expected_skill: ios-tuist-feature
    category: positive
    note: "Feature work inside an existing target."
  - id: pos-feature-ko
    prompt: "ProfileFeature에 프로필 편집 화면 기능을 추가해줘."
    fixture: modular
    expected_skill: ios-tuist-feature
    category: positive
    note: "Korean feature addition in an existing module."
  - id: pos-dependency-en
    prompt: "Add the Kingfisher Swift package and use it only in ProfileFeature."
    fixture: modular
    expected_skill: ios-tuist-dependency
    category: positive
    note: "External package scoped to one target."
  - id: pos-dependency-ko
    prompt: "SharedUI 타겟에 SnapKit 패키지 의존성을 추가해줘."
    fixture: modular
    expected_skill: ios-tuist-dependency
    category: positive
    note: "Korean package addition to a named target."
  - id: pos-module-en
    prompt: "Extract the networking code into its own module called NetworkingKit."
    fixture: extract-candidate
    expected_skill: ios-tuist-module
    category: positive
    note: "Same prompt as the WS6 smoke run."
  - id: pos-module-ko
    prompt: "App 타겟 안의 네트워킹 코드를 별도 모듈로 분리해줘."
    fixture: extract-candidate
    expected_skill: ios-tuist-module
    category: positive
    note: "Korean extraction request."
  - id: pos-archreview-en
    prompt: "Review this Tuist project's target graph and dependency direction. Report findings only."
    fixture: architecture-smells
    expected_skill: ios-tuist-architecture-review
    category: positive
    note: "Prompt from the 2026-10-13 observation experiment (selected architecture-review)."
  - id: pos-archreview-ko
    prompt: "이 프로젝트 모듈 구조에 문제가 없는지 진단만 해줘. 코드는 고치지 말고."
    fixture: architecture-smells
    expected_skill: ios-tuist-architecture-review
    category: positive
    note: "Korean diagnosis-only request."
  - id: pos-ci-en
    prompt: "Our GitHub Actions workflow for this Tuist project is slow. Audit it and suggest improvements."
    fixture: ci-gaps
    expected_skill: ios-tuist-ci
    category: positive
    note: "Existing workflow audit."
  - id: pos-ci-ko
    prompt: "이 프로젝트의 CI 워크플로가 매번 전체를 다시 빌드해. 점검해줘."
    fixture: ci-gaps
    expected_skill: ios-tuist-ci
    category: positive
    note: "Korean CI audit."
  - id: pos-migrate-en
    prompt: "Migrate this project from Tuist 3.42.2 to Tuist 4.206.0."
    fixture: migrate-candidate
    expected_skill: ios-tuist-migrate
    category: positive
    note: "Explicit, version-specific migration request."
  - id: pos-migrate-ko
    prompt: "이 프로젝트의 Tuist 버전을 4.206.0으로 올려줘."
    fixture: migrate-candidate
    expected_skill: ios-tuist-migrate
    category: positive
    note: "Korean explicit target version."
  - id: pos-restyle-en
    prompt: "Convert the CleanFeature target from sources/resources globs to buildableFolders."
    fixture: restyle-candidate
    expected_skill: ios-tuist-restyle
    category: positive
    note: "Named target, explicit buildableFolders conversion."
  - id: pos-restyle-ko
    prompt: "CleanFeature 타겟을 buildableFolders 방식으로 바꿔줘."
    fixture: restyle-candidate
    expected_skill: ios-tuist-restyle
    category: positive
    note: "Korean restyle of a named target."
  - id: pos-testtarget-en
    prompt: "Create a unit test target for FeatureB."
    fixture: test-target-candidate
    expected_skill: ios-tuist-test-target
    category: positive
    note: "FeatureB has no test target."
  - id: pos-testtarget-ko
    prompt: "FeatureB 타겟용 유닛 테스트 타겟을 추가해줘."
    fixture: test-target-candidate
    expected_skill: ios-tuist-test-target
    category: positive
    note: "Korean test-target creation."
  - id: pos-scaffold-en
    prompt: "Write a tuist scaffold template that generates a <Name>Label.swift file like the existing feature template does."
    fixture: scaffold-candidate
    expected_skill: ios-tuist-scaffold
    category: positive
    note: "One template, shape taken from the committed one."
  - id: pos-scaffold-ko
    prompt: "새 기능 모듈용 tuist scaffold 템플릿을 하나 만들어줘. name 속성 하나만 받게."
    fixture: scaffold-candidate
    expected_skill: ios-tuist-scaffold
    category: positive
    note: "Korean single-template request."
  # --- negative: no skill of this plugin should be used -----------------------
  - id: neg-swift-some
    prompt: "What does the Swift keyword 'some' mean? Answer in one sentence."
    fixture: modular
    expected_skill: none
    category: negative
    note: "General Swift question (experiment: no tool, $0.10)."
  - id: neg-swiftui-state-ko
    prompt: "SwiftUI에서 @State와 @Binding 차이를 설명해줘."
    fixture: modular
    expected_skill: none
    category: negative
    note: "General SwiftUI question."
  - id: neg-write-test-case
    prompt: "Write a unit test for the request builder in Networking.swift."
    fixture: extract-candidate
    expected_skill: none
    category: negative
    note: "Adding test cases to an existing test target is out of test-target's scope."
  - id: neg-typo
    prompt: "Fix the typo in the title string in SettingsRow.swift."
    fixture: extract-candidate
    expected_skill: none
    category: negative
    note: "Plain source edit, no Tuist graph change."
  - id: neg-rename-ko
    prompt: "Networking.swift의 client 변수 이름을 apiClient로 바꿔줘."
    fixture: extract-candidate
    expected_skill: none
    category: negative
    note: "Korean plain rename."
  - id: neg-explain-tuist
    prompt: "Explain what Tuist is in two sentences."
    fixture: modular
    expected_skill: none
    category: negative
    note: "Informational question."
  - id: neg-commit-msg-ko
    prompt: "방금 바꾼 내용으로 Conventional Commits 형식의 커밋 메시지 초안을 써줘."
    fixture: modular
    expected_skill: none
    category: negative
    note: "Git chore."
  - id: neg-instruments
    prompt: "How do I profile memory leaks with Instruments?"
    fixture: modular
    expected_skill: none
    category: negative
    note: "Tooling question unrelated to Tuist manifests."
  # --- adjacent: confusable skill pairs --------------------------------------
  - id: adj-module-not-feature
    prompt: "Move the ProfileFeature view code into a new module called ProfileUI."
    fixture: modular
    expected_skill: ios-tuist-module
    category: adjacent
    forbidden_skills: [ios-tuist-feature]
    note: "Extraction into a new module, not feature work."
  - id: adj-feature-not-module
    prompt: "Add an avatar view to ProfileFeature. Keep the current module layout."
    fixture: modular
    expected_skill: ios-tuist-feature
    category: adjacent
    forbidden_skills: [ios-tuist-module]
    note: "Feature inside an existing module."
  - id: adj-dependency-not-module
    prompt: "ProfileFeature에서만 Alamofire를 쓰고 싶어. 의존성만 추가해줘."
    fixture: modular
    expected_skill: ios-tuist-dependency
    category: adjacent
    forbidden_skills: [ios-tuist-module, ios-tuist-feature]
    note: "Dependency wiring, no new module."
  - id: adj-restyle-not-migrate
    prompt: "Switch CleanFeature to buildableFolders. Do not change the Tuist version."
    fixture: restyle-candidate
    expected_skill: ios-tuist-restyle
    category: adjacent
    forbidden_skills: [ios-tuist-migrate]
    note: "Restyle without a version bump."
  - id: adj-migrate-not-restyle
    prompt: "Tuist 4.206.0으로 마이그레이션해줘. 폴더 통합 방식은 바꾸지 말고."
    fixture: migrate-candidate
    expected_skill: ios-tuist-migrate
    category: adjacent
    forbidden_skills: [ios-tuist-restyle]
    note: "Version migration without restyle."
  - id: adj-testtarget-ui
    prompt: "Add a UI test target for the App target."
    fixture: test-target-candidate
    expected_skill: ios-tuist-test-target
    category: adjacent
    forbidden_skills: [ios-tuist-feature, ios-tuist-module]
    note: "New test target, not a feature or module."
  - id: adj-review-not-change
    prompt: "FeatureA가 CoreKit에 의존하는 방향이 맞는지 봐줘. 아무것도 바꾸지 마."
    fixture: architecture-smells
    expected_skill: ios-tuist-architecture-review
    category: adjacent
    forbidden_skills: [ios-tuist-module, ios-tuist-dependency]
    note: "Read-only review, no edits."
  # --- official-conflict: tuist/agent-plugin territory (038e54c) -------------
  - id: off-migrate-xcode
    prompt: "Migrate this Xcode project to Tuist."
    fixture: existing-xcode
    expected_skill: none
    category: official-conflict
    forbidden_skills: [ios-tuist-migrate, ios-tuist-bootstrap]
    note: "Official 'migrate' skill; ios-tuist-migrate is version-to-version only."
  - id: off-migrate-xcode-ko
    prompt: "기존 Xcode 프로젝트를 Tuist generated workspace로 전환하고 싶어."
    fixture: existing-xcode
    expected_skill: none
    category: official-conflict
    forbidden_skills: [ios-tuist-migrate, ios-tuist-bootstrap]
    note: "Korean adoption request; official migrate."
  - id: off-generate-fails-ko
    prompt: "tuist generate가 실패해요. 원인을 찾아줘."
    fixture: modular
    expected_skill: none
    category: official-conflict
    forbidden_skills: [ios-tuist-migrate]
    note: "Official debug-generated-project."
  - id: off-cache-compare
    prompt: "Compare the last two tuist cache runs and explain the cache misses."
    fixture: modular
    expected_skill: none
    category: official-conflict
    forbidden_skills: [ios-tuist-ci]
    note: "Official compare-cache-runs."
  - id: off-flaky
    prompt: "Fix the flaky tests reported by Tuist test insights."
    fixture: test-target-candidate
    expected_skill: none
    category: official-conflict
    forbidden_skills: [ios-tuist-test-target]
    note: "Official fix-flaky-tests."
  - id: off-generate-and-test
    prompt: "Run tuist generate and then xcodebuild test for the App scheme."
    fixture: legacy-tuist
    expected_skill: none
    category: official-conflict
    forbidden_skills: [ios-tuist-migrate, ios-tuist-restyle]
    note: "Official generated-projects (day-to-day commands)."
  # --- ambiguous: vague modernization requests must not trigger migrate -------
  - id: amb-latest-ko
    prompt: "Tuist 최신으로 정리해줘."
    fixture: legacy-tuist
    expected_skill: none
    category: ambiguous
    forbidden_skills: [ios-tuist-migrate]
    note: "No explicit target version; migrate requires one."
  - id: amb-latest-tooling
    prompt: "Make this project use the latest tooling."
    fixture: version-mismatch
    expected_skill: none
    category: ambiguous
    forbidden_skills: [ios-tuist-migrate]
    note: "Vague upgrade wish."
  - id: amb-version-warning-ko
    prompt: "버전 경고가 뜨는데 알아서 맞춰줘."
    fixture: version-mismatch
    expected_skill: none
    category: ambiguous
    forbidden_skills: [ios-tuist-migrate]
    note: "Mismatch must be reported, not silently fixed."
  - id: amb-modernize
    prompt: "Modernize the manifests."
    fixture: legacy-tuist
    expected_skill: none
    category: ambiguous
    forbidden_skills: [ios-tuist-migrate, ios-tuist-restyle]
    note: "Restyle needs explicitly named targets; migrate needs a version."
```

- [ ] **Step 3: Run the schema test and confirm it fails**

Run: `./tests/routing/test-check-routing-cases.sh`
Expected: every line `FAIL - …` (`check-routing-cases.sh: No such file or directory`). Non-zero exit.

- [ ] **Step 4: Implement `scripts/check-routing-cases.sh`, then `chmod +x` it**

```bash
#!/bin/bash
# Validates tests/routing/cases.yaml (schema, fixture/skill references, PRD WS-C category minimums).
#   check-routing-cases.sh [cases.yaml]
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CASES="${1:-$REPO_ROOT/tests/routing/cases.yaml}"
[ -f "$CASES" ] || { echo "FAIL no such file: $CASES" >&2; exit 1; }

ruby -ryaml -e '
  cases_file, repo = ARGV
  errors = []
  doc = YAML.safe_load(File.read(cases_file))
  unless doc.is_a?(Hash) && doc["version"] == 1 && doc["cases"].is_a?(Array)
    puts "FAIL schema: top level must be {version: 1, cases: [...]}"
    exit 1
  end
  skills = Dir.children(File.join(repo, "skills")).select { |d| File.file?(File.join(repo, "skills", d, "SKILL.md")) }.sort
  fixtures = Dir.children(File.join(repo, "tests", "fixtures")).select { |d| File.directory?(File.join(repo, "tests", "fixtures", d)) }
  categories = %w[positive negative adjacent official-conflict ambiguous]
  allowed = %w[id prompt fixture expected_skill category note forbidden_skills]
  seen = {}
  cases = doc["cases"]
  cases.each_with_index do |c, i|
    unless c.is_a?(Hash)
      errors << "case ##{i + 1}: not a mapping"
      next
    end
    where = "case ##{i + 1} (#{c["id"]})"
    extra = c.keys - allowed
    errors << "#{where}: unknown keys #{extra.join(", ")}" unless extra.empty?
    %w[id prompt fixture expected_skill category note].each do |k|
      errors << "#{where}: missing #{k}" unless c[k].is_a?(String) && !c[k].strip.empty?
    end
    id = c["id"].to_s
    errors << "#{where}: id must be kebab-case" unless id.match?(/\A[a-z0-9]+(-[a-z0-9]+)*\z/)
    errors << "#{where}: duplicate id" if seen[id]
    seen[id] = true
    errors << "#{where}: unknown fixture #{c["fixture"]}" unless fixtures.include?(c["fixture"])
    errors << "#{where}: unknown expected_skill #{c["expected_skill"]}" unless (skills + ["none"]).include?(c["expected_skill"])
    errors << "#{where}: unknown category #{c["category"]}" unless categories.include?(c["category"])
    if c.key?("forbidden_skills")
      f = c["forbidden_skills"]
      if !f.is_a?(Array) || f.empty? || f.any? { |s| !skills.include?(s) }
        errors << "#{where}: forbidden_skills must be a non-empty list of skill dirs"
      elsif f.include?(c["expected_skill"])
        errors << "#{where}: forbidden_skills contains expected_skill"
      end
    end
    errors << "#{where}: ambiguous case needs forbidden_skills" if c["category"] == "ambiguous" && !c.key?("forbidden_skills")
  end
  valid = cases.select { |c| c.is_a?(Hash) }
  count = ->(cat) { valid.count { |c| c["category"] == cat } }
  { "negative" => 8, "adjacent" => 6, "official-conflict" => 5, "ambiguous" => 3 }.each do |cat, min|
    n = count.call(cat)
    errors << "category #{cat}: #{n} < #{min}" if n < min
  end
  skills.each do |s|
    n = valid.count { |c| c["category"] == "positive" && c["expected_skill"] == s }
    errors << "category positive #{s}: #{n} < 2" if n < 2
  end
  errors << "total cases: #{valid.size} not in 30..50" unless (30..50).cover?(valid.size)
  korean = valid.count { |c| c["prompt"].to_s.match?(/\p{Hangul}/) }
  english = valid.size - korean
  errors << "korean prompts: #{korean} < 8" if korean < 8
  errors << "english prompts: #{english} < 8" if english < 8
  if errors.empty?
    summary = categories.map { |cat| "#{cat}=#{count.call(cat)}" }.join(" ")
    puts "ok   #{File.basename(cases_file)}: #{valid.size} cases (#{summary}; korean=#{korean} english=#{english})"
  else
    errors.each { |e| puts "FAIL #{e}" }
    exit 1
  end
' "$CASES" "$REPO_ROOT"
```

- [ ] **Step 5: Run the schema test; it must pass**

Run: `./tests/routing/test-check-routing-cases.sh`
Expected: 8 `ok   - …` lines, then `all routing-case tests passed`, exit 0.
Run: `./scripts/check-routing-cases.sh`
Expected: `ok   cases.yaml: 45 cases (positive=20 negative=8 adjacent=7 official-conflict=6 ambiguous=4; korean=20 english=25)`

- [ ] **Step 6: Create the canned streams and the failing observer test**

The canned streams are trimmed from the 2026-10-13 run of claude 2.1.296. Field names and nesting are kept; long fields (signatures, usage, the tools list) are dropped. One JSON object per line. Create `tests/routing/fixtures/`:

`skill-first.jsonl`
```text
{"type":"system","subtype":"init","claude_code_version":"2.1.296","model":"claude-opus-5","permissionMode":"plan","plugins":[{"name":"ios-tuist-skills","path":"/repo","source":"ios-tuist-skills@inline","version":"0.8.1"}],"skills":["ios-tuist-skills:ios-tuist-architecture-review"]}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"I'll use the dedicated architecture review skill for this."}]},"parent_tool_use_id":null}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"toolu_01","name":"Skill","input":{"skill":"ios-tuist-skills:ios-tuist-architecture-review"},"caller":{"type":"direct"}}]},"parent_tool_use_id":null}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"toolu_02","name":"Bash","input":{"command":"ls -la"}}]},"parent_tool_use_id":null}
```
`explore-then-skill.jsonl`
```text
{"type":"system","subtype":"init","claude_code_version":"2.1.296","model":"claude-opus-5","permissionMode":"plan","plugins":[{"name":"ios-tuist-skills","path":"/repo","source":"ios-tuist-skills@inline","version":"0.8.1"}],"skills":[]}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"toolu_01","name":"Bash","input":{"command":"find . -type f"}}]},"parent_tool_use_id":null}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"toolu_02","name":"Read","input":{"file_path":"/w/Project.swift"}}]},"parent_tool_use_id":null}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"toolu_03","name":"Skill","input":{"skill":"ios-tuist-skills:ios-tuist-feature"}}]},"parent_tool_use_id":null}
```
`write-first.jsonl`
```text
{"type":"system","subtype":"init","claude_code_version":"2.1.296","model":"claude-opus-5","permissionMode":"plan","plugins":[{"name":"ios-tuist-skills","path":"/repo","source":"ios-tuist-skills@inline","version":"0.8.1"}],"skills":[]}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"toolu_01","name":"Bash","input":{"command":"ls"}}]},"parent_tool_use_id":null}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"toolu_02","name":"Write","input":{"file_path":"/home/u/.claude/plans/p.md","content":"# plan"}}]},"parent_tool_use_id":null}
```
`no-tool.jsonl`
```text
{"type":"system","subtype":"init","claude_code_version":"2.1.296","model":"claude-opus-5","permissionMode":"plan","plugins":[{"name":"ios-tuist-skills","path":"/repo","source":"ios-tuist-skills@inline","version":"0.8.1"}],"skills":[]}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"It declares an opaque result type."}]},"parent_tool_use_id":null}
{"type":"result","subtype":"success","is_error":false,"num_turns":1,"total_cost_usd":0.1023225}
```
`other-skill.jsonl`
```text
{"type":"system","subtype":"init","claude_code_version":"2.1.296","model":"claude-opus-5","permissionMode":"plan","plugins":[{"name":"ios-tuist-skills","path":"/repo","source":"ios-tuist-skills@inline","version":"0.8.1"},{"name":"tuist","path":"/official","source":"tuist@inline","version":"0.0.0"}],"skills":[]}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"toolu_01","name":"Skill","input":{"skill":"tuist:migrate"}}]},"parent_tool_use_id":null}
```
`truncated.jsonl` (the second line is deliberately not JSON):
```text
{"type":"system","subtype":"init","claude_code_version":"2.1.296","model":"claude-opus-5","permissionMode":"plan","plugins":[],"skills":[]}
not json at all
{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"toolu_01","name":"Bash","input":{"command":"ls"}}]},"parent_tool_use_id":null}
```
`nested.jsonl`
```text
{"type":"system","subtype":"init","claude_code_version":"2.1.296","model":"claude-opus-5","permissionMode":"plan","plugins":[{"name":"ios-tuist-skills","path":"/repo","source":"ios-tuist-skills@inline","version":"0.8.1"}],"skills":[]}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"toolu_01","name":"Task","input":{"description":"explore"}}]},"parent_tool_use_id":null}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"toolu_02","name":"Skill","input":{"skill":"ios-tuist-skills:ios-tuist-module"}}]},"parent_tool_use_id":"toolu_01"}
```

`tests/routing/test-routing-observe.sh`, then `chmod +x` it:
```bash
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
```

Run: `./tests/routing/test-routing-observe.sh`
Expected: all `FAIL - …` (observer missing), non-zero exit.

- [ ] **Step 7: Implement `scripts/routing-observe.sh`, then `chmod +x` it**

```bash
#!/bin/bash
# Reads `claude -p --output-format stream-json --verbose` on stdin and prints one JSON line:
# which skill was selected and why reading stopped. Exits at the stop event so the producer
# gets SIGPIPE instead of running (and spending) to the end.
#   routing-observe.sh [plugin-name]   (default ios-tuist-skills)
set -euo pipefail

exec ruby -rjson -e '
  plugin = ARGV[0] || "ios-tuist-skills"
  info = {
    "selected" => nil, "stop_reason" => "eof", "nested" => false, "tools_before_stop" => [],
    "write_path" => nil, "plugin_version" => nil, "claude_code_version" => nil, "model" => nil,
    "permission_mode" => nil, "cost_usd" => nil, "result_subtype" => nil
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
          info["write_path"] = item.dig("input", "file_path") || item.dig("input", "notebook_path")
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
' "${1:-ios-tuist-skills}"
```

Run: `./tests/routing/test-routing-observe.sh`
Expected: 8 `ok   - …` lines, `all routing-observe tests passed`, exit 0.

- [ ] **Step 8: Write the failing summarize test**

`tests/routing/fixtures/results-sample.jsonl` holds 5 synthetic rows in the `results.jsonl` row shape:
```text
{"id":"pos-a","category":"positive","fixture":"modular","expected_skill":"ios-tuist-feature","forbidden_skills":[],"selected":"ios-tuist-feature","stop_reason":"skill","nested":false,"tools_before_stop":[],"write_path":null,"plugin_version":"0.9.0","claude_code_version":"2.1.296","model":"m","permission_mode":"plan","cost_usd":null,"result_subtype":null,"elapsed_s":20,"claude_exit":141}
{"id":"pos-b","category":"positive","fixture":"modular","expected_skill":"ios-tuist-dependency","forbidden_skills":[],"selected":"ios-tuist-feature","stop_reason":"skill","nested":false,"tools_before_stop":["Bash"],"write_path":null,"plugin_version":"0.9.0","claude_code_version":"2.1.296","model":"m","permission_mode":"plan","cost_usd":null,"result_subtype":null,"elapsed_s":30,"claude_exit":141}
{"id":"neg-a","category":"negative","fixture":"modular","expected_skill":"none","forbidden_skills":[],"selected":"none","stop_reason":"result","nested":false,"tools_before_stop":[],"write_path":null,"plugin_version":"0.9.0","claude_code_version":"2.1.296","model":"m","permission_mode":"plan","cost_usd":0.1,"result_subtype":"success","elapsed_s":10,"claude_exit":0}
{"id":"amb-a","category":"ambiguous","fixture":"legacy-tuist","expected_skill":"none","forbidden_skills":["ios-tuist-migrate"],"selected":"ios-tuist-migrate","stop_reason":"skill","nested":false,"tools_before_stop":[],"write_path":null,"plugin_version":"0.9.0","claude_code_version":"2.1.296","model":"m","permission_mode":"plan","cost_usd":null,"result_subtype":null,"elapsed_s":15,"claude_exit":141}
{"id":"off-a","category":"official-conflict","fixture":"existing-xcode","expected_skill":"none","forbidden_skills":["ios-tuist-migrate"],"selected":"none","stop_reason":"eof","nested":false,"tools_before_stop":["Bash"],"write_path":null,"plugin_version":"0.9.0","claude_code_version":"2.1.296","model":"m","permission_mode":"plan","cost_usd":0.2,"result_subtype":null,"elapsed_s":40,"claude_exit":0}
```

`tests/routing/test-routing-summarize.sh`, then `chmod +x` it:
```bash
#!/bin/bash
# Unit test for `run-routing-eval.sh summarize` on canned results (no claude needed).
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cp "$REPO_ROOT/tests/routing/fixtures/results-sample.jsonl" "$TMP/results.jsonl"
failures=0

"$REPO_ROOT/scripts/run-routing-eval.sh" summarize "$TMP" > "$TMP/stdout" 2>&1 || { echo "FAIL - summarize exited non-zero: $(cat "$TMP/stdout")"; exit 1; }

want() {
  if grep -qF -- "$2" "$TMP/summary.md"; then echo "ok   - $1"; else echo "FAIL - $1: [$2] not in summary.md"; failures=$((failures + 1)); fi
}
want "overall accuracy"        "Accuracy: 3/5 (60.0%)"
want "category line"           "| ambiguous | 0/1 | 0.0% |"
want "forbidden violation"     "- amb-a: selected ios-tuist-migrate (forbidden)"
want "precision of feature"    "| feature | 1 | 1 | 0 | 0.5 | 1.0 |"
want "eof anomaly listed"      "- off-a: stop_reason eof"
want "cost accounting"         "Known cost: \$0.30 over 2 cases; 3 cases stopped before a result (cost unknown)"
want "plugin version recorded" "Plugin version: 0.9.0"

ruby -rjson -e 'd = JSON.parse(File.read(ARGV[0])); exit(d["cases"].size == 5 && d["aggregate"]["correct"] == 3 ? 0 : 1)' "$TMP/results.json" \
  && echo "ok   - results.json aggregate" || { echo "FAIL - results.json aggregate"; failures=$((failures + 1)); }

[ "$failures" -eq 0 ] && echo "all routing-summarize tests passed" || echo "$failures routing-summarize test(s) failed"
exit "$failures"
```
Run: `./tests/routing/test-routing-summarize.sh`. Expected: `FAIL - summarize exited non-zero: … No such file or directory`, exit 1.

- [ ] **Step 9: Implement `scripts/run-routing-eval.sh`, then `chmod +x` it**

```bash
#!/bin/bash
# Routing evaluation (PRD v0.9 WS-C): which skill does a headless Claude Code session pick?
#   run-routing-eval.sh run --condition plugin-only|plugin+official|none --out DIR \
#       [--cases FILE] [--only id1,id2] [--budget USD] [--official-plugin-dir DIR] [--yes]
#   run-routing-eval.sh summarize DIR
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

usage() {
  sed -n '3,5p' "$0" | sed 's/^# //' >&2
  exit 2
}

summarize() {
  local dir="$1"
  [ -s "$dir/results.jsonl" ] || { echo "error: no results in $dir/results.jsonl" >&2; exit 1; }
  ruby -rjson -e '
    dir = ARGV[0]
    rows = File.readlines(File.join(dir, "results.jsonl"), chomp: true).reject(&:empty?).map { |l| JSON.parse(l) }
    meta_path = File.join(dir, "meta.json")
    meta = File.exist?(meta_path) ? JSON.parse(File.read(meta_path)) : {}
    short = ->(s) { s.to_s.sub(/\Aios-tuist-/, "") }
    pct = ->(a, b) { b.zero? ? "n/a" : format("%.1f%%", 100.0 * a / b) }
    correct = ->(r) { r["selected"] == r["expected_skill"] }
    n_correct = rows.count(&correct)
    by_cat = rows.group_by { |r| r["category"] }.sort.map { |c, rs| [c, rs.count(&correct), rs.size] }
    violations = rows.select { |r| (r["forbidden_skills"] || []).include?(r["selected"]) }
    anomalies = rows.select { |r| r["stop_reason"] == "eof" || r["nested"] }
    skills = rows.flat_map { |r| [r["expected_skill"], r["selected"]] }.uniq
                 .reject { |s| s == "none" || s.to_s.start_with?("other:") }.sort
    per_skill = skills.map do |s|
      tp = rows.count { |r| r["selected"] == s && r["expected_skill"] == s }
      fp = rows.count { |r| r["selected"] == s && r["expected_skill"] != s }
      fn = rows.count { |r| r["expected_skill"] == s && r["selected"] != s }
      { "skill" => s, "tp" => tp, "fp" => fp, "fn" => fn,
        "precision" => (tp + fp).zero? ? nil : (tp.to_f / (tp + fp)).round(3),
        "recall" => (tp + fn).zero? ? nil : (tp.to_f / (tp + fn)).round(3) }
    end
    others = rows.map { |r| r["selected"] }.select { |s| s.to_s.start_with?("other:") }.uniq.sort
    row_labels = skills + ["none"]
    col_labels = skills + ["none"] + others
    matrix = row_labels.map { |e| col_labels.map { |s| rows.count { |r| r["expected_skill"] == e && r["selected"] == s } } }
    known = rows.map { |r| r["cost_usd"] }.compact
    plugin_versions = rows.map { |r| r["plugin_version"] }.compact.uniq
    aggregate = {
      "cases" => rows.size, "correct" => n_correct, "by_category" => by_cat.map { |c, k, n| { "category" => c, "correct" => k, "total" => n } },
      "violations" => violations.map { |r| r["id"] }, "anomalies" => anomalies.map { |r| r["id"] },
      "per_skill" => per_skill, "confusion" => { "rows" => row_labels, "cols" => col_labels, "counts" => matrix },
      "known_cost_usd" => known.sum.round(4), "cost_known_cases" => known.size, "cost_unknown_cases" => rows.size - known.size,
      "plugin_versions" => plugin_versions
    }
    File.write(File.join(dir, "results.json"), JSON.pretty_generate({ "meta" => meta, "aggregate" => aggregate, "cases" => rows }) + "\n")
    fmt = ->(x) { x.nil? ? "n/a" : x.to_s }
    md = []
    md << "# Routing evaluation — #{meta["condition"] || "unknown condition"}"
    md << ""
    md << "Date: #{meta["date"] || "unknown"} | Claude Code: #{rows.map { |r| r["claude_code_version"] }.compact.uniq.join(", ")} | Plugin version: #{plugin_versions.join(", ")} | Budget/case: $#{meta["budget_usd"] || "?"}"
    md << ""
    md << "Accuracy: #{n_correct}/#{rows.size} (#{pct.call(n_correct, rows.size)})"
    md << ""
    md << "| Category | Correct | Rate |"
    md << "|---|---|---|"
    by_cat.each { |c, k, n| md << "| #{c} | #{k}/#{n} | #{pct.call(k, n)} |" }
    md << ""
    md << "## Forbidden-skill violations"
    md << (violations.empty? ? "- none" : violations.map { |r| "- #{r["id"]}: selected #{r["selected"]} (forbidden)" })
    md << ""
    md << "## Per skill"
    md << "| Skill | TP | FP | FN | Precision | Recall |"
    md << "|---|---|---|---|---|---|"
    per_skill.each { |p| md << "| #{short.call(p["skill"])} | #{p["tp"]} | #{p["fp"]} | #{p["fn"]} | #{fmt.call(p["precision"])} | #{fmt.call(p["recall"])} |" }
    md << ""
    md << "## Confusion matrix (rows = expected, columns = selected)"
    md << "| expected \\ selected | #{col_labels.map { |c| short.call(c) }.join(" | ")} |"
    md << "|---|#{col_labels.map { "---" }.join("|")}|"
    row_labels.each_with_index { |e, i| md << "| #{short.call(e)} | #{matrix[i].join(" | ")} |" }
    md << ""
    md << "## Anomalies"
    md << (anomalies.empty? ? "- none" : anomalies.map { |r| r["nested"] ? "- #{r["id"]}: skill selected inside a subagent" : "- #{r["id"]}: stop_reason eof" })
    md << ""
    md << format("Known cost: $%.2f over %d cases; %d cases stopped before a result (cost unknown)", known.sum, known.size, rows.size - known.size)
    File.write(File.join(dir, "summary.md"), md.flatten.join("\n") + "\n")
    puts md.flatten
  ' "$dir"
}

# Same rules as isolation_guard in benchmark-isolated-run.sh: the case must not see this repo.
isolation_guard() {
  local work="$1" path
  case "$work" in "$REPO_ROOT"|"$REPO_ROOT"/*) echo "ISOLATION VIOLATION: $work" >&2; return 1 ;; esac
  path="$work"
  while :; do
    if { [ -d "$path/skills" ] && [ -d "$path/references" ]; } || [ -e "$path/CLAUDE.md" ]; then
      echo "ISOLATION VIOLATION: $path" >&2
      return 1
    fi
    [ "$path" = / ] && break
    path="$(dirname "$path")"
  done
}

run() {
  local condition="" out="" cases="$REPO_ROOT/tests/routing/cases.yaml" only="" budget="0.30" official="" yes=0
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --condition) condition="$2"; shift 2 ;;
      --out) out="$2"; shift 2 ;;
      --cases) cases="$2"; shift 2 ;;
      --only) only="$2"; shift 2 ;;
      --budget) budget="$2"; shift 2 ;;
      --official-plugin-dir) official="$2"; shift 2 ;;
      --yes) yes=1; shift ;;
      *) usage ;;
    esac
  done
  [ -n "$condition" ] && [ -n "$out" ] || usage
  local plugin_args=()
  case "$condition" in
    plugin-only) plugin_args=(--plugin-dir "$REPO_ROOT") ;;
    plugin+official)
      [ -n "$official" ] && [ -d "$official/.claude-plugin" ] || { echo "error: --official-plugin-dir must be a local tuist/agent-plugin checkout" >&2; exit 2; }
      plugin_args=(--plugin-dir "$REPO_ROOT" --plugin-dir "$official") ;;
    none) plugin_args=() ;;
    *) usage ;;
  esac
  "$REPO_ROOT/scripts/check-routing-cases.sh" "$cases"
  [ ! -e "$out/results.jsonl" ] || { echo "error: $out/results.jsonl exists; use a fresh --out" >&2; exit 2; }
  mkdir -p "$out/observe" "$out/raw" "$out/stderr"
  local tmp_root list prompts
  tmp_root="$(cd "${TMPDIR:-/tmp}" && pwd -P)"
  prompts="$(mktemp -d "$tmp_root/routing-prompts.XXXXXX")"
  list="$prompts/list.tsv"
  ruby -ryaml -e '
    only = ARGV[1].to_s.split(",")
    YAML.safe_load(File.read(ARGV[0]))["cases"].each do |c|
      next unless only.empty? || only.include?(c["id"])
      File.write(File.join(ARGV[2], c["id"] + ".txt"), c["prompt"])
      puts [c["id"], c["fixture"]].join("\t")
    end
  ' "$cases" "$only" "$prompts" > "$list"
  local count; count="$(wc -l < "$list" | tr -d " ")"
  [ "$count" -gt 0 ] || { echo "error: no cases selected" >&2; exit 2; }
  echo "Cases: $count, budget/case: \$$budget, worst case: \$$(ruby -e "puts format('%.2f', $count * $budget)")"
  # Guard against accidental spend: more than 5 cases needs an explicit --yes.
  [ "$count" -le 5 ] || [ "$yes" -eq 1 ] || { echo "error: $count cases; re-run with --yes to spend up to the amount above" >&2; exit 2; }
  ruby -rjson -rdigest -e '
    File.write(ARGV[0], JSON.pretty_generate({
      "condition" => ARGV[1], "date" => Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"), "repo_revision" => ARGV[2],
      "claude_version" => ARGV[3], "budget_usd" => ARGV[4].to_f, "cases_sha256" => Digest::SHA256.file(ARGV[5]).hexdigest,
      "official_plugin_dir" => (ARGV[6].empty? ? nil : ARGV[6])
    }) + "\n")
  ' "$out/meta.json" "$condition" "$(git -C "$REPO_ROOT" rev-parse HEAD)" "$(claude --version 2>&1)" "$budget" "$cases" "$official"
  local plans_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plans"
  : > "$out/plans-created.txt"
  local id fixture parent work prompt start statuses observe_status claude_exit
  while IFS=$'\t' read -r id fixture; do
    parent="$(mktemp -d "$tmp_root/routing-eval.XXXXXX")"
    work="$parent/$fixture"
    cp -R "$REPO_ROOT/tests/fixtures/$fixture" "$work"
    # The expectation document would hand the model the answer.
    rm -f "$work/EXPECTATIONS.md" "$work/.gitkeep"
    isolation_guard "$work"
    prompt="$(cat "$prompts/$id.txt")"
    ls -1 "$plans_dir" 2>/dev/null | sort > "$parent/plans-before.txt" || true
    echo "--- $id ($fixture)"
    start=$SECONDS
    set +e
    (cd "$work" && claude -p "$prompt" "${plugin_args[@]}" --setting-sources project --permission-mode plan \
        --output-format stream-json --verbose --max-budget-usd "$budget" < /dev/null 2> "$out/stderr/$id.txt") \
      | tee "$out/raw/$id.jsonl" | "$REPO_ROOT/scripts/routing-observe.sh" > "$out/observe/$id.json"
    statuses=("${PIPESTATUS[@]}")
    set -e
    claude_exit="${statuses[0]}"
    observe_status="${statuses[2]}"
    [ "$observe_status" -eq 0 ] || { echo "error: observer failed on $id" >&2; exit 1; }
    [ -s "$out/observe/$id.json" ] || echo '{"selected":"none","stop_reason":"no-output"}' > "$out/observe/$id.json"
    ruby -ryaml -rjson -e '
      c = YAML.safe_load(File.read(ARGV[0]))["cases"].find { |x| x["id"] == ARGV[1] }
      o = JSON.parse(File.read(ARGV[2]))
      row = { "id" => c["id"], "category" => c["category"], "fixture" => c["fixture"],
              "expected_skill" => c["expected_skill"], "forbidden_skills" => c["forbidden_skills"] || [] }
      puts JSON.generate(row.merge(o).merge("elapsed_s" => ARGV[3].to_i, "claude_exit" => ARGV[4].to_i))
    ' "$cases" "$id" "$out/observe/$id.json" "$((SECONDS - start))" "$claude_exit" >> "$out/results.jsonl"
    # Plan mode writes plan files outside the workdir. List them, never delete: another session may own them.
    ls -1 "$plans_dir" 2>/dev/null | sort | comm -13 "$parent/plans-before.txt" - | sed "s|^|$id\t$plans_dir/|" >> "$out/plans-created.txt" || true
    rm -rf -- "$parent"
  done < "$list"
  rm -rf -- "$prompts"
  summarize "$out"
}

[ "$#" -ge 1 ] || usage
case "$1" in
  run) shift; run "$@" ;;
  summarize) [ "$#" -eq 2 ] || usage; summarize "$2" ;;
  *) usage ;;
esac
```

Deviation from the contracts file, deliberate: plan files created in `~/.claude/plans` are **listed, not deleted**. A concurrent interactive session of the user's could create one in the same window, and deleting it would destroy user data. Step 12 reviews the list by hand.

- [ ] **Step 10: Run all routing unit tests; all must pass**
```bash
./tests/routing/test-routing-summarize.sh
./tests/routing/test-routing-observe.sh
./tests/routing/test-check-routing-cases.sh
bash -n scripts/run-routing-eval.sh && echo "syntax ok"
./scripts/run-routing-eval.sh run --condition plugin-only 2>&1 | head -3   # usage text, exit 2
```
Expected: `all routing-summarize tests passed` (8 ok lines), `all routing-observe tests passed`, `all routing-case tests passed`, `syntax ok`, and the 3 usage lines.

- [ ] **Step 11: CI, .gitignore, README**

`.github/workflows/lint.yml`, job `ci-scripts`. After the Task 1 step `Benchmark summarizer unit tests`, or after `Fixture selection unit tests` if Task 1 is not merged yet, add:
```yaml
      - name: Routing cases schema
        run: ./scripts/check-routing-cases.sh
      - name: Routing eval unit tests
        run: |
          ./tests/routing/test-check-routing-cases.sh
          ./tests/routing/test-routing-observe.sh
          ./tests/routing/test-routing-summarize.sh
```
`perl` (used by the observer test) is preinstalled on `ubuntu-latest` and macOS.

Append to `.gitignore`:
```text

# Routing evaluation: raw stream-json and stderr stay local (large, contain full transcripts)
docs/superpowers/benchmarks/*-routing/*/raw/
docs/superpowers/benchmarks/*-routing/*/stderr/
docs/superpowers/benchmarks/*-routing/*/observe/
```

`README.md`: insert a new section between `## Skill effectiveness benchmark` and `## Non-goals`:
```markdown
## Routing evaluation

`tests/routing/cases.yaml` lists prompts with the skill that should be selected
(or `none`, for requests that belong to no skill or to the official Tuist
plugin). `scripts/run-routing-eval.sh run --condition plugin-only --out <dir> --yes`
runs each prompt headless in a copy of its fixture (without `EXPECTATIONS.md`),
records the first `Skill` call from Claude Code's stream-json output, and writes
`summary.md` (accuracy, per-skill precision/recall, confusion matrix,
forbidden-skill violations). Each case is capped with `--max-budget-usd`
(default 0.30).

**Rule:** a PR that changes any skill's `description:` must re-run the
`plugin-only` evaluation and attach the summary next to the latest baseline
under `docs/superpowers/benchmarks/*-routing/`.

Codex is not evaluated: `codex exec --json` (0.160.0) has no skill event to observe.
```
After Step 12, add the baseline link line `Baseline: [<date> plugin-only](docs/superpowers/benchmarks/<date>-routing/plugin-only/summary.md)` under that paragraph.

Re-run Step 10 plus `ruby -ryaml -e 'YAML.load_file(".github/workflows/lint.yml"); puts "yaml ok"'`. Expected: all pass, `yaml ok`.

- [ ] **Step 12 [hand-off: Claude/user; spends money, needs claude + network]: smoke run, then the baseline**

Smoke run, 2 cases, below the `--yes` threshold, about $0.60 max:
```bash
./scripts/run-routing-eval.sh run --condition plugin-only --out "$TMPDIR/routing-smoke" --only pos-archreview-en,neg-swift-some
cat "$TMPDIR/routing-smoke/results.jsonl"
```
Expected: `pos-archreview-en` has `"selected":"ios-tuist-architecture-review","stop_reason":"skill"` and `neg-swift-some` has `"selected":"none","stop_reason":"result"`. Both carry `"plugin_version":"<current plugin.json version>"`. If the event shape differs (claude version changed), stop. Update the canned fixtures from a fresh raw stream and re-run Step 10 before the baseline.

Baseline. User decision 2026-10-13: plugin-only only, $0.30/case, so at most 45 × $0.30 = $13.50:
```bash
D=docs/superpowers/benchmarks/$(date +%F)-routing/plugin-only
./scripts/run-routing-eval.sh run --condition plugin-only --out "$D" --yes
cat "$D/plans-created.txt"   # review; delete only files you confirm came from this run
git status --short docs/superpowers/benchmarks   # only meta.json, results.jsonl, results.json, summary.md, plans-created.txt
```
`plugin+official` (needs `git clone https://github.com/tuist/agent-plugin "$TMPDIR/agent-plugin" && git -C "$TMPDIR/agent-plugin" checkout 038e54c`) and `none` are implemented but **not run** in this release.

- [ ] **Step 13 [hand-off: Claude]: commits**
```bash
git add tests/routing scripts/check-routing-cases.sh scripts/routing-observe.sh scripts/run-routing-eval.sh .github/workflows/lint.yml .gitignore
git commit -m "feat(routing): add routing evaluation cases, observer and runner (WS-C)"
git add README.md docs/superpowers/benchmarks/*-routing
git commit -m "docs(routing): record plugin-only routing baseline and description-change rule"
```

- [ ] **Step 14 [hand-off: Claude]: PR into `develop`.** The body must contain:
  - The `check-routing-cases.sh` line and the Step 10 test output.
  - The smoke-run JSON lines and the baseline `summary.md`, inlined.
  - Total known cost and the count of cost-unknown cases.
  - The `plans-created.txt` review result.
  - Unverified:
    - The observation method relies on undocumented stream-json behavior (`Skill` tool_use), checked on claude 2.1.296 only.
    - A run stopped at the first `Skill` event never reports `total_cost_usd`, so its cost is unknown (bounded by `--max-budget-usd`).
    - After the observer exits, claude stops only on its next stdout write (SIGPIPE). Spend between the stop event and that write is bounded by the budget cap, not measured.
    - `plugin+official` and `none` were not run.
    - Codex routing is unsupported (no skill event in `codex exec --json` 0.160.0).
    - Pass thresholds are not set (PRD open question 3).
    - Results are N=1 per case. Run-to-run variance (seen in the WS6 smoke run) is not measured.

---

### Task 6: WS-D — version-specific knowledge in one place

Branch `feature/v0.9-ws-d` from `develop` **after Task 3 (WS-B) is merged** (the new reference is synced by WS-B's manifest; link texts below assume WS-B's `references/...` form).

**Goal:** the Tuist versions and issue numbers that `ios-tuist-restyle` rules depend on move to `references/tuist-known-issues.md`, each with a source and a `Last verified` line; the skill keeps the same rules and links the entries; a monthly workflow re-checks the build-observable entries against the latest Tuist and fails (never fixes) when reality differs.

**Files:**
- Create: `references/tuist-known-issues.md`
- Create: `scripts/known-issues-probe.sh`, `scripts/known-issues-compare.sh`, `tests/known-issues/expected.json`
- Create: `.github/workflows/known-issues-recheck.yml`
- Create: `tests/known-issues/test-known-issues.sh`, `tests/known-issues/test-compare.sh`
- Modify: `skills/ios-tuist-restyle/SKILL.md` (7 passages, below), `scripts/skill-resources.manifest` (+1 line), `.github/workflows/lint.yml` (+1 step)
- Generated: `skills/ios-tuist-restyle/references/tuist-known-issues.md` (via `./scripts/sync-skill-resources.sh`)

**Interfaces:**
- Consumes (Task 3): manifest format `<skill> <source>`, `scripts/sync-skill-resources.sh`, `scripts/check-skill-links.sh` (ignores `#fragment`), lint job `skill resources`.
- Produces: anchors `#buildablefolders-minimum-version`, `#buildablefolders-has-no-per-path-exclusion`, `#cross-target-file-references-into-a-buildable-folder`, `#static-framework-resources-with-buildable-folders-original-defect`, `#static-framework-resources-regression-bundlenotfound`, `#static-framework-resources-regression-missed-resource-bundle-copy` (GitHub heading slugs). Probe output lines `<probe>=<result>`.

#### Evidence to re-verify first

```bash
grep -n -o '4\.[0-9]*\.[0-9]*\|#[0-9]\{4,\}' skills/ios-tuist-restyle/SKILL.md
# a1dacba: 66:4.62.0 69:4.62.0 80:4.62.0 128:#8337 135:#8547 135:4.100.0 136:#9156 137:4.128.2 137:#9289 138:4.133.1 141:4.100.0 200:4.62.0 228:4.62.0 241:4.206.0 241:4.62.0 249:#8547 263:4.206.0
grep -n '4\.206\.0' skills/ios-tuist-test-target/SKILL.md skills/ios-tuist-scaffold/SKILL.md
# test-target 224, 259; scaffold 259, 295 — all inside ```text Output Contract examples
```

Findings (read in full on `a1dacba`):
- `ios-tuist-restyle`: every version/issue number outside the Output Contract example is defect or availability knowledge (lines 66-69, 80, 119-122, 126-130, 133-141, 200, 228). Lines 241-275 are an illustrative report example inside a ```` ```text ```` fence.
- `ios-tuist-test-target` and `ios-tuist-scaffold`: the only versions are `Tuist 4.206.0` in example reports (`Version Context: Tuist 4.206.0 (project-pinned, matches active)`). Not defect knowledge; **left unchanged** (state this in the PR).
- `references/version-safety.md` (v0.8.1) already carries version-specific behaviour (`.tuist-version`, `swiftVersion` table) with "Checked tags" columns — its own verification record. **Left in place** (it is evidence-collection procedure, not a defect list); mention in the PR.
- `tests/fixtures/restyle-candidate/EXPECTATIONS.md` repeats #8547/#9156/#9289 and the 4.62.0 floor. Fixture docs, not a skill: out of scope, unchanged.
- No source link exists in the repository for the 4.62.0 introduction of `buildableFolders` or for "no per-path exclusion"; no entry has a recorded verification date. Per the PRD format these get `Last verified: unknown — re-verify` until Step 9 records a probe result.

#### Steps

- [ ] **Step 1: Write the failing tests**

`tests/known-issues/test-known-issues.sh`:

```bash
#!/bin/bash
# WS-D acceptance: restyle rules keep no inline Tuist versions/issue numbers
# outside example fences; every known-issues entry has the PRD fields; every
# link into known-issues points at a real heading.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

ruby - <<'RUBY'
failures = 0
report = ->(ok, name) { puts "#{ok ? 'ok  ' : 'FAIL'} - #{name}"; failures += 1 unless ok }

ki = "references/tuist-known-issues.md"
report.(File.file?(ki), "#{ki} exists")
text = File.file?(ki) ? File.read(ki) : ""
entries = text.split(/^### /)[1..] || []
report.(entries.size >= 6, "at least 6 entries (got #{entries.size})")
fields = ["- Affects:", "- Fixed in:", "- Source:", "- Last verified:", "- Skill impact:"]
entries.each do |e|
  title = e.lines.first.strip
  missing = fields.reject { |f| e.include?("\n#{f}") }
  report.(missing.empty?, "entry '#{title}' has all fields#{missing.empty? ? '' : " (missing #{missing.join(', ')})"}")
end
slug = ->(h) { h.downcase.gsub(/[^a-z0-9 \-]/, "").tr(" ", "-") }
anchors = text.scan(/^### (.+)$/).flatten.map { |h| slug.(h.strip) }

in_fence = false
inline = []
File.foreach("skills/ios-tuist-restyle/SKILL.md").with_index(1) do |line, n|
  if line.lstrip.start_with?("```") then in_fence = !in_fence; next end
  next if in_fence
  inline << "#{n}: #{line.strip}" if line.match?(/\b\d+\.\d+\.\d+\b|#\d{4,}/)
end
report.(inline.empty?, "restyle has no inline version/issue numbers outside fences#{inline.empty? ? '' : "\n  " + inline.join("\n  ")}")

links = Dir.glob("skills/*/SKILL.md").flat_map { |f| File.read(f).scan(/tuist-known-issues\.md#([a-z0-9-]+)/).flatten.map { |a| [f, a] } }
report.(links.any? { |f, _| f.include?("ios-tuist-restyle") }, "restyle links known issues")
links.each { |f, a| report.(anchors.include?(a), "#{f} -> ##{a} exists") }
report.(File.read("scripts/skill-resources.manifest").include?("ios-tuist-restyle references/tuist-known-issues.md"), "manifest syncs known issues into restyle")
exit(failures.zero? ? 0 : 1)
RUBY
```

`tests/known-issues/test-compare.sh`:

```bash
#!/bin/bash
# Unit tests for scripts/known-issues-compare.sh (no Tuist needed).
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CMP="$REPO_ROOT/scripts/known-issues-compare.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/ki-compare.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
failures=0
printf '%s\n' '{"a": "pass", "b": "present"}' > "$TMP/expected.json"

expect() { # expect <name> <exit> <probe lines...>
  local name="$1" want="$2"; shift 2
  printf '%s\n' "$@" > "$TMP/probe.txt"
  local out; out="$(GITHUB_STEP_SUMMARY="$TMP/summary.md" "$CMP" "$TMP/probe.txt" "$TMP/expected.json" 2>&1)"; local got=$?
  if [ "$got" = "$want" ]; then echo "ok   - $name"; else echo "FAIL - $name (exit $got, want $want)"; printf '%s\n' "$out" | sed 's/^/  /'; failures=$((failures + 1)); fi
}
expect "all match" 0 "tuist_version=4.206.0" "a=pass" "b=present"
expect "changed result fails" 1 "tuist_version=4.212.0" "a=pass" "b=absent"
expect "missing probe fails" 1 "tuist_version=4.212.0" "a=pass"
expect "unknown probe line is reported, not fatal" 0 "tuist_version=4.212.0" "a=pass" "b=present" "c=pass"
grep -q '| b | present | present |' "$TMP/summary.md" && echo "ok   - summary table written" || { echo "FAIL - summary table written"; failures=$((failures + 1)); }
exit $((failures > 0))
```

Run: `./tests/known-issues/test-known-issues.sh; ./tests/known-issues/test-compare.sh` — expected FAIL (no known-issues file; compare script missing), exit 1.

- [ ] **Step 2: Create `references/tuist-known-issues.md`**

```markdown
# Tuist known issues

Version-specific Tuist behaviour that skill rules depend on. Skills state
the rule and link the entry; the versions live here so they can be
re-verified in one place without touching the rules.

- `Last verified: unknown — re-verify` means the entry was carried over
  from skill text (v0.8.1) without a recorded check.
- Entries with a `Probe:` line are re-checked by
  `.github/workflows/known-issues-recheck.yml` (monthly and on demand)
  against the pinned and the latest Tuist; a changed result fails that
  workflow and a human updates the entry. Nothing is updated automatically.

### buildableFolders minimum version
- Affects: Tuist earlier than 4.62.0 (`buildableFolders` is not available)
- Fixed in: 4.62.0 (introduced; maps to Xcode 16's synchronized-groups feature)
- Source: carried over from `ios-tuist-restyle` (v0.8.1); no release-note link recorded in this repository
- Last verified: unknown — re-verify
- Skill impact: `ios-tuist-restyle` version floor — below it, every named target is refused and no version bump is suggested.

### buildableFolders has no per-path exclusion
- Affects: every version the skill text was written against ("as of the project-pinned version"); no later version is known to add one
- Fixed in: unknown
- Source: `ios-tuist-restyle` checklist item "Exclude patterns"; fixture `tests/fixtures/restyle-candidate` (`ExcludeFeature` relies on `.glob(pattern:excluding:)`)
- Last verified: unknown — re-verify
- Skill impact: `ios-tuist-restyle` refuses a target whose `sources:`/`resources:` use `.glob(pattern:excluding:)` or any per-file compiler flag/setting.

### Cross-target file references into a buildable folder
- Affects: all versions with `buildableFolders` (issue closed as "not planned": the limitation is acknowledged and intentionally left as-is)
- Fixed in: not planned
- Source: https://github.com/tuist/tuist/issues/8337
- Last verified: unknown — re-verify
- Skill impact: `ios-tuist-restyle` refuses a target when another target's manifest references an individual file inside its source/resource directories.

### Static framework resources with buildable folders (original defect)
- Affects: versions before the fix (lower bound not recorded in the skill text)
- Fixed in: ~4.100.0
- Source: https://github.com/tuist/tuist/issues/8547
- Last verified: unknown — re-verify
- Skill impact: `ios-tuist-restyle` "Static framework + resources" item — never treated as clear only because the pinned version is newer than this fix (see the two regressions below).

### Static framework resources regression: BundleNotFound
- Affects: introduced in 4.128.2 (a `BundleNotFound` crash)
- Fixed in: unknown
- Source: https://github.com/tuist/tuist/issues/9156
- Last verified: unknown — re-verify
- Skill impact: same checklist item; reason the item is reported as checked-with-residual-risk rather than clear.

### Static framework resources regression: missed resource-bundle copy
- Affects: introduced in 4.133.1 (a missed resource-bundle copy)
- Fixed in: unknown
- Source: https://github.com/tuist/tuist/issues/9289
- Last verified: unknown — re-verify
- Probe: `cleanfeature-resource-in-app` (restyle-candidate `CleanFeature`, a `.staticFramework` with `resources:`, converted to `buildableFolders`; checks `dummy.txt` is inside the built `App.app`)
- Skill impact: same checklist item.
```

Every fact above is quoted from `skills/ios-tuist-restyle/SKILL.md` lines 66-68, 119-122, 126-130, 133-141 on `a1dacba`; nothing is added from memory.

- [ ] **Step 3: Rewrite the restyle passages (meaning unchanged; exact before -> after)**

Each "before" must match exactly once (they assume WS-B's `references/` links). Stop and report otherwise.

1. Version Safety, before:
   ```markdown
   Full [version-safety](references/version-safety.md) procedure,
   Existing Project Mode. `buildableFolders` requires **Tuist 4.62.0 or
   later** (introduced in that release, mapping to Xcode 16's
   synchronized-groups feature). If the project-pinned Tuist version is
   older than 4.62.0, refuse every named target and say so — do not
   ```
   after:
   ```markdown
   Full [version-safety](references/version-safety.md) procedure,
   Existing Project Mode. `buildableFolders` requires a minimum Tuist
   version, recorded with its source in
   [known issues: buildableFolders minimum version](references/tuist-known-issues.md#buildablefolders-minimum-version).
   If the project-pinned Tuist version is older than that minimum, refuse
   every named target and say so — do not
   ```

2. Workflow step 2, before:
   ```markdown
   2. **Confirm the Tuist version floor** — project-pinned version ≥ 4.62.0
      ([version-safety](references/version-safety.md)). Below the
   ```
   after:
   ```markdown
   2. **Confirm the Tuist version floor** — project-pinned version ≥ the
      minimum in [known issues: buildableFolders minimum version](references/tuist-known-issues.md#buildablefolders-minimum-version)
      ([version-safety](references/version-safety.md)). Below the
   ```

3. Checklist "Exclude patterns", before:
   ```markdown
     excluding specific files or paths within an included folder as of the
     project-pinned version — a target relying on exclusion cannot be
   ```
   after:
   ```markdown
     excluding specific files or paths within an included folder as of the
     project-pinned version
     ([known issues: no per-path exclusion](references/tuist-known-issues.md#buildablefolders-has-no-per-path-exclusion))
     — a target relying on exclusion cannot be
   ```

4. Checklist "Cross-target file references", before:
   ```markdown
     a real Tuist defect (tuist/tuist#8337, closed as "not planned," i.e.
     the limitation itself is acknowledged and intentionally left as-is,
     not a bug awaiting a fix), not a hypothetical.
   ```
   after:
   ```markdown
     a real Tuist limitation, acknowledged and intentionally left as-is
     rather than a bug awaiting a fix
     ([known issues: cross-target file references](references/tuist-known-issues.md#cross-target-file-references-into-a-buildable-folder)),
     not a hypothetical.
   ```

5. Checklist "Static framework + resources", before:
   ```markdown
     has a real history of breakage in Tuist — the original defect
     (tuist/tuist#8547) was fixed in ~4.100.0, but the same resource-bundle
     path has regressed at least twice since (tuist/tuist#9156, a
     `BundleNotFound` crash introduced in 4.128.2; tuist/tuist#9289, a
     missed resource-bundle copy introduced in 4.133.1) — so "fixed once"
     does not mean "stable," and no single version floor can be cited as
     safe going forward. Never wave this item through solely because the
     project-pinned version is newer than 4.100.0. Instead: check Tuist's
   ```
   after:
   ```markdown
     has a real history of breakage in Tuist — an original defect was
     fixed, but the same resource-bundle path has regressed at least twice
     since (the three "Static framework resources" entries in
     [known issues](references/tuist-known-issues.md#static-framework-resources-with-buildable-folders-original-defect))
     — so "fixed once" does not mean "stable," and no single version floor
     can be cited as safe going forward. Never wave this item through
     solely because the project-pinned version is newer than the version
     that fixed the original defect. Instead: check Tuist's
   ```

6. Decision Rules, before: `  project is below the 4.62.0 floor — refuse and point at` — after: `  project is below the buildableFolders minimum version — refuse and point at`

7. Output Contract template, before: `Version Context (Tuist version vs. the 4.62.0 buildableFolders floor)` — after: `Version Context (Tuist version vs. the buildableFolders minimum version)`

Unchanged on purpose: the Output Contract **example** (lines ~241-275, inside ```` ```text ````) keeps `Tuist 4.206.0`, `4.62.0` and `tuist/tuist#8547` — it illustrates what a report looks like, and a report is expected to cite concrete versions/issues from the known-issues entries. Rule meanings: floor still refuses all targets below it; static-framework item still never passes on version alone; exclusion and cross-target items still refuse.

- [ ] **Step 4: Sync the new reference into restyle**

Add to `scripts/skill-resources.manifest` (in the `ios-tuist-restyle` group):

```text
ios-tuist-restyle references/tuist-known-issues.md
```

```bash
./scripts/sync-skill-resources.sh | tail -1         # sync: 1 change(s)
./scripts/check-skill-links.sh | tail -1            # ... 0 problem(s)
./tests/known-issues/test-known-issues.sh           # all ok
```

- [ ] **Step 5: Write the probe and the compare scripts**

`scripts/known-issues-probe.sh` (needs mise, Tuist, Xcode — CI/Claude only):

```bash
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
```

`scripts/known-issues-compare.sh`:

```bash
#!/bin/bash
# Compares known-issues-probe.sh output with tests/known-issues/expected.json.
# A difference fails the job so a human re-verifies the entry; nothing is edited.
# Usage: known-issues-compare.sh <probe-output> <expected.json>
set -euo pipefail

ruby -rjson - "$1" "$2" <<'RUBY'
got = File.readlines(ARGV[0], chomp: true).select { |l| l.include?("=") }.map { |l| l.split("=", 2) }.to_h
want = JSON.parse(File.read(ARGV[1]))
version = got.delete("tuist_version") || "unknown"
rows = want.map { |probe, exp| [probe, exp, got.fetch(probe, "missing")] }
extra = got.keys - want.keys
table = ["Tuist #{version}", "", "| probe | expected | got |", "|---|---|---|"] + rows.map { |r| "| #{r.join(' | ')} |" }
puts table
File.write(ENV["GITHUB_STEP_SUMMARY"], table.join("\n") + "\n", mode: "a") if ENV["GITHUB_STEP_SUMMARY"]
extra.each { |p| puts "::warning title=unexpected probe::#{p}=#{got[p]} has no expectation" }
bad = rows.reject { |_, exp, actual| exp == actual }
bad.each { |p, exp, actual| puts "::error title=known issue changed::#{p}: expected #{exp}, got #{actual} on Tuist #{version} — re-verify references/tuist-known-issues.md" }
exit(bad.empty? ? 0 : 1)
RUBY
```

`tests/known-issues/expected.json`:

```json
{
  "restyle-baseline-build": "pass",
  "cleanfeature-buildablefolders-build": "pass",
  "cleanfeature-resource-in-app": "present"
}
```

Basis: `tests/fixtures/restyle-candidate/EXPECTATIONS.md` records (4.206.0) that the baseline builds and the converted `CleanFeature` builds and tests; `present` is the non-defect outcome for #9289 and is **unverified until Step 8**.

```bash
chmod +x scripts/known-issues-probe.sh scripts/known-issues-compare.sh tests/known-issues/*.sh
bash -n scripts/known-issues-probe.sh && echo "syntax ok"
./tests/known-issues/test-compare.sh      # all ok
```

- [ ] **Step 6: Add the workflow**

`.github/workflows/known-issues-recheck.yml`:

```yaml
name: Known issues recheck

# Re-runs the build-observable entries of references/tuist-known-issues.md
# against the pinned and the latest Tuist. A changed result fails the job
# so a human re-verifies the entry; nothing is changed automatically.
on:
  schedule:
    - cron: "0 18 1 * *"
  workflow_dispatch:

jobs:
  probe:
    name: probe (Tuist ${{ matrix.tuist }})
    runs-on: macos-15
    strategy:
      fail-fast: false
      matrix:
        tuist: ["4.206.0", "latest"]
    env:
      XDG_CACHE_HOME: /tmp/tuist/cache
      XDG_STATE_HOME: /tmp/tuist/state
      XDG_DATA_HOME: /tmp/tuist/data
    steps:
      - uses: actions/checkout@v6
      - name: Install mise
        run: brew install mise
      - name: Resolve and install Tuist
        id: tuist
        run: |
          # aqua is the registry default on a clean machine; naming it keeps
          # "latest" from coming from an asdf plugin's non-semver tag list.
          if [ "${{ matrix.tuist }}" = latest ]; then v="$(mise latest aqua:tuist/tuist)"; else v="${{ matrix.tuist }}"; fi
          echo "Resolved Tuist: $v"
          echo "version=$v" >> "$GITHUB_OUTPUT"
          mise install "tuist@$v"
      - name: Probe
        run: ./scripts/known-issues-probe.sh "${{ steps.tuist.outputs.version }}" | tee probe.txt
      - name: Compare with expectations
        run: ./scripts/known-issues-compare.sh probe.txt tests/known-issues/expected.json
```

The pinned row is the control: if it fails, the probe (not Tuist) is broken. Version `4.206.0` must equal the `restyle-candidate` entry in `tests/fixtures/ci-matrix.json`; add that check to `tests/known-issues/test-known-issues.sh`:

```ruby
pinned = JSON.parse(File.read("tests/fixtures/ci-matrix.json")).find { |e| e["fixture"] == "restyle-candidate" }["tuist"]
report.(File.read(".github/workflows/known-issues-recheck.yml").include?(%(tuist: ["#{pinned}", "latest"])), "recheck control version matches ci-matrix (#{pinned})")
```

(add `require "json"` at the top of that ruby block). Lint: append to the `skill resources` job in `lint.yml`:

```yaml
      - name: Known-issues tests
        run: |
          ./tests/known-issues/test-known-issues.sh
          ./tests/known-issues/test-compare.sh
```

No `validate-fixtures.yml` / `ci-select-fixtures.sh` change: the probe copies the fixture and is never run by fixture validation.

- [ ] **Step 7: Run the local tests**

```bash
./tests/known-issues/test-known-issues.sh; echo "exit=$?"   # all ok, exit=0
./tests/known-issues/test-compare.sh; echo "exit=$?"        # all ok, exit=0
./tests/skills/test-self-containment.sh; echo "exit=$?"     # still all ok
./scripts/sync-skill-resources.sh | tail -1                 # sync: 0 change(s)
```

- [ ] **Step 8: [hand-off] Run the probe locally for the pinned version** (Claude/user; needs mise + Tuist + Xcode)

```bash
./scripts/known-issues-probe.sh 4.206.0 | tee /tmp/probe-4.206.0.txt
./scripts/known-issues-compare.sh /tmp/probe-4.206.0.txt tests/known-issues/expected.json; echo "exit=$?"
```

Expected: `restyle-baseline-build=pass`, `cleanfeature-buildablefolders-build=pass`, `cleanfeature-resource-in-app=present`, exit 0. If `cleanfeature-resource-in-app=absent` on 4.206.0: stop and report (either the probe looks in the wrong place — record `find .../App.app` output — or the defect is present on the pinned version, which changes the restyle fixture's EXPECTATIONS; that is a user decision, not a plan change).

- [ ] **Step 9: Record the verification** (after Step 8 passes)

In `references/tuist-known-issues.md`, entry "Static framework resources regression: missed resource-bundle copy", replace `- Last verified: unknown — re-verify` with `- Last verified: 4.206.0 on <YYYY-MM-DD of the Step 8 run> (probe: present)`. Re-run `./scripts/sync-skill-resources.sh` (1 change) and the tests. Other entries stay `unknown — re-verify` (no probe covers them; say so in the PR).

- [ ] **Step 10: Commit** ([hand-off] to Claude)

```bash
git add references/tuist-known-issues.md skills/ios-tuist-restyle scripts/skill-resources.manifest tests/known-issues
git commit -m "refactor(restyle): move Tuist version-specific defects to tuist-known-issues (WS-D)"
git add scripts/known-issues-probe.sh scripts/known-issues-compare.sh .github/workflows/known-issues-recheck.yml .github/workflows/lint.yml
git commit -m "ci: monthly known-issues recheck against the latest Tuist (WS-D)"
```

- [ ] **Step 11: [hand-off] One dispatch run after merge** (PRD acceptance: "workflow_dispatch로 1회 실행 결과가 기록됨")

`workflow_dispatch` is only offered for workflows on the default branch (`develop`), so run it after the PR merges:

```bash
gh workflow run known-issues-recheck.yml --ref develop
gh run list --workflow known-issues-recheck.yml --limit 1
gh run view <id> --json conclusion,jobs -q '.conclusion, (.jobs[] | "\(.name): \(.conclusion)")'
```

Record both rows (4.206.0 and the resolved latest, e.g. 4.212.0 on 2026-10-12) in the release PR / CHANGELOG. A failing `latest` row is a finding to report and to turn into an entry update by a human, not a reason to change `expected.json` silently.

**PR body must include:** the before/after of all 7 restyle passages; the evidence grep before and the test output after; the decision to leave test-target/scaffold examples, `version-safety.md` tables and restyle-candidate EXPECTATIONS unchanged (with reasons); Step 8 probe output; that the new workflow is not a required check; that Step 11 happens after merge.

**Unverified (list in PR):** `brew install mise` and `mise latest aqua:tuist/tuist` on the `macos-15` runner (verified only locally, mise 2026.5.7: `4.212.0`); that `dummy.txt` presence in `App.app` is the right observable for tuist/tuist#9289 (the issue text was not re-read for this plan); the `Fixed in` values and every `Last verified: unknown` entry (carried over from skill text); the 4.62.0 introduction of `buildableFolders` (no source link in the repository).

---

### Task 7: Release v0.9.0 (Claude + user)

**Files:**
- Modify: `.claude-plugin/plugin.json` (`"version"`), `CHANGELOG.md`

- [ ] **Step 1: Confirm all six task PRs are merged into `develop`**

Run: `gh pr list --state merged --base develop --search "v0.9" --json number,title,headRefName`
Expected: PRs for `feature/v0.9-ws-h`, `-ws-a`, `-ws-b`, `-ws-e`, `-ws-c`, `-ws-d`.

- [ ] **Step 2: CHANGELOG `[0.9.0] - <date>`** on branch `chore/release-0.9.0`, one entry per task with its PR number, and explicitly:
  - **Output format change (WS-E):** every skill's Output Contract now ends with an `ios-tuist-result` block.
  - **Skill folder structure change (WS-B):** each `skills/<skill>/` now contains generated `references/`, `templates/`, `scripts/` copies; edit the root originals only. Affects anyone installing a single skill folder.
  - **Research gates** with their sources (Deviations 2 and 4 of this plan; mise `latest aqua:tuist/tuist`).
  - **Deferred:** WS-F, WS-G to v0.9.x.
  - Routing baseline link (`docs/superpowers/benchmarks/<date>-routing/`).

- [ ] **Step 3: Bump** `.claude-plugin/plugin.json` `"version": "0.9.0"`; verify with `ruby -rjson -e 'puts JSON.parse(File.read(".claude-plugin/plugin.json"))["version"]'` → `0.9.0`.

- [ ] **Step 3b: Ask the user** whether to add `golden tests` and `skill resources` to the required checks of `develop` and `main` (they gate nothing until then).

- [ ] **Step 4: PR into `develop`**, then PR `develop` → `main` titled `release: v0.9.0` (`gh pr update-branch` only with the user's OK).

- [ ] **Step 5: After the user merges:** annotated tag `v0.9.0` on the main merge commit (message `ios-tuist-skills 0.9.0`), push, `gh release create v0.9.0 --verify-tag --latest --title "v0.9.0 — Deterministic Core & Routing Evaluation"` with the CHANGELOG 0.9.0 section + `compare/v0.8.1...v0.9.0` link. Tag and Release need the user's OK.
