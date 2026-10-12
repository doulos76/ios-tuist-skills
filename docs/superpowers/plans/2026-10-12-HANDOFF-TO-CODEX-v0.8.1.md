# Handoff to Codex — ios-tuist-skills v0.8.1 (version-evidence follow-ups)

## Why you're getting this

Codex owns implementation; the Claude session produced research + plan
only. Nothing in the plan is implemented yet.

## Read, in order

1. Issues #47 and #48 with their research comments (the evidence).
2. Plan: `docs/superpowers/plans/2026-10-12-ios-tuist-skills-v0.8.1.md`
   (exact replacement text and grep checks for every task).
3. This file.

If the plan and an issue's research comment conflict, the comment wins;
report the conflict and stop.

## Where things stand

- Base: `develop` at `84fa328` (v0.8.0 released, tag `v0.8.0` on main
  `0a12044`).
- Research is done; the `.tuist-version` priority is a user decision
  (conditional source #3). Do not re-open it.
- The plan's replacement blocks were dry-run against `84fa328` on
  2026-10-12: every "replace" block matched exactly once and all grep
  checks failed before and passed after. If a block no longer matches,
  `develop` moved; stop and report rather than improvising text.

## Scope

Tasks 1-3 only (two files under `references/` and `skills/`, plus
`CHANGELOG.md`), on branch `fix/v0.8.1-version-evidence`, one commit per
task. Task 4 (release) is Claude + user.

Out of scope (report, don't fix): any other wording in
`version-safety.md`; fixtures, `EXPECTATIONS.md`, scripts, CI; the
`[0.8.0]` CHANGELOG section.

## What you cannot do in your sandbox (hand to Claude / the user)

| Needs a hand-off | Where |
|---|---|
| `git commit` | Task 1 Step 8, Task 2 Step 6, Task 3 Step 5 |
| `git push`, `gh pr create` | Task 3 Step 6 |

No `mise`/`tuist`/`xcodebuild` run is needed: the change is docs-only
and CI's fixture jobs are the guard. Anything not run goes under
"Unverified" in the PR body; never write "passes" without the output.

## Delivery mechanics

Same as `2026-10-02-HANDOFF-TO-CODEX-v0.8.md` § Delivery mechanics:
branch protection on `develop`/`main`, personal account `doulos76` over
HTTPS, don't change branch protection or global git config.
