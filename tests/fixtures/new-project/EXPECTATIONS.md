# Fixture: new-project

**Exercises:** `ios-tuist-bootstrap` (PRD §40 Scenario A)

## Starting state

This directory is empty (aside from this file and `.gitkeep`). No
`Project.swift`, `Tuist.swift`, or `Workspace.swift` exists here.

## Prompt to exercise this fixture

> Create a new SwiftUI iOS app using Tuist with a feature-modular
> structure.

## Expected behavior

- The environment is inspected (Tuist Context established) before any
  file is written.
- The generated structure uses the `feature-modular` profile from
  [`templates/feature-modular/`](../../../templates/feature-modular/).
- No `Workspace.swift` is created unless a real justification is stated
  (a single new app with one or two feature modules does not need one).
- No `Config.swift` is created anywhere.
- `tuist generate` succeeds.
- The app builds.
- Tests run and pass.
- The Output Contract report includes a populated Version Context and
  Validation Performed section with real command results, not assertions
  without evidence.

## What must NOT happen

- The skill must not assume a specific Tuist version without running the
  detection procedure in
  [version-safety](../../../references/version-safety.md).
- The skill must not silently install/upgrade Tuist to a different
  version.
- The skill must not skip validation and still report success.

## How to check

After running the skill against this fixture:

1. Read the skill's Output Contract report against the checklist above.
2. Run `tuist generate --no-open`, then build and test the generated app
   scheme independently; do not trust the skill's own report alone.
3. Reset the fixture to its empty starting state afterward with
   `git clean -fdx tests/fixtures/new-project` from the repo root so the
   fixture stays reusable for future runs and CI.
