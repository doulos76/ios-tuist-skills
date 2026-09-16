# Testing Policy

## Framework choice

- Prefer **Swift Testing** for new unit and integration tests when the
  detected Swift/Xcode version supports it (check
  [version-safety](version-safety.md)'s Tuist Context first).
- If the repository already standardizes on **XCTest**, preserve XCTest
  for new tests in that area. Do not introduce Swift Testing into an
  XCTest-only codebase as a side effect of an unrelated task.
- Use XCTest / XCUIAutomation for UI tests regardless of the unit-test
  framework choice — Swift Testing does not replace XCUI for UI
  automation.
- Never migrate existing test infrastructure (XCTest -> Swift Testing or
  vice versa) as a side effect of another task. A test-framework
  migration is only performed when explicitly requested.

## What to generate

Generate tests only when they verify meaningful behavior introduced by
the current change. Do not generate placeholder tests such as:

```swift
@Test func example() {
    #expect(true)
}
```

The one exception: an explicitly-labeled minimal smoke test inside a
*template* (see [`templates/`](../templates/)), whose purpose is to prove
the generated project builds and runs at least one test — label it
clearly as a template smoke test in a comment so it is never mistaken
for real coverage.

## Scope

When adding a feature, test the feature's own new behavior. Do not
expand test scope to unrelated existing code as part of the same change.
