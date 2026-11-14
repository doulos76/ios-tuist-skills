RetryKit is now a dependency of SearchFeature. It was already declared in `Tuist/Package.swift`, so the only change is one line in `Project.swift`. SearchFeature and App both build. SearchFeature doesn't use RetryKit yet, so nothing in its requests retries until you add `import RetryKit` and call it.

**Version Context**
- Tuist 4.206.0 from `.tool-versions`. The installed Tuist matches and there are no conflicts. Collected by the evidence script.
- Xcode 27.2, Swift 6.4.2, `Tuist/Package.swift` tools-version 5.9. The project uses Tuist 4 manifest syntax (`.external`, `buildableFolders`).

**Changes Made**
- Added `.external(name: "RetryKit")` to SearchFeature's dependencies and nowhere else. App and the other targets are unchanged.

**Files Changed**
- `Project.swift`

**Dependency Changes**
- RetryKit is a local Swift package (`Packages/RetryKit`), already listed in `Tuist/Package.swift` as a `.staticFramework`. No new package declaration or version constraint was needed.
- Added the edge SearchFeature → RetryKit. The edge check found no usage, because nothing in SearchFeature imports RetryKit yet. The product and module are both named `RetryKit`, so this isn't a naming mismatch.
- No edges removed. The project still manages packages through `Tuist/Package.swift`.

**Validation Performed**
- `tuist install`: success
- `tuist generate`: success. It printed a warning that CoreUtilities is a static target linked from both App and LegacyHelpers; that's unrelated to this change.

**Build Result**
- SearchFeature (iOS Simulator): success
- App (iOS Simulator): success

**Test Result**
- Tests not run

**Unverified Items**
- Tests not run
- No code in SearchFeature uses RetryKit yet, so retrying hasn't been exercised.

**Risks / Follow-up**
- The edge has no usage yet. The next step is to use `RetryPolicy` in `SearchFeature/Sources/SearchViewModel.swift` to wrap its requests. I left that out because this was a dependency-only change; I can write it if you want.

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
  - No code in SearchFeature uses RetryKit yet, so retrying hasn't been exercised
```