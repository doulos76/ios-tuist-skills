RetryKit is now a dependency of `SearchFeature`, but **no requests are retried yet**. Nothing imports it, and `SearchFeature` and the app both build.

## Version Context
- **Tuist:** 4.206.0 (pinned in `.tool-versions`), and the active version matches.
- **Toolchain:** Xcode 27.2 and Swift 6.4.2 are active. `Tuist/Package.swift` uses tools version 5.9.
- **Manifest syntax:** `Project.swift` uses `.target(...)` with `buildableFolders` and `.external(name:)`, and I kept that style.

## Changes Made
I added `.external(name: "RetryKit")` to the `SearchFeature` target's dependencies.

## Files Changed
- `Project.swift` (one line, not committed)

## Dependency Changes
- **Package:** RetryKit, a local Swift package library at `Packages/RetryKit`.
- **Attached to:** `SearchFeature` only.
- **Integration:** the existing `Tuist/Package.swift` setup. RetryKit was already declared there as a `.staticFramework`, so that file didn't need changing.
- **Version constraint:** none, because it's a local path dependency.
- **Edge check:** `SearchFeature -> RetryKit: no usage found`, which is expected since no code imports it yet.

## Validation Performed
- **`tuist install`:** success.
- **`tuist generate --no-open`:** success. It warned that `CoreUtilities` is a static product linked from both `App` and `LegacyHelpers`; this change didn't touch either of those links.

## Build Result
Both builds ran against the generic iOS Simulator destination:
- **`SearchFeature`:** `BUILD SUCCEEDED`
- **`App`:** `BUILD SUCCEEDED`

## Test Result
Not run. `SearchFeature` has no test target, and validation for this change only requires install, generate and build.

## Unverified Items
- Retry behaviour, because nothing uses RetryKit yet.
- `import RetryKit` from `SearchFeature` hasn't been compiled. The product name and module name are both `RetryKit` in its manifest, so I expect it to work.

## Risks / Follow-up
- **Retries need more than this dependency:** `RetryPolicy` only holds a `limit` and an `attempts` list, so it has no retry loop. `SearchViewModel` also never sends a request; it only builds a `HTTPRequest` or a description of one.
- **Decision for you:** retry logic needs a real send path first. `SearchFeature` can use RetryKit directly, but if the send path ends up in `CoreNetworking`, the dependency probably belongs there instead.
- **Untracked generated files:** the repo has no `.gitignore`, so `Derived/`, `*.xcodeproj`, `*.xcworkspace`, `Tuist/.build/` and the `.build/`, `Derived/` and `*.xcodeproj` folders under `Packages/*/` all show as untracked. Stage only `Project.swift` when you commit, or add a `.gitignore` first.

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
  - Retry behaviour, because nothing uses RetryKit yet
  - import RetryKit from SearchFeature has not been compiled
```