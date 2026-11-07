# ios-tuist-skills v0.9.2 Implementation Plan

> **Implementation owner: Codex.** Claude wrote this plan. Codex's `workspace-write`
> sandbox cannot `git commit`, reach the network, or run `mise`/`tuist`/`xcodebuild`/`claude`/`codex`.
> Steps marked **[hand-off]** are run by Claude or the user; Codex continues from their pasted output.
> Steps marked **[Claude]** are research, paid runs or writing done by Claude.

**Goal:** Close the four open v0.9.1 follow-ups: `.external` edges in the edge check, the new-test-target CI scheme gap, the invalid Claude dependency output block, and the three routing misses.

**Base:** `develop` at `9604fbf` or later. One branch and one PR per task into `develop`.

**Spec / evidence:**
- `docs/superpowers/benchmarks/2026-11-05-large-graph-trial/README.md` (scheme gap :29, Findings #4; dependency run 2 invalid)
- `docs/superpowers/benchmarks/2026-10-31-routing/` (baseline 42/45 at $0.60)
- `CHANGELOG.md` 0.9.1 "Known limitations"
- `docs/superpowers/plans/2026-10-16-ios-tuist-skills-v0.9.x.md` (format, Task 5 run commands :1570-1586)

## User decisions (2026-11-07)

- Routing: **diagnose first**; change a `description:` only if the diagnosis shows a real routing failure.
- Scheme gap: skills **detect and report**; they never edit CI files.

## Order

| # | Task | Branch | Cost |
|---|---|---|---|
| 0 | This plan + HANDOFF | `docs/v0.9.2-plan` | 0 |
| 1 | `.external` edges | `feature/v0.9.2-external-edges` | 0 |
| 2 | Test-scheme gap report | `feature/v0.9.2-test-scheme-gap` | 0 (optional smoke ≤ $3) |
| 3 | Dependency scenario rerun | `docs/v0.9.2-dependency-rerun` | ≤ $9 (+ ≤ $9 if a fix is needed) |
| 4 | Routing miss diagnosis | `docs/v0.9.2-routing-diagnosis` | ≤ $10.80 (+ ≤ $27 full rerun, separate approval) |
| 5 | Release 0.9.2 | `chore/release-0.9.2` | 0 |

Tasks 1 and 2 are independent. Task 3 should follow Task 2 only if Task 2 touches `ios-tuist-dependency` (it does not by plan). Task 4 is independent. Paid runs (3, 4) need the user's go-ahead (Max plan usage).

## Global constraints

- Bash 3.2 and Ruby 2.6 stdlib only. Run every test also with `PATH=/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin`.
- Edit `scripts/skill/*` and root `references/*` only; regenerate copies with `scripts/sync-skill-resources.sh`.
- Before committing each task, run `git check-ignore -v <new files>`; dry runs on `git archive` copies miss `.gitignore` effects.
- Unrequested refactors, formatting and dependencies are out of scope.
- Anything not run goes under "Unverified" in the PR body.

---

## Task 1: `.external` edges in `check-consumer-edges.sh`

**Files:** `scripts/skill/check-consumer-edges.sh`, generated copies under `skills/ios-tuist-{module,dependency}/scripts/`, `tests/golden/test-consumer-edges.sh`, new `tests/golden/consumer-edges/external-{usage,no-usage}/`, `skills/ios-tuist-dependency/SKILL.md` (~:94-103), `skills/ios-tuist-module/SKILL.md` (~:127-135), `CHANGELOG.md`, `tests/fixtures/large-graph/EXPECTATIONS.md` (~:99-100).

- [ ] **Step 1: Failing golden cases first.** Add `external-usage` (after-overlay adds `.external(name: "LogKit")` to a target plus `import LogKit` in its sources) and `external-no-usage` (edge only) on top of `tests/fixtures/extract-candidate`, with `expected.json`. Add both names to the loop in `tests/golden/test-consumer-edges.sh` (:14). Run the test: it must **fail** (the edge is not reported).
- [ ] **Step 2: Parse `.external`.** After the `.project(target:` scan (~:98) add a scan for `.external(name: "X")`. Report it as an added/removed edge with `kind: external`. Add `kind` (`target|project|external`) to every edge. Before choosing the JSON schema version: `grep -rn "ios-tuist-consumer-edges" .` — if no consumer breaks on an extra field, keep `/1`; otherwise bump to `/2` and update the consumers. Record the choice in the PR.
- [ ] **Step 3: Usage lookup by name only.** Search `import <name>` in the consumer's source folders. No product-to-module inference. When nothing is found, print `no usage found (external: product name may differ from module name)`.
- [ ] **Step 4: Sync + tests.** `scripts/sync-skill-resources.sh`; run `scripts/run-golden-tests.sh` (ruby 3 and 2.6), `tests/skills/test-sync-skill-resources.sh`, `test-self-containment.sh`, `test-standalone-copy.sh`. Golden cases now pass; show the before/after output.
- [ ] **Step 5: Skill text.** Dependency SKILL step 9: drop "(local targets and projects only)", add `.external(name:)` to the covered edge kinds, replace "Package product dependencies are not covered" with the name-mismatch caveat. Module SKILL ~:127-135: same. Update CHANGELOG and the EXPECTATIONS known-limit wording. Do not change any `description:`.
- [ ] **Step 6: [hand-off]** Claude commits, opens the PR.

## Task 2: Report new test targets missing from CI test schemes

**Files:** root `references/testing.md` (+ manifest registration), `skills/ios-tuist-module/SKILL.md`, `skills/ios-tuist-test-target/SKILL.md`, `tests/fixtures/large-graph/EXPECTATIONS.md`, `CHANGELOG.md`.

- [ ] **Step 1: [Claude] Establish facts.** In a scratch copy of `tests/fixtures/large-graph`: `tuist generate`, `xcodebuild -list`, then see which scheme's testAction contains `CheckoutFeatureTests`. Also check whether `tuist test` with no scheme runs every test target (Tuist docs or actual run). Paste the output; record it in the PR. These facts decide whether `ios-tuist-test-target/SKILL.md` :138-157 ("default scheme already includes the new test target") must be corrected. Until then it is **unconfirmed**; Evidence 3 of the v0.9.x plan says test targets have no scheme of their own.
- [ ] **Step 2: Shared procedure** in root `references/testing.md` (one place): after a new test target exists, find the CI test-scheme list (`.github/workflows/*.yml`, `fastlane/Fastfile`, `scripts/`, matrix JSON; patterns `-scheme`, `tuist test`, `test_schemes`), decide whether a listed scheme runs the new target, and if not report it with `file:line` under Unverified and Risks / Follow-up, and in the result block's `unverified`. Never edit CI files. If no CI definition is found, report "CI test scheme list not found".
- [ ] **Step 3: Wire it.** Reference the procedure from the module skill's validation section and the test-target skill's scheme step. Correct the :138-157 claim per Step 1. Register `testing.md` for `ios-tuist-module` in `scripts/skill-resources.manifest` if absent; run the sync.
- [ ] **Step 4: Fixture expectation.** Scenario 1 "Expected behavior": a moved test target outside the CI schemes is reported.
- [ ] **Step 5: Tests.** golden + skills tests green (including self-containment: references must resolve inside the skill folder).
- [ ] **Step 6: [Claude, optional, ≤ $3]** One module scenario 1 run (command as in the v0.9.x plan Task 5 Step 1) to see whether the report appears. N=1 evidence only; say so.

## Task 3: Rerun the Claude dependency scenario

- [ ] **Step 1: [Claude]** Scenario 2 prompt from `tests/fixtures/large-graph/EXPECTATIONS.md` (:89), runs **4, 5, 6**, same command as the v0.9.x plan (`--permission-mode acceptEdits --allowedTools "Read Grep Glob Bash" --max-budget-usd 3 --output-format json`), new `BENCH_DIR` `2026-11-xx-dependency-rerun`. Record each `Block:` line from `parse-skill-result.sh`.
- [ ] **Step 2: Decide.** 3/3 valid → document as one-off, no skill change. Any invalid → Step 3.
- [ ] **Step 3: [hand-off, conditional]** In `skills/ios-tuist-dependency/SKILL.md` "Machine-readable result": state that the Example above is human-readable sections, not block keys, and inline the eight-key skeleton from `references/output-contract.md:35-44`. Dependency skill only. Then **[Claude]** runs 7-9 (≤ $9) and records block validity.
- [ ] **Step 4:** README in the benchmark dir (columns as in the 2026-11-05 trial), footnote link from the trial README.

## Task 4: Routing miss diagnosis

Context: all three misses (`pos-feature-ko`, `adj-feature-not-module`, `pos-scaffold-en`) selected no skill and ended `error_max_budget_usd`; no wrong-skill picks.

- [ ] **Step 1: [Claude]** Three runs, new `--out` each:
  `scripts/run-routing-eval.sh run --condition plugin-only --only pos-feature-ko,adj-feature-not-module,pos-scaffold-en --budget 1.20 --out <dir>`
  (≤ 9 × $1.20). After each run check `plans-created.txt` and remove the plan files it lists from `~/.claude/plans`.
- [ ] **Step 2: Decide per case (hits out of 3).** All ≥ 2/3 → cause is budget; record in `COMPARISON.md`, no description change; present the `--budget` default question to the user. Any < 2/3 → draft a more concrete "Use when" for that skill only, and **ask the user before** the full 45-case rerun (≤ $27) that README :262-264 requires.
- [ ] **Step 3:** Save under `docs/superpowers/benchmarks/2026-11-xx-routing-diagnosis/`, judge with the pass rule (README :266-269).

## Task 5: Release 0.9.2

- [ ] `CHANGELOG.md` 0.9.2, `.claude-plugin/plugin.json` version, PR into `develop`, then `develop` → `main`. Wait for **all** checks (fixtures-ok can pass early from the skipped matrix). Tag `v0.9.2` and the GitHub Release only after the user approves.

## Verification summary

Every PR: `scripts/run-golden-tests.sh`, `tests/skills/*.sh`, `scripts/check-routing-cases.sh`; required checks fixtures-ok, ci scripts, golden tests, skill resources green. Task 1: new golden cases fail before, pass after. Task 2: `xcodebuild -list` output as evidence. Tasks 3-4: `parse-skill-result.sh` output and routing `summary.md` committed.
