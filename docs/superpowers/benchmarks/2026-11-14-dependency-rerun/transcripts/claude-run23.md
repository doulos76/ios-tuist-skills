I added RetryKit as a dependency of SearchFeature only, and both SearchFeature and the App build. SearchFeature doesn't use RetryKit yet, though: none of its requests retry until code calls it.

**Version Context**
- Tuist 4.206.0 from `.tool-versions`, which matches the installed version. No conflicts. Xcode 27.2, Swift 6.4.2. Evidence collected by the bundled script.
- The project declares external packages in `Tuist/Package.swift` and uses `.external(name:)` in `Project.swift`. I kept that convention.

**Changes Made**
- Added `.external(name: "RetryKit")` to SearchFeature's dependencies in `Project.swift`.
- No other target changed, including App.

**Files Changed**
- `Project.swift`

**Dependency Changes**
- RetryKit is a local Swift package library at `Packages/RetryKit`. It was already declared in `Tuist/Package.swift` (with `productTypes` set to `.staticFramework`), so that file didn't change.
- Added SearchFeature → RetryKit. The edge check reports "no usage found" because nothing imports it yet.
- No edges removed.

**Validation Performed**
- `tuist install`: success
- `tuist generate --no-open`: success. It printed a warning about `CoreUtilities` being linked twice; that was already the case and isn't related to this change.

**Build Result**
- SearchFeature (iOS Simulator): success
- App (iOS Simulator): success

**Test Result**
- Tests not run

**Unverified Items**
- Tests not run
- No code calls RetryKit yet, so nothing exercises it

**Risks / Follow-up**
- To actually retry requests, `SearchFeature/Sources/SearchViewModel.swift` needs to `import RetryKit` and use `RetryPolicy`. Its whole API is `RetryPolicy(limit:)` and `.attempts`. That's feature code and outside this dependency change; I can add it if you want.
- Generating and building left untracked files in the repo, because it has no `.gitignore`: `Derived/`, `*.xcodeproj`, `*.xcworkspace`, `Tuist/.build/` and the packages' `.build/` and `Derived/` folders. Don't commit them; adding a `.gitignore` would keep them out.

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
  - No code calls RetryKit yet, so nothing exercises it
```