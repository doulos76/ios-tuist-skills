# CI Speedup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Implementation owner: Codex.** This repo's Claude session only produced
> the spec, the plan and the CI-0 measurements. Codex's `workspace-write`
> sandbox cannot `git commit`, push, or run `mise`/`tuist`/`xcodebuild`, and
> may not reach GitHub (`gh`). For those steps stop and print the exact
> command for Claude/the user (see "Execution notes").

**Goal:** Cut fixture-CI wall time by running macOS jobs only where needed, without removing any validation.

**Architecture:** A cheap ubuntu `changes` job picks the fixtures to validate from the changed paths (`scripts/ci-select-fixtures.sh`, unit-tested). The macOS `validate` matrix runs only those fixtures. An always-run ubuntu `fixtures-ok` job aggregates the result and becomes the single required check. Non-macOS checks live in `lint.yml`.

**Tech Stack:** GitHub Actions, bash, ruby (JSON, as in `scripts/validate-fixtures-locally.sh`), python3 (measurement helper only).

**Spec:** `docs/superpowers/specs/2026-10-02-ci-speedup-design.md` (read it first; this plan follows its CI-0…CI-6 numbering). **Baseline data:** `docs/superpowers/ci/2026-10-baseline.md`.

## Global Constraints

- **Validation scope never shrinks.** A change to a fixture keeps that fixture's generate/build/test. `develop`/`main` pushes, `workflow_dispatch` and `schedule` always run **every** fixture. (`ios-tuist-ci`'s "Never remove a validation step" applies to this repo's own CI.)
- **Do not change branch protection yourself.** Required-check changes are requested from the user with exact wording (Task 2 Step 9).
- GitHub-hosted runners only (`macos-15` for fixtures, `ubuntu-latest` for the rest). No self-hosted runner, no Tuist/SPM caching.
- One PR per task, branch `ci/<id>` cut from `develop`. Commit messages: Conventional Commits, matching `git log` on `develop`.
- Every PR body contains before/after durations (from `scripts/ci-measure.py`) and every verification command's real output. Anything not run is "Unverified".
- Do not touch skill content, fixtures' sources, or v0.8/v0.9 files other than where a task says so.
- Order matters: **Tasks 1–2 (CI-1, CI-2) must land before v0.8 Task 3 (WS3)** — WS3's pin check reads the matrix and adds a CI job; it was updated to use `tests/fixtures/ci-matrix.json` and `lint.yml`.

## Review Focus

- A PR that changes **only** `docs/**` or `skills/**`: zero macOS jobs, `fixtures-ok` green. (Skipped matrix jobs must not leave a pending required check.)
- A PR that changes **one** file inside **one** fixture: exactly that fixture runs, including a fixture with several `test_schemes` (`modular`).
- A PR that changes **only a fixture not in the matrix** (`tests/fixtures/new-project/…`): nothing runs, no crash.
- `git diff base...head` **fails** (bad SHA / shallow clone): selection falls back to **all fixtures**, never to none.
- A PR that edits `validate-fixtures.yml`, `ci-matrix.json` or one of the CI scripts: all fixtures run.
- `validate` job **cancelled** or **failed** → `fixtures-ok` fails; **skipped** → passes.

## Execution notes

- Pre-measured facts the tasks rely on (2026-10-02, `docs/superpowers/ci/2026-10-baseline.md`): queue wait averages 13.6 min vs 4.9 min job runtime; Test step is 242 s of a 293 s job; the Build step is 29 s. So job **count** matters most; Build-step merging saves ≤ 29 s.
- `scripts/ci-select-fixtures.sh` and its unit test need only bash + ruby: Codex can run them locally. Everything needing GitHub (runs, logs, required checks) or Xcode is a hand-off.
- After PR #27 merges, `push` runs only on `main`/`develop`; PR branches get one `pull_request` run per head commit and superseded runs are cancelled.
- Required status checks are a manual list in branch protection. Until the user switches them to `fixtures-ok`, docs-only PRs would wait forever for skipped fixture jobs — hence the exact sequence in Task 2 Step 9.

---

### Task 1: CI-1 — verify the duplicate-run fix and add the measurement helper

