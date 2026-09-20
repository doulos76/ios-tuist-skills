# Handoff to Codex — ios-tuist-skills v0.6 implementation

## Why you're getting this

Per this repo's ownership split (see the `feedback_implementation_ownership`
memory, and the pattern already established in
`docs/superpowers/plans/2026-09-20-HANDOFF-TO-CODEX-v0.5.md`), Codex owns
implementation of `ios-tuist-skills`. The Claude session for v0.6 produced
spec + plan only and stopped — no implementation was attempted. You are
starting Task 1 from a clean slate.

## What you need to read, in order

1. **Spec** (binding authority for every decision below):
   `docs/superpowers/specs/2026-09-20-ios-tuist-skills-v0.6-design.md`
2. **Plan** (the argument from the spec — task-by-task steps, exact file
   contents, exact commands):
   `docs/superpowers/plans/2026-09-20-ios-tuist-skills-v0.6.md`
3. **This file** — the current repo state, one important API-accuracy
   fact caught during this plan's own self-review, and the branch
   protection change that landed since v0.5 shipped.

The plan is the primary artifact to execute from — it already contains
every task's full file contents, verification commands, and commit
messages. Treat the spec as authoritative if you ever find the plan
ambiguous or in conflict with it.

## Where things stand

- **Working directory:** no separate worktree required — work directly
  on `develop` in the main checkout
  (`/Users/dave/Documents/GitHub/ios-tuist-skills`), or a feature branch
  off it (see "Branch protection" below — a feature branch is required
  either way now).
- **HEAD is `1a7f659`** (`Merge pull request #8 from
  doulos76/docs/v0.6-scaffold-plan`). Nothing from the v0.6 plan has
  been implemented yet — start Task 1 from here.
