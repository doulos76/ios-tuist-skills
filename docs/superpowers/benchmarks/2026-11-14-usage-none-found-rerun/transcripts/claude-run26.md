RetryKit is now a dependency of SearchFeature only. Nothing in SearchFeature uses it yet, so requests are not actually retried until code calls it. The project generates, and both SearchFeature and the App build.

**Version Context**
- Tuist 4.206.0, pinned in `.tool-versions`. The installed version matches and there are no conflicts. I collected this with the skill's version script.
- Xcode 27.2, Swift 6.4.2. `Tuist/Package.swift` uses swift-tools-version 5.9.
- The project already declares packages in `Tuist/Package.swift` and references them with `.external(name:)`. I kept that pattern.

**Changes Made**
- Added `.external(name: "RetryKit")` to SearchFeature's dependencies in `Project.swift:71`.
- RetryKit was already declared in `Tuist/Package.swift` (local package, set to static framework), so that file didn't need changing.
- I didn't touch the App target or any other target.

**Files Changed**
- `Project.swift`

**Dependency Changes**
- Added SearchFeature → RetryKit. RetryKit is a local Swift package at `Packages/RetryKit`, added with `.package(path:)`, so there is no version constraint.
- The dependency check found no use of RetryKit in SearchFeature. No source file has `import RetryKit` yet.
- No dependencies removed.

**Validation Performed**
- `tuist install`: success
- `tuist generate --no-open`: success. It printed one warning that was already there: CoreUtilities is a static framework linked into both App and LegacyHelpers.

**Build Result**
- SearchFeature (iOS Simulator): success
- App (iOS Simulator): success

**Test Result**
- Tests not run

**Unverified Items**
- Tests not run
- No retry behavior exists or was checked, because nothing calls RetryKit yet.

**Risks / Follow-up**
- To actually retry requests, add `import RetryKit` in `SearchFeature/Sources/SearchViewModel.swift` and wrap its request calls with the policy from `Packages/RetryKit/Sources/RetryKit/RetryPolicy.swift`. Without that, the dependency just adds to the build. I can write that code if you want.
- Generating created `LargeGraph.xcodeproj`, `LargeGraph.xcworkspace`, `Derived/` and `.build/` folders. They show as untracked files, and the repo has no `.gitignore` to hide them.

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
  - Retry behavior not implemented or verified; no RetryKit call sites in SearchFeature
```