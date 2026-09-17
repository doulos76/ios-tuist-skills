# Fixture: modular

**Exercises:** `ios-tuist-dependency` (PRD §40 Scenario D)

## Starting state

A real, buildable feature-modular Tuist project with the dependency graph
`App -> ProfileFeature -> SharedUI`. Every production target has its own test
target. Static frameworks make the module boundaries and dependency direction
explicit without introducing dynamic-linking requirements.

## Prompt to exercise this fixture

> Add Kingfisher only to ProfileFeature.

## Expected behavior

- `ProfileFeature` is identified as the consumer directly from the prompt.
- Kingfisher is attached only to `ProfileFeature`'s dependency list.
- `App` and `SharedUI` dependency lists remain unchanged.
- The integration mechanism matches the project's existing mechanism; the
  skill must not introduce a second dependency system.
- Dependency installation and project generation succeed.
- `ProfileFeature` and `App` build successfully afterward.

## What must NOT happen

- Kingfisher attached to `App` or `SharedUI`.
- Any dependency list changed beyond `ProfileFeature`.
- Conversion of the project's dependency integration mechanism.

## How to check

1. Inspect `git diff tests/fixtures/modular/Project.swift`; only the
   `ProfileFeature` declaration (plus lock/resolution files, if applicable)
   should change.
2. Independently run `tuist install`, `tuist generate --no-open`, and an App
   build.
3. Run the `App`, `ProfileFeature`, and `SharedUI` schemes so all three test
   targets are exercised.
4. Restore the fixture with Git before reusing it.
