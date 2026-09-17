# Dependency Policy

## Classification

Before integrating any dependency, classify it as one of:

- Swift package library
- Swift package macro
- Build tool plugin
- Binary framework
- XCFramework
- Local package
- Local Tuist project
- System framework

The integration strategy may differ by category — a macro or build tool
plugin has different Tuist wiring than a plain library, and a binary
framework/XCFramework has different wiring than a Swift package. Confirm
the category from the dependency's own documentation/manifest, not by
assumption.

## Narrowest-target rule

A dependency must be attached to the narrowest target that actually
requires it — never the app target by default, and never every target in
a workspace "to be safe."

Bad:

```text
App
 └── Kingfisher
```

when only `ProfileFeature` imports Kingfisher.

Correct:

```text
ProfileFeature
 └── Kingfisher
```

If a dependency request is ambiguous about which target it belongs to,
resolve it from actual or clearly-intended `import` usage, preferring the
narrowest valid target — do not default to the app target to avoid the
question.

## Integration mechanism preservation

Do not assume every dependency should use exactly one Tuist integration
mechanism. Before adding a dependency, inspect:

- The repository's current convention (Tuist-native `Tuist/Package.swift`
  vs Xcode-native SwiftPM integration via `.external`/direct
  `.package(url:)` references, depending on what the project already
  uses).
- The dependency's type (from the classification above) and any
  plugin/macro/build-tool-plugin constraints it imposes.
- Package resolution and CI behavior already in place.

Do not convert an existing project from one integration mechanism to
another as a side effect of adding a dependency. That conversion is only
performed when explicitly requested.

## Version constraints

Preserve existing version constraint style (exact, range, branch, commit)
unless the task explicitly requires changing it. When adding a new
dependency with no existing convention to match, prefer the narrowest
constraint that satisfies the stated requirement.
