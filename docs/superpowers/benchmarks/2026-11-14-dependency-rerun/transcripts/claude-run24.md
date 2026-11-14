I added RetryKit as a dependency of SearchFeature only. The project generates and both SearchFeature and App build. SearchFeature's requests won't actually retry yet, though: no code in SearchFeature imports or calls RetryKit.

**Version Context**
- Tuist 4.206.0 from `.tool-versions`, which matches the installed version, with no conflicts. Evidence collected by the bundled script.
- Xcode 27.2, Swift 6.4.2, `Tuist/Package.swift` tools-version 5.9.
- The existing manifests use `.external(name:)` with Tuist-native `Tuist/Package.swift`.

**Changes Made**
- Added `.external(name: "RetryKit")` to SearchFeature's dependencies in `Project.swift`.
- RetryKit was already declared in `Tuist/Package.swift` as a local package built as a static framework, so that file is unchanged.
- No other target's dependencies changed, including App's.

**Files Changed**
- `Project.swift`

**Dependency Changes**
- Added SearchFeature → RetryKit (local Swift package library, `../Packages/RetryKit`).
- The edge check reports **no usage found**, because `SearchFeature/Sources/SearchViewModel.swift` doesn't import RetryKit yet.
- No edges removed.

**Validation Performed**
- `tuist install`: success
- `tuist generate`: success. It repeated a warning about CoreUtilities being linked statically from both App and LegacyHelpers; that has nothing to do with this change.

**Build Result**
- SearchFeature build (iOS Simulator): success
- App build (iOS Simulator): success

**Test Result**
- Tests not run.

**Unverified Items**
- Tests not run.
- Nothing calls RetryKit, so no retry behaviour has been exercised.

**Risks / Follow-up**
- To make requests actually retry, `SearchViewModel` needs to `import RetryKit` and use `RetryPolicy` around its `HTTPClient` calls. That's feature code, so I left it out of this dependency-only change. I can add it if you want.

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
  - {from: SearchFeature, to: RetryKit, usage: "no usage found"}
dependency_edges_removed: []
validation: {generate: pass, build: pass, test: not-run}
unverified:
  - Tests not run
  - Retry behavior not exercised; SearchFeature sources do not yet import RetryKit
```