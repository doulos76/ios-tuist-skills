# Handoff to Codex — ios-tuist-skills v0.8 implementation

## Why you're getting this

Per this repo's ownership split (see
`docs/superpowers/plans/2026-09-20-HANDOFF-TO-CODEX-v0.6.md`), Codex owns
implementation. The Claude session for v0.8 produced spec + plan only —
no implementation was attempted. You start Task 1 from a clean slate.

## Read, in order

1. **Spec** (authoritative for rationale and acceptance criteria):
   `docs/superpowers/specs/2026-10-01-ios-tuist-skills-v0.8-design.md`
   (the PRD; §0 holds the working rules: verify evidence first, one
   workstream per branch, no scope creep).
2. **Plan** (task-by-task steps, exact replacement text, exact commands):
   `docs/superpowers/plans/2026-10-02-ios-tuist-skills-v0.8.md`
3. **This file** — repo state, delivery mechanics, and what Codex cannot
   do itself.

If the plan and the spec conflict, the spec wins; report the conflict.

## Where things stand

- Base: `develop` at `492fd7e` (v0.7.1) plus one docs commit that adds
  the three files listed above. Nothing from the v0.8 plan is
  implemented.
- The docs commit is on branch `docs/v0.8-spec-plan` and is **not
  pushed**. Until it is merged to `develop`, cut your feature branches
  from `docs/v0.8-spec-plan` (or ask the user to merge it first —
  preferred, so feature branches start from `develop` as the plan says).
- Evidence for WS1–WS6 was re-verified against `492fd7e` on 2026-10-02
  and matched the PRD (details in the plan's "Execution notes"). Still
  re-check each task's evidence before editing; if a file differs from
  what the plan quotes, stop and report.

## Delivery mechanics

- `main` and `develop` are branch-protected (confirmed in the v0.6
  handoff; re-check with `gh api repos/doulos76/ios-tuist-skills/branches/develop/protection`
  if in doubt): no direct pushes; PR into `develop`; required fixture CI
  jobs must pass.
- One branch + one PR per workstream: `feature/v0.8-ws1` … `ws7`, then
  `chore/release-0.8.0`. Order: WS1 → WS2 → WS3 → WS4 → WS5 → WS6 → WS7;
  WS6 needs WS3 merged first.
- **Required status checks are a manual list on the protection rule.**
  Task 3 adds a new `check-pins` job; it will not gate merges unless the
  user adds it to the rule. Do not change branch protection yourself —
  ask the user.
- CI is GitHub-hosted now (`runs-on: macos-15` in the workflow; the repo
  is public). The self-hosted-runner and "Actions credit exhausted"
  notes in the v0.6 handoff and older memory are outdated. Don't rely on
  them, and check the workflow file if a job looks stuck.

## What you cannot do in your sandbox (hand these to Claude / the user)

Codex `workspace-write` cannot `git commit`, nor run `mise`, `tuist` or
`xcodebuild`. For these, stop and print the exact command for Claude or
the user to run, then continue from their pasted output:

| Needs a hand-off | Where in the plan |
|---|---|
| `git commit` (every task's last step) | all tasks |
| `./scripts/validate-fixtures-locally.sh <fixture>` | Task 1 Step 8, Task 3 Step 7, Task 8 Step 1 |
| `claude` runs: description routing test, benchmark acceptance run | Task 4 Step 7, Task 6 Step 7 |
| `codex plugin marketplace add …` acceptance | Task 7 Step 6 |

Anything not actually run is reported as "Unverified" in the PR body.
Never write "passes" without the pasted output.

## Research gates (do not answer from memory)

| Gate | Task | If the source disagrees with the PRD |
|---|---|---|
| Is `Package.swift` / `Tuist/Package.swift` a Tuist **CLI** version source? | Task 2 Step 1 | Stop; report; keep the source and link the doc |
| Additional mise config paths | Task 2 Step 1 | Include only what the mise docs confirm |
| Max `description` length (Agent Skills spec) | Task 4 Step 1 | If unconfirmable, ≤ 500 chars and mark Unverified |
| Codex plugin/marketplace manifest spec | Task 7 Step 1 | Defer WS7 to v0.8.x; don't guess field names |

## Judgment calls already made (change only with the user's OK)

- Emptied original test target after a module extraction: **report only,
  never delete** (PRD open question 4).
- `ci-gaps`: adding `.tool-versions` `tuist 4.206.0` is safe — its
  EXPECTATIONS says no pin mismatch is intended (PRD open question 3).
- Benchmark harness is `prep` + `collect` subcommands so no unverified
  `claude` flags are baked in.
- `check-pins` is its own ubuntu job, not a step in the macOS matrix.

## Out of scope (do not do)

New skills (`ios-tuist-adopt`), external decision-model integration,
relaxing `ios-tuist-ci`'s "never remove a validation step", re-running
all 14 baseline measurements, editing any existing benchmark score
(footnote only, Task 8).

## Finish line

Every PR body carries the verification output (or "Unverified"). After
Tasks 1–5 (and 6/7 if ready) are merged and CI is green, do the release
task. Merging `develop` → `main` and cutting a GitHub Release is the
user's decision; bring it back to them rather than doing it.

## Ledger template (copy into your progress notes)

```text
Task | Branch | PR | Verified (what ran) | Unverified | Notes
1    |        |    |                     |            |
...
```