- **Working tree is clean** (`git status --short` prints nothing).
- **Push state:** unlike v0.5's handoff, `origin/develop` and local
  `develop` are already in sync at `1a7f659` — the spec and plan are
  both already pushed and merged (PR #7, PR #8). You do not need to
  catch up any unpushed local-only commits; you're starting from a
  state that already matches `origin/develop`.

```
1a7f659 (HEAD, develop, origin/develop) Merge pull request #8 from doulos76/docs/v0.6-scaffold-plan
95a7016 docs: add v0.6 implementation plan for ios-tuist-scaffold skill
6310843 Merge pull request #7 from doulos76/docs/v0.6-scaffold-spec
fd90d4d docs: add v0.6 design spec for ios-tuist-scaffold skill
14d785f Merge pull request #5 from doulos76/feature/ios-tuist-test-target
```

## Branch protection is now on — this changes how you deliver work

**New since v0.5 shipped, not mentioned in the v0.5 handoff:** `main`
and `develop` both now have GitHub branch protection enabled:

- Direct `git push` to `main` or `develop` is rejected.
- A pull request is required to merge into either branch. Required
  approving review count is 0 (solo-maintainer repo), so you (or the
  user) can merge your own PR once CI is green — no separate human
  reviewer is required, but the PR mechanism itself is not optional.
- All 9 existing fixture CI jobs (`legacy-tuist`, `modular`,
  `version-mismatch`, `extract-candidate`, `architecture-smells`,
  `ci-gaps`, `migrate-candidate`, `restyle-candidate`,
  `test-target-candidate`) are required status checks — a PR cannot
  merge until every one of them passes on the PR's head commit.
- Force-pushes and branch deletion are blocked on both `main` and
  `develop`.

**Practical implication for this plan:** work on a feature branch (e.g.
`feature/ios-tuist-scaffold`), push it, open a PR into `develop`, and
wait for the 9 (soon to be 10, once Task 3 lands the new fixture) CI
jobs to go green before merging — the same delivery shape v0.5 actually
used in practice (see PR #5), even though the v0.5 plan file itself
predates the branch-protection setup and doesn't mention it. Do not
attempt a direct `git push origin develop` — it will be rejected by
GitHub, not by a bug in your tooling.

**Also note:** if `tests/fixtures/scaffold-candidate` is added as
Task 3's new matrix entry, that job (`scaffold-candidate (Tuist
4.206.0)`) is **not yet a required status check** — required checks are
a manually-configured list on the branch protection rule, not
auto-derived from the workflow file. If you want the new fixture job to
gate merges the same way the other 9 do, that's a manual
`gh api -X PUT repos/doulos76/ios-tuist-skills/branches/<branch>/protection`
update the user needs to make (or explicitly delegate) — don't attempt
to change branch protection settings yourself without asking, since
that's a shared-infrastructure change outside this plan's scope.

## What's left: Tasks 1–5, all of them

Nothing has been implemented. Full detail is in the plan file. Summary:

| Task | What it does | Depends on |
|---|---|---|
| 1 | `skills/ios-tuist-scaffold/SKILL.md` (new skill) | nothing new — reads `references/source-of-truth.md`, `references/version-safety.md` |
| 2 | `tests/fixtures/scaffold-candidate/` fixture (minimal buildable Tuist project + one committed `feature` scaffold template under `Tuist/Templates/feature/`) | Task 1 only conceptually — no code dependency |
| 3 | Extend `.github/workflows/validate-fixtures.yml` matrix with the new fixture | Task 2 |
| 4 | Update `README.md`, `CHANGELOG.md`, bump `.claude-plugin/plugin.json` to `0.6.0` | Tasks 1–3 |
| 5 | Final spec-compliance sweep against spec §7's acceptance checklist | Tasks 1–4 |

Tasks 1 and 2 have no code dependency on each other and could be done in
either order, but the plan lists them 1-then-2 and there's no reason to
deviate.

## One fact worth double-checking as you implement Task 1 and Task 2

This plan's own self-review (before it was committed) caught a real API
gap: `Template.Item.file(path: String, templatePath: Path)`'s `path:`
argument is a **plain Swift `String`, not rendered through Stencil**.
Tuist's own documented pattern for a dynamic output file name is
ordinary Swift string interpolation of the attribute *inside the
manifest* — `path: "Sources/\(nameAttribute)Label.swift"` — not
`{{ name }}` syntax inside `path:`. `{{ attributeName }}` substitution
is verified only for **`.stencil` file contents** (the file at
`templatePath:`), never for `path:` itself.

Both the spec (small patch, already merged) and the plan's Task 1/Task 2
content reflect this correctly as written. If your own tooling/testing
during implementation disagrees with this — e.g. you find `{{ }}` in
`path:` actually does get rendered on the Tuist version this repo
pins (4.206.0) — re-verify against real `tuist scaffold` behavior
(don't just trust the plan or this note blindly) and flag the
discrepancy in your ledger/progress notes rather than silently changing
which mechanism you use. The plan's Task 1 Step 5 and Task 5 Step 1
both include `grep` checks that fail loudly (`UNEXPECTED: {{ }}
syntax used inside a path: string`) if this boundary gets violated
anywhere in the skill doc or fixture — don't relax those checks to make
them pass if you hit this discrepancy; investigate and report instead.

## A second fact worth double-checking: Stencil syntax scope

The spec and plan are both explicit that this skill's `.stencil` files
must use **substitution only** (`{{ attributeName }}`) and never
Stencil's control-flow syntax (`{% for %}`, `{% if %}`, filters) — not
because control-flow syntax doesn't work in Tuist's Stencil integration
(it likely does; Stencil is a real templating engine), but because this
plan's authors did not independently verify that specific behavior
against Tuist's documentation before writing the plan, per this
project's fact-verification discipline (don't assert what wasn't
checked). If a real task later needs conditional/repeated `.stencil`
content, that's grounds for a future skill enhancement with its own
verification pass — not something to quietly add to this plan's scope
now.

## Verification bar (unchanged from prior milestones)

Every task's fixture work must be validated for real — `tuist install`,
`tuist generate --no-open`, `xcodebuild build`, and the relevant
`xcodebuild test` schemes, actually run, actual output checked. For
Task 2 specifically, this also means actually running `tuist scaffold
feature --name Sample` in a **scratch copy** of the fixture (never the
committed tree — see Plan Task 2 Steps 8–9) and inspecting the generated
file's content character-for-character, not just checking the command's
exit code. "Files look right" is never sufficient, per this repo's own
skills' Output Contract standard (see any `skills/ios-tuist-*/SKILL.md`'s
Validation section for the pattern you're building tooling to enforce
on others — hold your own implementation to the same bar).

## Unrelated context carried over from v0.5 (still true)

- GitHub Actions CI still runs on a self-hosted runner
  (`~/actions-runner-ios-tuist-skills/`, a macOS LaunchAgent service),
  not GitHub-hosted `macos-15` — this remains a temporary measure until
  this private repo's Actions minutes situation changes or the repo
  goes public (see `.github/workflows/validate-fixtures.yml`'s
  `runs-on:` comment). If a workflow run you triggered appears stuck in
  `queued` for more than a minute or two on this Mac, that's usually the
  LaunchAgent service, not a workflow/YAML bug — ask the user rather
  than debugging the workflow file. It has also been observed, once, to
  mark a job `failure` after a mid-run service restart even though every
  step in that job's log actually succeeded — if you hit a
  same-shape anomaly (all steps green, job conclusion red), a
  `gh run rerun --failed` on just the affected job(s) is the known fix,
  not a code change.
- v0.5 shipped a GitHub Release (`v0.5.0`) after `develop` was merged to
  `main`. Whether/when v0.6 gets the same `main` merge + release
  treatment is the user's call once this plan's Tasks 1–5 are done and
  merged to `develop` — not something to do unilaterally as part of
  this plan.

## When Tasks 1–5 are done

Follow the plan's own closing note and the spec's acceptance criteria
(spec §7) as the finish line. Open a PR from your feature branch into
`develop` (branch protection requires this — see above), wait for all
required fixture CI jobs to pass, and merge. Whether to also merge
`develop` into `main` and cut a release afterward is a decision to bring
back to the user, not something to do unilaterally, consistent with how
v0.5 was finished.
