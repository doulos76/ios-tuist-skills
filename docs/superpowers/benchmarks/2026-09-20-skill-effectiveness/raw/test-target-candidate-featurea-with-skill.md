# Comparison 10a — `test-target-candidate` (FeatureA) — with-skill

## Task prompt

> Create a unit test target for FeatureA and wire it into the existing App scheme.

## Condition

Real `claude --plugin-dir /Users/dave/Documents/GitHub/ios-tuist-skills`
session, run by the user in the `.worktrees/benchmark-with-skill`
worktree, fixture freshly reset beforehand via
`scripts/benchmark-prep-run.sh test-target-candidate featurea`.

## Fixture

`tests/fixtures/test-target-candidate/` — `FeatureA` already has
`FeatureATests` (`product: .unitTests`, depends on `FeatureA`), already
enrolled in the custom `App` scheme's `testAction`
(`.targets(["AppTests", "FeatureATests"])`).

## What this response did

- Inspected `Project.swift` directly and found `FeatureATests` already
  declared at lines 38–47, with the exact product/dependency/sources
  shape, and confirmed it's already in the `App` scheme's `testAction`
  at line 63 — cited exact line numbers as evidence.
- **Refused** to create a duplicate test target. **Zero file changes**.
- Explicitly noted the distinction between "create a new test target"
  (refused, already exists) and "add test cases to the existing
  target" (a different task, out of scope for this skill — belongs to
  `ios-tuist-feature`) — a precise scope boundary, not just a blanket
  refusal.
- Skipped version-pin verification, explicitly reasoning that since no
  manifest change was made, pin verification wasn't necessary for this
  particular outcome (a reasonable scope-minimization call for a
  no-op response, not an omission).

## `git diff`

```
(empty — no changes to tests/fixtures/test-target-candidate)
```

## Comparison to contaminated baseline (`test-target-candidate-featurea-baseline.md`)

| Aspect | Baseline (contaminated) | With-skill |
|---|---|---|
| Verdict | Refused — inspected `Project.swift`/`FeatureATests.swift` first, found it already exists | Refused — inspected `Project.swift` directly, cited exact line numbers |
| REFUSAL correctness | PASS (empty diff, confirmed) | PASS (empty diff, confirmed) |
| Follow-up scope clarity | Not specifically distinguished | Explicitly distinguished "new target" (this task, refused) from "add test cases to existing target" (different skill's job) |

Both conditions reached the identical, correct verdict with equivalent
rigor — this is one of the comparisons where the contaminated
baseline's own independent judgment (formed before reading
`EXPECTATIONS.md`, per that report's own methodology) already matched
the skill's expected behavior, which is useful context for the
aggregate scoring: not every comparison is expected to show a large
with-skill advantage, and this fixture's refusal path is a
straightforward case either condition should get right.

## Rubric scoring — NOT PERFORMED

Deferred to the batch scoring pass after all 14 with-skill runs are
captured.

## Real-artifact pass/fail

| Axis | Result |
|---|---|
| REFUSAL | PASS (empty diff, confirmed) |
| BUILD/TEST | N/A — refusal path |
