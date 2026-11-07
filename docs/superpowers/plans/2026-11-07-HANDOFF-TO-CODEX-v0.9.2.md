# Handoff to Codex — ios-tuist-skills v0.9.2 implementation

## Why you're getting this

Codex owns implementation; the Claude session produced research and the
plan only. Nothing in the plan is implemented yet.

## Read, in order

1. Plan: `docs/superpowers/plans/2026-11-07-ios-tuist-skills-v0.9.2.md`
   (its "User decisions" section wins on scope).
2. This file.

## Your tasks

- **Task 1** (`.external` edges) and **Task 2** (test-scheme gap report) are yours.
  They are independent; one branch `feature/v0.9.2-*` and one PR each.
- Task 2 Step 1 and Step 6 are **[Claude]**: wait for the pasted
  `xcodebuild -list` / `tuist test` output before editing
  `skills/ios-tuist-test-target/SKILL.md` :138-157. Do not decide that
  claim from memory.
- Task 3 (dependency rerun), Task 4 (routing diagnosis) and Task 5
  (release) are Claude + user. Do not start them.
- Only Task 3 Step 3 (conditional SKILL.md fix) may come back to you.

## Rules

- Edit `scripts/skill/*` and root `references/*` only; run
  `scripts/sync-skill-resources.sh` for the copies.
- Do not change any skill `description:`.
- Golden cases must fail before the fix and pass after; show both outputs.
- Run `git check-ignore -v` on every new file you add.
- If a line range in the plan no longer matches, `develop` moved: stop and report.

## What you cannot do in your sandbox

`git` (any command), network, `gh`, `mise`, `tuist`, `xcodebuild`,
`claude`. Steps marked **[hand-off]** print the exact command for Claude
or the user; continue from the pasted output. Anything not run goes under
"Unverified" in the PR body; never write "passes" without the output.
