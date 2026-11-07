RetryKit is now a dependency of `SearchFeature`, and both `SearchFeature` and `App` build, but **search requests don't retry yet**. No code uses RetryKit so far, and it can't re-send a request on its own. The change is uncommitted.

## Version Context
- **Tuist:** 4.206.0 pinned in `.tool-versions`, and the active version matches, with no conflicts.
- **Toolchain:** Xcode 27.2 and Swift 6.4.2. `Tuist/Package.swift` uses tools version 5.9.
- **Manifest style:** `Target.target(...)` with `buildableFolders` on `SearchFeature`, plus `sources` arrays on some other targets.
- **Dependency integration:** Tuist-native, through `Tuist/Package.swift`.

## Changes Made
I added `.external(name: "RetryKit")` to the `SearchFeature` target's dependencies. `Tuist/Package.swift` already declared the package and its product type, so it needed no change.

## Files Changed
- `Project.swift` (one line)

## Dependency Changes
- **Package:** RetryKit, a local Swift package library at `Packages/RetryKit`
- **Version constraint:** none; it stays a path dependency as already declared
- **Attached to:** `SearchFeature` only
- **Edge check:** one edge added, `SearchFeature -> RetryKit`, with `no usage found`; none removed

## Validation Performed
- `tuist install`: success
- `tuist generate --no-open`: success
- `SearchFeature` build: success
- `App` build: success

`tuist generate` also warned that `CoreUtilities` is linked from both `App` and `LegacyHelpers`. This comes from those two targets' existing dependencies, not from this change.

## Build Result
`** BUILD SUCCEEDED **` for both the `SearchFeature` and `App` schemes on a generic iOS Simulator destination.

## Test Result
Not run. The skill doesn't require tests for this change, and `SearchFeature` has no test target.

## Unverified Items
- Existing test targets weren't run.
- Nothing was run on a device or a booted simulator.

## Risks / Follow-up
- **Retry still needs code:** `SearchViewModel` doesn't import RetryKit yet. RetryKit only provides `RetryPolicy`, which holds a limit and a list of attempt numbers, with no way to run a request.
- **Nothing sends requests yet:** the `HTTPClient` call in `SearchViewModel` only uses `describe(_:)`, which returns a string, and `catalogRequest(for:)` just returns an `HTTPRequest`. Retry behaviour needs a request-sending path first, or it needs to go wherever requests actually get sent, which is outside this dependency change.
- **Cleanup:** I removed the generated workspace and project files and `.build` folders after validating, because the repo has no `.gitignore` and they would have shown up as untracked. Run `tuist install` and `tuist generate` again to get them back.

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
  - Existing test targets were not run
  - Nothing was run on a device or booted simulator
```