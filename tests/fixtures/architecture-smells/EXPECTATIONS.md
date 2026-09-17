# Fixture: architecture-smells

**Exercises:** `ios-tuist-architecture-review`

## Starting state

A real, buildable three-target Tuist project: `App -> FeatureA ->
CoreKit`. `CoreKit` has no manifest dependency on `FeatureA`. The smell is
source-level, not manifest-level (a real manifest-declared cycle would
fail to generate, so this fixture encodes the smell as evidence a
diagnostic review can find by reading source, not just the graph):

- `CoreKit` and `FeatureA` each independently define the same
  uppercasing formatter (`CoreDisplayFormatter.title` and
  `FeatureATitleFormatter.title`), despite `FeatureA` already declaring a
  manifest dependency on `CoreKit`.

## Prompt to exercise this fixture

> Review this project's architecture.

## Expected behavior

- The skill maps the graph (`App -> FeatureA -> CoreKit`) before making
  any claim.
- The skill's findings name the duplicated formatting logic as evidence
  that `FeatureA`'s dependency on `CoreKit` isn't being fully leveraged,
  or that the boundary between the two targets is unclear — citing the
  actual files (`CoreKit/Sources/CoreKit.swift`,
  `FeatureA/Sources/FeatureA.swift`) as evidence.
- No file in the fixture is modified.
- The report includes a "Not Flagged" section noting graph areas
  checked and found sound (e.g. `App`'s single outbound dependency on
  `FeatureA` is unremarkable).

## What must NOT happen

- Any edit to `Project.swift` or any source file in this fixture.
- A finding that isn't traceable to something actually present in this
  fixture's graph or source.
- A recommendation that forces one specific architecture style rather
  than naming the checklist/graph rule violated.

## How to check

1. `git status --short tests/fixtures/architecture-smells` after running
   the skill — must show no changes.
2. Read the skill's findings report — confirm it names `CoreKit` and/or
   `FeatureA` and cites the duplicated formatter as evidence, not a
   generic "consider consolidating shared code" comment untethered to
   this fixture.
3. Independently run `tuist install && tuist generate --no-open &&
   xcodebuild build` plus the three test schemes to confirm the fixture
   itself remains buildable and passing throughout (the smell doesn't
   break the build — that's the point).
