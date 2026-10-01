# Handoff to Codex — CI speedup

## Why you're getting this

Per this repo's ownership split (see `2026-09-20-HANDOFF-TO-CODEX-v0.6.md`),
Codex implements; the Claude session produced the spec, the plan and the CI-0
measurements only. **Do this before any v0.8 work** — v0.8 Task 3 depends on it.

## Read, in order

1. Spec: `docs/superpowers/specs/2026-10-02-ci-speedup-design.md`
2. Baseline measurements: `docs/superpowers/ci/2026-10-baseline.md`
3. Plan: `docs/superpowers/plans/2026-10-02-ci-speedup.md` (task-by-task, exact code)
4. This file.

## What the measurements say (facts, n small)

Queue wait averages 13.6 min (max 37.5) vs 4.9 min job runtime; the Test step
is 242 s of a 293 s job; the Build step is 29 s. So reducing the **number of
macOS jobs** (Task 2) matters far more than shaving compile time (Task 3).

## State and order

- Prerequisite: PR #27 (`ci/reduce-duplicate-runs`: push only on main/develop +
  concurrency) merged, and PR #28 (docs, includes this plan) merged. If either is
  not merged, stop and report.
- Tasks: 1 (verify #27, add `scripts/ci-measure.py`) → 2 (path selection,
  `fixtures-ok`, `lint.yml`) → 3 (conditional, measurement-gated) → 4 (weekly
  schedule) → 5 (CI-6 decision, possibly document only). One PR per task, branch
  `ci/<id>` from `develop`.
- The selection script and its 13-case unit test in Task 2 were run once by
  Claude in a scratch directory (all passed, including real `git diff base...head`
  and the "diff fails → select all" fallback). That is evidence the code in the plan
  is sound, **not** a substitute for running it in the repo.

## What you cannot do (hand to Claude/user)

`git commit`/push, anything needing `gh` or GitHub (run URLs, logs, throwaway
PRs), `xcodebuild`/`tuist`/`mise`. Print the exact command, wait for the pasted
output. Never write "passes" without output; mark the rest "Unverified".

## Do NOT

- Change branch protection. Task 2 Step 9 gives the user the exact ordered steps
  (add `fixtures-ok`, merge, then drop the 10 per-fixture checks).
- Remove or skip any step of the macOS `validate` job, or any fixture from the matrix.
- Re-introduce self-hosted runners, add Tuist/SPM caching, or touch skill content.
- Merge Task 3 changes without the evidence listed in its Step 5 (same test counts,
  intentional-failure check, before/after timing).

## Account / delivery

Personal account `doulos76`; `origin` is HTTPS with a repo-local `gh` credential
helper — don't switch to SSH or touch global git config (see
`2026-10-02-HANDOFF-TO-CODEX-v0.8.md`). `develop`/`main` are branch-protected; PR
required, and the branch must be up to date with `develop` (every
`gh pr update-branch` restarts CI — avoid pushing extra commits late).

## Ledger template

```text
Task | Branch | PR | Verified (what ran) | Unverified | Before/after numbers
```
