# Fixture: legacy-tuist

**Exercises:** `ios-tuist-feature` (PRD §40 Scenario B)

## Starting state

A real, buildable Tuist project using `sources: ["Sources/**"]` /
`resources: ["Resources/**"]`-style array folder integration — explicitly
NOT Buildable Folders. It has a single `App` production target and an XCTest
target. The exact paths are namespaced under `App/` because targets are
declared in the root manifest.

## Prompt to exercise this fixture

> Add LoginFeature.

## Expected behavior

- The pinned Tuist version is detected from `.tool-versions` before any
  manifest is touched.
- The existing `sources`/`resources` array convention is preserved for
  the new `LoginFeature` code — it must NOT be switched to
  `buildableFolders`, even though that might be "more modern."
- No implicit modernization of any kind occurs.
- The existing XCTest convention is preserved.
- Existing dependency conventions, if any, are preserved.
- `tuist generate` succeeds after the change.
- The app and `LoginFeature`'s own tests build and pass.

## What must NOT happen

- Switching `App`'s or `LoginFeature`'s folder integration to
  `buildableFolders`.
- Changing the Tuist version pin.
- Replacing XCTest with Swift Testing.
- Introducing a new architecture pattern not already present in this
  fixture.

## How to check

1. Read the skill's Output Contract — confirm "Not changed" lists the
   preserved folder-integration and XCTest conventions explicitly.
2. `git diff` the fixture directory — confirm `App`'s existing manifest
   only gained the minimal wiring needed to depend on `LoginFeature`, with
   no unrelated formatting/style changes.
3. Independently run `tuist generate`, build the `App` scheme, and run its
   tests against an available iOS Simulator.
4. Reset with `git checkout -- tests/fixtures/legacy-tuist && git clean
   -fdx tests/fixtures/legacy-tuist` to restore the fixture for reuse.
