# Comparison 6 — `architecture-smells` — with-skill

## Task prompt

> Review this project's architecture.

## Condition

Real `claude --plugin-dir /Users/dave/Documents/GitHub/ios-tuist-skills`
session, run by the user in the `.worktrees/benchmark-with-skill`
worktree, fixture freshly reset beforehand via
`scripts/benchmark-prep-run.sh architecture-smells`.

## Fixture

`tests/fixtures/architecture-smells/` — `App -> FeatureA -> CoreKit`.
`CoreKit` and `FeatureA` each independently define an identical
uppercasing formatter, despite `FeatureA` declaring a manifest
dependency on `CoreKit` — the smell is source-level (found by reading
code), not manifest-level (a real cycle would fail to generate).

## What this response did

- Mapped the graph via `tuist graph --format json`, corroborated
  against `Project.swift`'s declared edges, before making any claim.
- Found the exact intended smell: grepped `FeatureA/Sources/` and
  `App/Sources/` for any reference to `CoreKit`/`CoreDisplayFormatter`,
  found **zero** — confirming `FeatureA` declares a dependency on
  `CoreKit` in the manifest but never actually imports or calls it in
  source. Named this concretely: "a declared dependency with zero
  source usage."
- Also independently found the duplicated-formatter pattern
  (`CoreDisplayFormatter.title` vs. `FeatureATitleFormatter.title`) as
  a second, related piece of evidence — `FeatureA` reimplements the
  same trivial logic rather than using the module it depends on.
- Named exact files as evidence for every finding
  (`CoreKit/Sources/CoreKit.swift`, `FeatureA/Sources/FeatureA.swift`,
  `App/Sources/ArchitectureSmellsApp.swift`), per this fixture's
  explicit requirement.
- Included a "Not Flagged" section covering dependency direction
  (clean, no reverse imports), cyclic dependencies (none, confirmed via
  both manifest and `tuist graph` JSON), fan-out duplicate-symbol risk
  (N/A — linear chain, not fan-out), and test boundary (each target has
  its own narrowly-scoped test target, no cross-target `@testable`
  leakage).
- **Zero file changes** — confirmed via `git status --short`.
- Explicitly disclosed, under "Unverified Items," that
  `EXPECTATIONS.md` existed in the fixture directory but was
  **deliberately not read** as review input — reasoning stated: "this
  skill's evidence rule requires findings drawn only from the actual
  graph/manifest/source... reading it risks tailoring the report to a
  known answer rather than to what's actually in the code." This
  independently reached the same conclusion `EXPECTATIONS.md` documents
  without consulting it.

## `git diff`

```
(empty — no changes to tests/fixtures/architecture-smells)
```

## Comparison to contaminated baseline (`architecture-smells-baseline.md`)

| Aspect | Baseline (contaminated) | With-skill |
|---|---|---|
| Core finding | Found the same duplicated-formatter smell unprompted | Found the same smell, plus explicitly proved the *unused* declared dependency (zero source references to CoreKit in FeatureA) via grep — a stronger, more specific claim |
| Evidence citation | General description | Exact commands run (`tuist graph --format json`, targeted `grep`) and exact file paths cited per finding |
| "Not Flagged" section | Not present in that format | Full section: dependency direction, cyclic risk, fan-out risk, test boundary, each with a stated reason it's sound |
| Zero file changes | PASS (confirmed) | PASS (confirmed) |
| Avoiding answer-key contamination | N/A (baseline's own contamination is the point of this whole exercise) | **Explicitly declined to read `EXPECTATIONS.md`** and stated why — directly relevant to keeping *this* run's own finding honestly derived, even though the with-skill session has no prior-conversation exposure to worry about the way the baseline generation process does |

This is a notably rigorous run: the response's self-imposed rule
against reading the fixture's own answer key is exactly the kind of
discipline this benchmark's own methodology cares about, applied by
the skill to itself.

## Rubric scoring — NOT PERFORMED

Deferred to the batch scoring pass after all 14 with-skill runs are
captured.

## Real-artifact pass/fail

| Axis | Result |
|---|---|
| No file changes (review-only task) | PASS |
| Findings traceable to actual fixture content | PASS (specific files/greps cited) |
