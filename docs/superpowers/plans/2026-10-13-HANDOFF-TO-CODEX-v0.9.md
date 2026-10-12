# Handoff to Codex — ios-tuist-skills v0.9 implementation

## Why you're getting this

Codex owns implementation; the Claude session produced research and the
plan only. Nothing in the plan is implemented yet.

## Read, in order

1. Spec (PRD): `docs/superpowers/specs/2026-10-02-ios-tuist-skills-v0.9-design.md`
   (§0 working rules apply).
2. Plan: `docs/superpowers/plans/2026-10-13-ios-tuist-skills-v0.9.md`.
   Its "Deviations from the PRD" section was approved by the user on
   2026-10-13 and wins over the PRD; any other conflict: stop and report.
3. This file.

## Where things stand

- Base: `develop` after this docs PR merges (v0.8.1 = `a1dacba`).
- Research gates answered on 2026-10-13 (sources in the plan's
  Deviations 2 and 4): `${CLAUDE_SKILL_DIR}`; skill selection observable
  as a stream-json `Skill` tool_use (experiment, undocumented); no skill
  event in `codex exec --json`; `mise latest aqua:tuist/tuist`.
- Every task section was dry-run on a copy of `a1dacba` while drafting:
  replacement blocks matched exactly once and the tests failed before
  and passed after. If a block no longer matches, `develop` moved — stop
  and report rather than improvising text.

## Order

Task 1 (WS-H) → Task 2 (WS-A) → Task 3 (WS-B) → Task 4 (WS-E);
Task 5 (WS-C) is independent; Task 6 (WS-D) after Task 3; Task 7 release
is Claude + user. One branch `feature/v0.9-ws-<id>` and one PR per task.

## What you cannot do in your sandbox

`git` (any command), network, `gh`, `mise`, `tuist`, `xcodebuild`,
`claude`. Steps marked **[hand-off]** print the exact command for Claude
or the user; continue from the pasted output. Anything not run goes under
"Unverified" in the PR body; never write "passes" without the output.

## Delivery mechanics

As in `2026-10-02-HANDOFF-TO-CODEX-v0.8.md` § Delivery mechanics. Branch
protection: `develop` and `main` require `fixtures-ok` and `ci scripts`
(main changed to this on 2026-10-13). Don't change branch protection.
