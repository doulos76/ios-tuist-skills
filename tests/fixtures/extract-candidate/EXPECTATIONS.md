# Fixture: extract-candidate

**Exercises:** `ios-tuist-module`

## Starting state

A real, buildable single-target Tuist project (`App`) containing two
distinct pieces of code:

- `Networking.swift` — a small, dependency-free, independently testable
  networking layer with a clear public surface. This should clear the
  modularization checklist.
- `SettingsRow.swift` — a single, one-off SwiftUI view used exactly once
  in the app's entry point, with no reuse and no distinct ownership
  boundary. This should fail the checklist.

## Prompts to exercise this fixture

> Extract the networking code into its own module called NetworkingKit.

and, separately (reset the fixture between the two):

> Extract SettingsRow into its own module.

## Expected behavior

**For the networking extraction:**
- The checklist in `references/modularization.md` is applied concretely
  (not hypothetically) before any file is touched.
- A new `NetworkingKit` target is created; `App` depends on it instead of
  owning the code.
- The moved test (`requestBuilderComposesProfilePath`) travels with the
  code into `NetworkingKit`'s own test target.
- `tuist generate` succeeds; `NetworkingKit` and `App` both build; the
  moved test passes.

**For the `SettingsRow` extraction:**
- The skill refuses the extraction.
- The Output Contract states "Changes Made: none — extraction refused"
  and names the specific checklist items that failed (no reuse, no
  ownership boundary, no test-isolation benefit).
- No file is created or modified.

## What must NOT happen

- `SettingsRow` extracted into its own target anyway "because it was
  asked for."
- The extracted networking code's public behavior changed while moving.
- Any change to `SettingsRow.swift` when the networking extraction is the
  one being exercised (the two prompts are independent — only the
  targeted code should move).

## How to check

1. For the networking prompt: `git diff` should show a new
   `NetworkingKit/` directory, `Project.swift` gaining a `NetworkingKit`
   target and `App` depending on it, and `Networking.swift` +
   `AppTests.swift`'s networking test relocated — nothing else touched.
2. For the `SettingsRow` prompt: `git diff` should be empty (or contain
   only the skill's own reported output, not tracked in this directory);
   confirm via `git status --short tests/fixtures/extract-candidate`.
3. Independently run `tuist install && tuist generate --no-open &&
   xcodebuild build` (and `xcodebuild test` for the relevant scheme)
   after the networking extraction to confirm the skill's own report
   wasn't taken on faith.
4. Reset with `git checkout -- tests/fixtures/extract-candidate && git
   clean -fdx tests/fixtures/extract-candidate` between exercising either
   prompt and before committing any further changes to this fixture.