Branch: `ci/measure-helper` (CI-1 itself is PR #27, already authored; this task verifies it and records the "after" numbers).

**Files:**
- Create: `scripts/ci-measure.py`
- Modify: `docs/superpowers/ci/2026-10-baseline.md` (append "## 6. After CI-1")

**Interfaces:**
- Produces: `python3 scripts/ci-measure.py <run-id>...` printing job duration, queue wait and per-step means (used by Tasks 2, 3, 6).

- [ ] **Step 1: Confirm #27 is merged** (hand-off if no `gh`): `gh pr view 27 --json state` → `MERGED`. If not merged, stop and report.

- [ ] **Step 2: Verify behaviour** (hand-off): push a trivial commit to any PR branch twice; `gh run list --branch <b> --json event,status,conclusion` must show only `pull_request` runs and the older one `cancelled`. Record the output.

- [ ] **Step 3: Create `scripts/ci-measure.py`:**

```python
#!/usr/bin/env python3
"""Summarise Validate-fixtures runs: job time, queue wait, per-step means.

Usage: ci-measure.py <run-id> [<run-id> ...]   (needs an authenticated `gh`)
Only successful jobs are counted. Queue wait = job start - run creation.
"""
import collections
import datetime as dt
import json
import statistics as st
import subprocess
import sys


def ts(value):
    return dt.datetime.fromisoformat(value.replace("Z", "+00:00"))


def main(run_ids):
    steps = collections.defaultdict(list)
    waits, durations = [], []
    for run_id in run_ids:
        out = subprocess.run(
            ["gh", "run", "view", run_id, "--json", "jobs,createdAt"],
            check=True, capture_output=True, text=True,
        ).stdout
        run = json.loads(out)
        created = ts(run["createdAt"])
        for job in run["jobs"]:
            if job["conclusion"] != "success" or not job.get("startedAt"):
                continue
            waits.append((ts(job["startedAt"]) - created).total_seconds())
            durations.append((ts(job["completedAt"]) - ts(job["startedAt"])).total_seconds())
            for step in job["steps"]:
                if step.get("startedAt") and step.get("completedAt"):
                    steps[step["name"]].append((ts(step["completedAt"]) - ts(step["startedAt"])).total_seconds())
    if not durations:
        sys.exit("no successful jobs found")
    print(f"jobs measured: {len(durations)}")
    print("job duration s : mean %.0f median %.0f max %.0f" % (st.mean(durations), st.median(durations), max(durations)))
    print("queue wait s   : mean %.0f median %.0f max %.0f" % (st.mean(waits), st.median(waits), max(waits)))
    print("step means (s):")
    for name, values in sorted(steps.items(), key=lambda kv: -st.mean(kv[1])):
        print(f"  {st.mean(values):6.0f}  n={len(values):3d}  {name}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    main(sys.argv[1:])
```

- [ ] **Step 4: Check it runs** (`python3 -m py_compile scripts/ci-measure.py` — Codex can run). Then hand off `python3 scripts/ci-measure.py 36887896322` (a known run): expected `jobs measured: 10`, Test step mean in the 200–300 s range.

- [ ] **Step 5: Append "## 6. After CI-1"** to the baseline doc with the output of `ci-measure.py` for ≥ 3 PR runs created after #27 merged (hand-off for the numbers), the observed run-count per commit (expect 1), and the sentence "before = sections 1–2". Do not edit sections 1–5.

- [ ] **Step 6: Commit** (hand-off)

```bash
chmod +x scripts/ci-measure.py
git add scripts/ci-measure.py docs/superpowers/ci/2026-10-baseline.md
git commit -m "ci: add run measurement helper and record post-dedup numbers"
```

---

### Task 2: CI-2 (+ CI-4 skeleton) — path-based fixture selection, `fixtures-ok`, `lint.yml`

Branch: `ci/ci-2-path-selection`. Separate commits per step group (Steps 1–2, 3–6, 7, 8).

**Files:**
- Create: `tests/fixtures/ci-matrix.json`
- Create: `scripts/ci-select-fixtures.sh`
- Create: `tests/ci/test-select-fixtures.sh`
- Create: `.github/workflows/lint.yml`
- Modify: `.github/workflows/validate-fixtures.yml`
- Modify: `scripts/validate-fixtures-locally.sh` (matrix source: yml → JSON)

**Interfaces:**
- Produces: `tests/fixtures/ci-matrix.json` (array of `{fixture, tuist, workspace, resolve_cmd, test_schemes}`), `scripts/ci-select-fixtures.sh --event <e> [--base <sha> --head <sha> | --files-from <file>] [--github-output]`, check names `changes`, `validate`, **`fixtures-ok`** and workflow `Lint`.
- Consumed later by: v0.8 Task 3 (`scripts/check-fixture-pins.sh` reads `ci-matrix.json`; its job goes in `lint.yml`).

- [ ] **Step 1: Re-verify the matrix** you are about to move: `sed -n 15,60p .github/workflows/validate-fixtures.yml`. The JSON below must equal it exactly (10 entries). If the workflow differs (new fixture, changed scheme), stop and report.

- [ ] **Step 2: Create `tests/fixtures/ci-matrix.json`:**

```json
[
  { "fixture": "legacy-tuist",          "tuist": "4.206.0", "workspace": "App",                 "resolve_cmd": "install", "test_schemes": "App" },
  { "fixture": "modular",               "tuist": "4.206.0", "workspace": "App",                 "resolve_cmd": "install", "test_schemes": "App ProfileFeature SharedUITests" },
  { "fixture": "version-mismatch",      "tuist": "4.62.0",  "workspace": "App",                 "resolve_cmd": "install", "test_schemes": "App" },
  { "fixture": "extract-candidate",     "tuist": "4.206.0", "workspace": "App",                 "resolve_cmd": "install", "test_schemes": "App" },
  { "fixture": "architecture-smells",   "tuist": "4.206.0", "workspace": "App",                 "resolve_cmd": "install", "test_schemes": "App FeatureA CoreKit" },
  { "fixture": "ci-gaps",               "tuist": "4.206.0", "workspace": "App",                 "resolve_cmd": "install", "test_schemes": "App" },
  { "fixture": "migrate-candidate",     "tuist": "3.42.2",  "workspace": "MigrateCandidate",    "resolve_cmd": "fetch",   "test_schemes": "App" },
  { "fixture": "restyle-candidate",     "tuist": "4.206.0", "workspace": "RestyleCandidate",    "resolve_cmd": "install", "test_schemes": "App" },
  { "fixture": "test-target-candidate", "tuist": "4.206.0", "workspace": "TestTargetCandidate", "resolve_cmd": "install", "test_schemes": "App" },
  { "fixture": "scaffold-candidate",    "tuist": "4.206.0", "workspace": "ScaffoldCandidate",   "resolve_cmd": "install", "test_schemes": "App" }
]
```
Check: `ruby -rjson -e 'p JSON.parse(File.read("tests/fixtures/ci-matrix.json")).size'` → `10`.

- [ ] **Step 3: Point `scripts/validate-fixtures-locally.sh` at the JSON.** Replace its `WORKFLOW_FILE=…` line and the `MATRIX_TSV=…ruby -ryaml…` block (L11 and L21-L33) with:

```bash
MATRIX_FILE="$REPO_ROOT/tests/fixtures/ci-matrix.json"
```
```bash
MATRIX_TSV="$(ruby -rjson -e '
  JSON.parse(File.read(ARGV[0])).each do |entry|
    puts [
      entry.fetch("fixture"),
      entry.fetch("tuist").to_s,
      entry.fetch("workspace"),
      entry.fetch("resolve_cmd"),
      entry.fetch("test_schemes"),
    ].join("\t")
  end
' "$MATRIX_FILE")"
```
and change the error message to `$MATRIX_FILE`. Update the header comment ("driven by the workflow file's own matrix" → "driven by tests/fixtures/ci-matrix.json, the same file the CI reads"). Check: `bash -n scripts/validate-fixtures-locally.sh`; hand off `./scripts/validate-fixtures-locally.sh migrate-candidate` (expect pass).

- [ ] **Step 4 (test first): Write `tests/ci/test-select-fixtures.sh`** (chmod +x):

```bash
#!/bin/bash
# Unit tests for scripts/ci-select-fixtures.sh (bash + ruby only).
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SELECT="$REPO_ROOT/scripts/ci-select-fixtures.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
failures=0

names_of() {
  ruby -rjson -e 'puts JSON.parse(STDIN.read)["matrix"]["include"].map { |e| e["fixture"] }.sort.join(",")'
}
flag_of() {
  ruby -rjson -e 'puts JSON.parse(STDIN.read)["has_fixtures"]'
}
ALL="$(ruby -rjson -e 'puts JSON.parse(File.read(ARGV[0])).map { |e| e["fixture"] }.sort.join(",")' "$REPO_ROOT/tests/fixtures/ci-matrix.json")"

# expect <name> <expected fixtures csv> <event> [changed files...]
expect() {
  local name="$1" expected="$2" event="$3"; shift 3
  printf '%s\n' "$@" > "$TMP/files"
  local out; out="$("$SELECT" --event "$event" --files-from "$TMP/files")"
  local got; got="$(printf '%s' "$out" | names_of)"
  local want_flag="true"; [ -z "$expected" ] && want_flag="false"
  local got_flag; got_flag="$(printf '%s' "$out" | flag_of)"
  if [ "$got" = "$expected" ] && [ "$got_flag" = "$want_flag" ]; then
    echo "ok   - $name"
  else
    echo "FAIL - $name: expected [$expected]/$want_flag, got [$got]/$got_flag"
    failures=$((failures + 1))
  fi
}

expect "docs and skills only select nothing" "" pull_request docs/superpowers/a.md skills/ios-tuist-ci/SKILL.md README.md .claude-plugin/plugin.json
expect "one file in one fixture"             "modular" pull_request tests/fixtures/modular/App/Sources/A.swift
expect "dotfile inside a fixture"            "extract-candidate" pull_request tests/fixtures/extract-candidate/.tool-versions
expect "two fixtures plus docs"              "ci-gaps,modular" pull_request docs/x.md tests/fixtures/modular/Project.swift tests/fixtures/ci-gaps/Tuist.swift
expect "fixture outside the matrix"          "" pull_request tests/fixtures/new-project/README.md
expect "workflow change selects all"         "$ALL" pull_request .github/workflows/validate-fixtures.yml
expect "matrix file change selects all"     "$ALL" pull_request tests/fixtures/ci-matrix.json
expect "local validator change selects all"  "$ALL" pull_request scripts/validate-fixtures-locally.sh
expect "selector change selects all"         "$ALL" pull_request scripts/ci-select-fixtures.sh
expect "push selects all"                    "$ALL" push docs/x.md
expect "workflow_dispatch selects all"       "$ALL" workflow_dispatch
expect "schedule selects all"                "$ALL" schedule

# A failing git diff must fall back to every fixture, never to none.
out="$("$SELECT" --event pull_request --base 0000000000000000000000000000000000000001 --head 0000000000000000000000000000000000000002 2>/dev/null)"
got="$(printf '%s' "$out" | names_of)"
if [ "$got" = "$ALL" ]; then echo "ok   - unresolvable diff selects all"; else echo "FAIL - unresolvable diff: got [$got]"; failures=$((failures + 1)); fi

[ "$failures" -eq 0 ] && echo "all selection tests passed" || echo "$failures selection test(s) failed"
exit "$failures"
```

- [ ] **Step 5: Run it, expect FAIL** (script missing): `./tests/ci/test-select-fixtures.sh; echo "exit=$?"` → errors / non-zero.

- [ ] **Step 6: Create `scripts/ci-select-fixtures.sh`** (chmod +x):

```bash
#!/bin/bash
# Chooses which fixtures the macOS matrix must validate for a change set.
# Pure function of (event, changed files, ci-matrix.json). Fails SAFE: when the
# change set cannot be computed it selects every fixture, never none.
#
#   ci-select-fixtures.sh --event <event> --base <sha> --head <sha> [--github-output]
#   ci-select-fixtures.sh --event pull_request --files-from <file>   # for tests
#
# Only pull_request events are filtered. push (main/develop), workflow_dispatch
# and schedule always validate everything, which backstops any gap in the path
# rules below.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MATRIX_FILE="${CI_MATRIX_FILE:-$REPO_ROOT/tests/fixtures/ci-matrix.json}"

event="" base="" head="" files_from="" github_output=0
while [ $# -gt 0 ]; do
  case "$1" in
    --event) event="${2:-}"; shift 2 ;;
    --base) base="${2:-}"; shift 2 ;;
    --head) head="${2:-}"; shift 2 ;;
    --files-from) files_from="${2:-}"; shift 2 ;;
    --github-output) github_output=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
[ -n "$event" ] || { echo "--event is required" >&2; exit 2; }

changed_files=""
effective_event="$event"
if [ "$event" = "pull_request" ]; then
  if [ -n "$files_from" ]; then
    changed_files="$(cat "$files_from")"
  elif [ -n "$base" ] && [ -n "$head" ] && changed_files="$(git -C "$REPO_ROOT" diff --name-only "$base...$head" 2>/dev/null)"; then
    :
  else
    echo "warning: could not compute the changed files; validating every fixture" >&2
    effective_event="diff-failed"
  fi
fi

CHANGED_FILES="$changed_files" EVENT="$effective_event" TO_GITHUB="$github_output" ruby -rjson -e '
  matrix = JSON.parse(File.read(ARGV[0]))
  names = matrix.map { |e| e.fetch("fixture") }
  files = ENV.fetch("CHANGED_FILES").split("\n").reject(&:empty?)
  everything = [
    %r{\A\.github/workflows/validate-fixtures\.yml\z},
    %r{\Atests/fixtures/ci-matrix\.json\z},
    %r{\Ascripts/(validate-fixtures-locally|ci-select-fixtures|ci-pick-simulator)\.sh\z},
  ]
  reasons = {}
  select_all = nil
  if ENV["EVENT"] != "pull_request"
    select_all = "event #{ENV["EVENT"]} always validates every fixture"
  else
    files.each do |f|
      if everything.any? { |re| re.match?(f) }
        select_all ||= "#{f} affects every fixture"
      elsif (m = %r{\Atests/fixtures/([^/]+)/}.match(f)) && names.include?(m[1])
        (reasons[m[1]] ||= []) << f
      end
    end
  end
  chosen = select_all ? matrix : matrix.select { |e| reasons.key?(e["fixture"]) }
  summary = if select_all
    ["all fixtures: #{select_all}"]
  elsif reasons.empty?
    ["no fixture selected: no changed path affects a fixture"]
  else
    reasons.map { |n, fs| "#{n}: #{fs.first}#{fs.size > 1 ? " (+#{fs.size - 1} more)" : ""}" }
  end
  result = { "matrix" => { "include" => chosen }, "has_fixtures" => !chosen.empty?, "summary" => summary }
  if ENV["TO_GITHUB"] == "1"
    File.open(ENV.fetch("GITHUB_OUTPUT"), "a") do |out|
      out.puts "matrix=#{JSON.generate(result["matrix"])}"
      out.puts "has_fixtures=#{result["has_fixtures"]}"
    end
    if ENV["GITHUB_STEP_SUMMARY"]
      File.open(ENV["GITHUB_STEP_SUMMARY"], "a") { |s| s.puts "### Fixture selection", *summary.map { |l| "- #{l}" } }
    end
  else
    puts JSON.generate(result)
  end
' "$MATRIX_FILE"
```
Run: `chmod +x scripts/ci-select-fixtures.sh tests/ci/test-select-fixtures.sh && ./tests/ci/test-select-fixtures.sh` → every line `ok`, last line `all selection tests passed`, exit 0. Commit (hand-off): `git commit -m "ci: add path-based fixture selection with unit tests"`.

- [ ] **Step 7: Create `.github/workflows/lint.yml`** (CI-4 skeleton; ubuntu only; runs on every PR):

```yaml
name: Lint

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]
  workflow_dispatch:

concurrency:
  group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}

jobs:
  ci-scripts:
    name: ci scripts
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - name: Fixture selection unit tests
        run: ./tests/ci/test-select-fixtures.sh
```
Validate: `ruby -ryaml -e 'YAML.load_file(".github/workflows/lint.yml")'`. **Unverified until it runs:** that `ruby` is preinstalled on `ubuntu-latest`. If the first run says `ruby: command not found`, add `- uses: ruby/setup-ruby@v1` (pin per the repo's convention) and report. Commit: `ci: add lint workflow for non-macOS checks`.

- [ ] **Step 8: Rewrite `.github/workflows/validate-fixtures.yml`.** Keep `on:` and `concurrency:` exactly as they are after #27. Replace everything from `jobs:` down to (not including) the `env:` of the `validate` job with:

```yaml
jobs:
  changes:
    name: changes
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.select.outputs.matrix }}
      has_fixtures: ${{ steps.select.outputs.has_fixtures }}
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0
      - name: Select fixtures
        id: select
        env:
          EVENT_NAME: ${{ github.event_name }}
          BASE_SHA: ${{ github.event.pull_request.base.sha }}
          HEAD_SHA: ${{ github.event.pull_request.head.sha }}
        run: ./scripts/ci-select-fixtures.sh --event "$EVENT_NAME" --base "$BASE_SHA" --head "$HEAD_SHA" --github-output

  validate:
    name: ${{ matrix.fixture }} (Tuist ${{ matrix.tuist }})
    needs: changes
    if: needs.changes.outputs.has_fixtures == 'true'
    runs-on: macos-15
    strategy:
      fail-fast: false
      matrix: ${{ fromJSON(needs.changes.outputs.matrix) }}
```
leaving the rest of the `validate` job (env, steps) untouched. Then append the aggregator job at the end of the file:

```yaml
  fixtures-ok:
    name: fixtures-ok
    if: always()
    needs: [changes, validate]
    runs-on: ubuntu-latest
    env:
      CHANGES_RESULT: ${{ needs.changes.result }}
      VALIDATE_RESULT: ${{ needs.validate.result }}
    steps:
      - name: Aggregate fixture results
        run: |
          echo "changes=$CHANGES_RESULT validate=$VALIDATE_RESULT"
          test "$CHANGES_RESULT" = "success"
          case "$VALIDATE_RESULT" in
            success|skipped) ;;
            *) exit 1 ;;
          esac
```
Check: `ruby -ryaml -e 'YAML.load_file(".github/workflows/validate-fixtures.yml")'` parses; `grep -n "runs-on" .github/workflows/validate-fixtures.yml` → `ubuntu-latest` ×2, `macos-15` ×1. Do NOT remove any step from the `validate` job (Verify Tuist pin, Resolve, Generate, Build, Test all stay).

- [ ] **Step 9: PR with the user action on top.** The PR description must **begin** with:

```text
ACTION REQUIRED (repo owner), in this order:
1. After this PR's own CI has run once (it changes the workflow, so it runs ALL fixtures and creates `fixtures-ok`),
   add `fixtures-ok` to the required status checks of `develop` (keep the 10 old fixture names for now).
2. Merge this PR.
3. Remove the 10 per-fixture checks from the required list, leaving `fixtures-ok`
   (optionally also `ci scripts` from the Lint workflow).
Until step 3, docs-only PRs wait on skipped per-fixture checks. Branch protection is not changed by this PR.
```
Then the acceptance evidence (hand-off, needs GitHub): open three throwaway draft PRs against this branch's base — (a) docs-only → 0 macOS jobs and `fixtures-ok` green; (b) one fixture file touched → only that fixture's job runs; (c) edit a comment in `validate-fixtures.yml` → all 10 run — and paste the run URLs, plus `scripts/ci-measure.py` output. Close the throwaway PRs afterwards (they are drafts for measurement only).

- [ ] **Step 10: Commit and PR** (hand-off)

```bash
git add tests scripts .github
git commit -m "ci: run only the fixtures a change affects and aggregate via fixtures-ok"
```

---

### Task 3: CI-3 — remove redundant compilation and pre-boot the simulator (conditional)

Branch: `ci/ci-3-fixture-time`. **Gate:** only proceed with each change if its Step-1 measurement supports it; otherwise write the measurement into the baseline doc and stop.

**Files:**
- Create: `scripts/ci-pick-simulator.sh`
- Modify: `.github/workflows/validate-fixtures.yml` (the `validate` job's steps), `scripts/ci-select-fixtures.sh` already lists `ci-pick-simulator.sh` as an "everything" path (Task 2)
- Modify: `docs/superpowers/ci/2026-10-baseline.md` (append "## 7. CI-3 evidence")

- [x] **Step 1 (done 2026-10-03, baseline §7): F6 reconfirmed on 4 jobs (gap 57–402 s, all > 30 s) → change 2 (pre-boot) proceeds.** Original instruction: Re-verify F6 on other fixtures (hand-off, needs `gh`). For `modular`, `architecture-smells` and `migrate-candidate`, take a recent successful job log (`gh run view --job <id> --log`) and record, per job: the timestamp of the last compile line in the Test step, the timestamp of `Test Suite 'All tests' started`, and the `IDETestOperationsObserverDebug: … elapsed` value. Baseline had one sample (extract-candidate: ~139 s gap). Write the three results into the baseline doc. **If the gap is < 30 s in all three, skip change 2 below** and report.

- [ ] **Step 2: Create `scripts/ci-pick-simulator.sh`** (moves the inline ruby from the Test step):

```bash
#!/bin/bash
# Prints the UDID of the first available iPhone simulator. Shared by the CI
# Test step and the early pre-boot step so both pick the same device.
set -euo pipefail
xcrun simctl list devices available --json | ruby -rjson -e '
  devices = JSON.parse(STDIN.read).fetch("devices").values.flatten
  iphone = devices.find { |device| device["isAvailable"] && device["name"].start_with?("iPhone") }
  abort "No available iPhone simulator found" unless iphone
  print iphone.fetch("udid")
'
```

- [ ] **Step 3: Pre-boot (change 2) — do this first; it is the primary change (likely larger than change 1's ≤ 29 s). Ship it as its own commit so its effect can be measured separately from Step 4.** Insert before `Resolve dependencies`:

```yaml
      - name: Pre-boot simulator
        run: |
          SIMULATOR_ID="$(./scripts/ci-pick-simulator.sh)"
          echo "SIMULATOR_ID=$SIMULATOR_ID" >> "$GITHUB_ENV"
          xcrun simctl boot "$SIMULATOR_ID" || true
```
**[검증 필요]** whether `simctl boot` returns before boot completes. Measure the step's duration in the PR run: if it blocks ~the whole boot, nothing is gained from "background" and the saved time is only the overlap with resolve/generate — report the real number. Before tests, wait for readiness: `xcrun simctl bootstatus "$SIMULATOR_ID" -b`.

- [ ] **Step 4: Merge Build into Test (change 1) — only if Step 1/baseline confirm the duplicate compile (they did for extract-candidate).** Replace the `Build` and `Test` steps with one step (keep a name that makes the App build visible):

```yaml
      - name: Build and test
        working-directory: tests/fixtures/${{ matrix.fixture }}
        env:
          TEST_SCHEMES: ${{ matrix.test_schemes }}
        run: |
          xcrun simctl bootstatus "$SIMULATOR_ID" -b
          for scheme in $TEST_SCHEMES; do
            xcodebuild build-for-testing \
              -workspace "${{ matrix.workspace }}.xcworkspace" \
              -scheme "$scheme" \
              -destination "id=$SIMULATOR_ID"
            xcodebuild test-without-building \
              -workspace "${{ matrix.workspace }}.xcworkspace" \
              -scheme "$scheme" \
              -destination "id=$SIMULATOR_ID"
          done
```
Every fixture's `test_schemes` begins with `App`, so the first `build-for-testing` is the App build. State this in the PR and, per fixture, show that the `App` scheme builds the `App` target (generated scheme file or `xcodebuild -list`; hand-off — needs `tuist generate`).

- [ ] **Step 5: Evidence (hand-off).**
  - Test counts: for every fixture compare `Executed N tests` (last occurrence per scheme) between a pre-change run (baseline logs) and the new run. Any difference is a failure to explain.
  - Intentional failure: on a throwaway commit add a compile error in `tests/fixtures/extract-candidate/App/Sources/…` and confirm that job fails; drop the commit.
  - Timing: `scripts/ci-measure.py <new-run-id>` vs the baseline: mean job time and the Test/Build lines.

- [ ] **Step 6: Commit** (hand-off): `ci: build once per scheme and pre-boot the simulator`.

---

### Task 4: CI-5 — weekly full run

Branch: `ci/ci-5-schedule`. Depends on Task 2.

**Files:** Modify `.github/workflows/validate-fixtures.yml` (`on:` block only).

- [ ] **Step 1: Add** under `on:`:

```yaml
  # Weekly full matrix: catches gaps in the path-selection rules in
  # scripts/ci-select-fixtures.sh. Kept separate from any "latest Tuist"
  # drift check (v0.9 WS-D): a failure here means a regression, not external change.
  schedule:
    - cron: "0 18 * * 0"
```
- [ ] **Step 2: Check:** YAML parses; `./tests/ci/test-select-fixtures.sh` still passes (it already asserts `schedule` selects all fixtures).
- [ ] **Step 3: Evidence (hand-off):** a real `schedule` event cannot be forced. Run `gh workflow run "Validate fixtures"` (workflow_dispatch → same "select all" branch) and show 10 fixture jobs + `fixtures-ok`. State in the PR that the `schedule` path itself is covered by the unit test and first real firing, and mark it "Unverified (first scheduled run pending)".
- [ ] **Step 4: Commit** (hand-off): `ci: add weekly full fixture run`.

---

### Task 5: CI-6 — concurrency-limit decision (measure first; may produce only a document)

Branch: `ci/ci-6-concurrency` — create only if the decision needs code.

- [ ] **Step 1: Measure after Task 2 landed** (hand-off): `scripts/ci-measure.py` over ≥ 3 runs of each kind — a docs-only PR (no jobs; record wall time of `changes`+`fixtures-ok`), a 1-fixture PR, and a `develop` push (all 10). Append "## 8. After CI-2" to the baseline doc.
- [ ] **Step 2: Decide using the PRD's options (spec §CI-6):** (a) keep as is if PR runs now rarely exceed 2 macOS jobs and the remaining queue is only on `develop`/scheduled full runs; (b) bundle small fixtures only if (a) fails *and* the measured per-job fixed cost (checkout + mise + simulator boot) is a large share of job time; (c) tune `max-parallel` only if the full-matrix run starves other workflows. Record the choice, the numbers behind it, and the plan limit if it can be verified from GitHub's docs (**[검증 필요]**, currently unknown).
- [ ] **Step 3:** If (b) is chosen, a separate plan is needed (failure isolation and summary requirements are in the spec); stop and report instead of improvising.
- [ ] **Step 4: Commit the document** (hand-off): `docs: record CI-6 concurrency decision`.

---

## Self-review (writer's)

- **Spec coverage:** CI-0 → done by Claude (baseline doc) + Task 1 helper/after-numbers; CI-1 → Task 1 (verification of #27); CI-2 → Task 2 (selection rules table, `ci-matrix.json`, `$GITHUB_STEP_SUMMARY` output, `fixtures-ok`, user action with exact order, unit tests); CI-3 → Task 3 (gated on measurement; change order reflects baseline: pre-boot is the larger saving); CI-4 → `lint.yml` skeleton in Task 2 + v0.8 WS3 job placement; CI-5 → Task 4; CI-6 → Task 5.
- **Decisions made here:** selection falls back to *all* fixtures when the diff cannot be computed; required-check switch happens in two phases so merges never block; `ci-matrix.json` is the single matrix source for the workflow, the local validator and v0.8's pin check.
- **Open items:** macOS slot limit (unverified); whether `simctl boot` is non-blocking (Task 3 Step 3); `ruby` on `ubuntu-latest` (first `Lint` run); v0.9 WS-A/WS-B will need their sync/script paths added to the "everything" list in `scripts/ci-select-fixtures.sh` (spec open question 3).
