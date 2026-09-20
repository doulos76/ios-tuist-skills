# Handoff to Codex — ios-tuist-skills v0.5 implementation

## Why you're getting this

Per this repo's ownership split (see [[feedback_implementation_ownership]]
in the user's memory, and the pattern already established in
`.superpowers/sdd/2026-09-17-ios-tuist-skills-v0.2/HANDOFF-TO-CODEX.md`),
Codex owns implementation of `ios-tuist-skills`. The Claude session for
v0.5 produced spec + plan only and stopped — no implementation was
attempted this time (unlike v0.2, where two tasks had to be handed back
after Claude briefly implemented them by mistake). You are starting
Task 1 from a clean slate.

## What you need to read, in order

1. **Spec** (binding authority for every decision below):
   `docs/superpowers/specs/2026-09-20-ios-tuist-skills-v0.5-design.md`
2. **Plan** (the argument from the spec — task-by-task steps, exact file
   contents, exact commands):
   `docs/superpowers/plans/2026-09-20-ios-tuist-skills-v0.5.md`
3. **This file** — the current repo state and one adjacent, unrelated
   infrastructure change you should know about before you start.

The plan is the primary artifact to execute from — it already contains
every task's full file contents, verification commands, and commit
messages. Treat the spec as authoritative if you ever find the plan
ambiguous or in conflict with it.

## Where things stand

- **Working directory:** no separate worktree — work directly on
  `develop` in the main checkout
  (`/Users/dave/Documents/GitHub/ios-tuist-skills`).
- **HEAD is `72eff3b`** (`docs: add v0.5 implementation plan for
  ios-tuist-test-target skill`). Nothing from the v0.5 plan has been
  implemented yet — start Task 1 from here.
- **Working tree is clean** (`git status --short` prints nothing).
- **Push state:** `origin/develop` is at `6801638` (the self-hosted
  runner CI change below) — two commits behind local `develop`
  (`964bd5d` spec, `72eff3b` plan). Those two are **not yet pushed**.
  Per the plan's own closing note and prior milestones' precedent, do
  not push until the whole v0.5 plan (Tasks 1–5) is done and the user
  agrees to publish.

```
72eff3b (HEAD, develop) docs: add v0.5 implementation plan for ios-tuist-test-target skill
964bd5d docs: add v0.5 design spec for ios-tuist-test-target skill
6801638 (origin/develop) ci: switch fixture validation to self-hosted runner
2ff01c9 fix: correct stale Tuist issue citations in ios-tuist-restyle
```

## What's left: Tasks 1–5, all of them

Nothing has been implemented. Full detail is in the plan file. Summary:

| Task | What it does | Depends on |
|---|---|---|
| 1 | `skills/ios-tuist-test-target/SKILL.md` (new skill) | nothing new — reads existing `references/testing.md`, `references/source-of-truth.md`, `references/version-safety.md` |
| 2 | `tests/fixtures/test-target-candidate/` fixture (real buildable 5-target Tuist project: FeatureA already has a unit test target, FeatureB doesn't, plus a custom `App` scheme bundling `AppTests`/`FeatureATests`) | Task 1 only conceptually — no code dependency |
| 3 | Extend `.github/workflows/validate-fixtures.yml` matrix with the new fixture | Task 2 |
| 4 | Update `README.md`, `CHANGELOG.md`, bump `.claude-plugin/plugin.json` to `0.5.0` | Tasks 1–3 |
| 5 | Final spec-compliance sweep against spec §7's acceptance checklist | Tasks 1–4 |

Tasks 1 and 2 have no code dependency on each other and could be done in
either order, but the plan lists them 1-then-2 and there's no reason to
deviate.

## One fact worth double-checking as you implement Task 1

The plan's Global Constraints and Task 1 both state, as a verified fact
from live Context7 Tuist-docs lookups during plan authoring: Tuist's
`ProjectDescription` has exactly two test product cases, `.unitTests`
and `.uiTests` — there is no `.integrationTests` case. The skill and
fixture represent "integration test target" as a second `.unitTests`
target distinguished by name only (`{Target}IntegrationTests`). If your
own tooling/documentation access disagrees with this by the time you
implement, re-verify against the actual `ProjectDescription` you have
available (don't just trust the plan blindly) and flag the discrepancy
in your ledger/progress notes rather than silently changing the
represented product case.

## Unrelated but adjacent: GitHub Actions CI is now self-hosted (temporary)

Not part of the v0.5 spec/plan — a separate infrastructure change made
earlier in the same session, already pushed to `origin/develop` at
`6801638`. You'll see its effect the moment Task 3 extends the CI
matrix, so it's worth knowing about:

- `.github/workflows/validate-fixtures.yml`'s `runs-on:` was changed
  from `macos-15` to `[self-hosted, self-hosted-ios-tuist]`, with an
  inline comment explaining why and when to revert.
- **Why:** this private repo's GitHub-hosted Actions minutes were
  exhausted (see the "CI credit exhausted" project memory). A
  self-hosted runner was registered on the user's own Mac
  (`~/actions-runner-ios-tuist-skills/`, running as a LaunchAgent
  service, label `self-hosted-ios-tuist`) as a stopgap.
  Confirmed working live: a push to `develop` after this change
  completed successfully in ~9 minutes on the self-hosted runner.
- **When this reverts:** the user's stated plan is to switch back to
  GitHub-hosted runners once development is complete and the repo goes
  public. Until then, every `git push` that triggers this workflow runs
  on the user's own Mac, not GitHub's infrastructure — so CI will only
  actually run if that Mac is on and the LaunchAgent service is alive.
  If a workflow run you triggered appears stuck in `queued` for more than
  a minute or two, that's the first thing to check (not a matrix/YAML
  bug) — ask the user rather than debugging the workflow file.
- Task 3 Step 5 in the plan already accounts for this — it validates
  locally via `scripts/validate-fixtures-locally.sh` first, and treats
  an actual `git push` / GitHub Actions run as the user's decision, not
  something to do unilaterally mid-plan.

## Verification bar (unchanged from prior milestones)

Every task's fixture work must be validated for real — `tuist install`,
`tuist generate --no-open`, `xcodebuild build`, and the relevant
`xcodebuild test` schemes, actually run, actual output checked. "Files
look right" is never sufficient, per this repo's own skills' Output
Contract standard (see any `skills/ios-tuist-*/SKILL.md`'s Validation
section for the pattern you're building tooling to enforce on others —
hold your own implementation to the same bar). The plan's Task 2 Steps
7–9 already walk through exactly this cycle for the new fixture,
including reverting the probe conversion afterward so the committed
fixture stays in its pre-creation state.

## When Tasks 1–5 are done

Follow the plan's own closing note and the spec's acceptance criteria
(spec §7) as the finish line. `develop` will have the v0.5 commits
locally (on top of the already-pushed self-hosted-runner commit) but
**not yet pushed** — pushing to `origin/develop` is a decision to bring
back to the user, not something to do unilaterally, consistent with how
prior milestones were finished.
