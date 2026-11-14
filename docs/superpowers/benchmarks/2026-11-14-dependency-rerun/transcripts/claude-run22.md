RetryKit is now linked to SearchFeature and nothing else. SearchFeature and App both build, but no retry code was written: `SearchViewModel` doesn't import or use RetryKit yet, so requests aren't actually retried.

**Version Context**
- Tuist 4.206.0, pinned in `.tool-versions`, with no conflicts; evidence collected by the script.
- Xcode 27.2 and Swift 6.4.2 are installed; `Tuist/Package.swift` uses swift-tools-version 5.9.
- The project already declares packages in `Tuist/Package.swift` and links them with `.external`. I kept that approach.

**Changes Made**
- Added `.external(name: "RetryKit")` to SearchFeature's dependencies.
- No other target changed, including App and CoreNetworking.

**Files Changed**
- `Project.swift`

**Dependency Changes**
- RetryKit was already declared in `Tuist/Package.swift` (local path `../Packages/RetryKit`, set up as a static framework). That file is unchanged, so there was no version constraint to set.
- Added SearchFeature → RetryKit. The edge check reports "no usage found", because nothing in SearchFeature imports RetryKit yet.
- No edges removed.

**Validation Performed**
- `tuist install`: success
- `tuist generate`: success. It printed one warning that was there before this change: CoreUtilities is a static target linked from both App and LegacyHelpers.

**Build Result**
- SearchFeature build (iOS Simulator): success
- App build (iOS Simulator): success

**Test Result**
- Tests not run

**Unverified Items**
- Tests not run
- No retry behaviour exists or was checked; this change only makes RetryKit importable.

**Risks / Follow-up**
- To get retries, `SearchViewModel.swift` needs `import RetryKit` and its requests need to go through a `RetryPolicy`. Until then the new link is unused. Say if you want me to write that.
- The repo has no `.gitignore`, so the generated `.xcodeproj` and `.xcworkspace` files, plus `Derived/` and `.build/` folders, now show as untracked. I didn't delete them or commit anything.

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
  - Retry behaviour not implemented or checked; SearchFeature does not import RetryKit yet
```