RetryKit is now a dependency of SearchFeature, and both SearchFeature and the App build. Nothing in SearchFeature uses RetryKit yet, so its requests aren't actually retried until code calls `RetryPolicy`.

**Version Context**
- Tuist 4.206.0, pinned in `.tool-versions` and matching the installed `tuist version`, no conflicts. Evidence collected by the bundled script.
- Xcode 27.2, Swift 6.4.2; `Tuist/Package.swift` uses swift-tools-version 5.9.
- The project uses Tuist's own `Tuist/Package.swift` setup, not Xcode's built-in Swift package handling. RetryKit was already declared there as a local package (`../Packages/RetryKit`, built as a static framework) but no target used it.

**Changes Made**
- Added `.external(name: "RetryKit")` to SearchFeature's dependencies only.
- No other target changed, including App. `Tuist/Package.swift` is unchanged.

**Files Changed**
- `Project.swift`

**Dependency Changes**
- Added SearchFeature → RetryKit (a local Swift package library). The edge check found no usage: there's no `import RetryKit` in `SearchFeature/Sources` yet.
- No version requirement involved, since it's a path-based local package.
- No edges removed.

**Validation Performed**
- `tuist install`: success
- `tuist generate`: success. It repeated a warning that was already there: CoreUtilities is a static target linked from both App and LegacyHelpers. This change didn't cause it.

**Build Result**
- SearchFeature (iOS Simulator): success
- App (iOS Simulator): success

**Test Result**
- Tests not run

**Unverified Items**
- Tests not run.
- No code uses RetryKit yet, so how it behaves at runtime is untested.

**Risks / Follow-up**
- To actually retry, `SearchViewModel` needs `import RetryKit` and logic built on `RetryPolicy`. RetryKit only provides `RetryPolicy(limit:)` and its `attempts` list, so the retry loop itself would have to be written. I can add it if you want.

```ios-tuist-result
skill: ios-tuist-dependency
outcome: completed
version_evidence:
  effective: 4.206.0
  source: .tool-versions
  conflicts: []
  collected_by: script
files_changed: [Project.swift]
dependency_edges_added:
  - {from: SearchFeature, to: RetryKit, usage: none-found}
dependency_edges_removed: []
validation: {generate: pass, build: pass, test: not-run}
unverified:
  - Tests not run
  - RetryKit runtime behavior unverified because no call site uses it yet
```