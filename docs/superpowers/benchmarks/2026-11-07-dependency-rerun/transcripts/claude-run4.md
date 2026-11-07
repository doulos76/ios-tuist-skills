`SearchFeature` now depends on RetryKit and everything builds, but **its requests don't retry yet**. This change only wires in the dependency, and no code imports or uses `RetryPolicy` so far.

## Version Context
- **Tuist:** 4.206.0, pinned in `.tool-versions`; the active version matches and there are no conflicts.
- **Xcode:** 27.2 is active, and the project doesn't pin a version.
- **Swift:** 6.4.2 is active, and `Tuist/Package.swift` uses tools version 5.9.
- **Manifest syntax:** the existing `.external(name:)` form, which `LogKit` and `KeyValueStore` already use.

## Changes Made
I added `.external(name: "RetryKit")` to the `SearchFeature` target's dependencies.

## Files Changed
- `Project.swift` (one line, not committed)

## Dependency Changes
- **Package:** RetryKit, a local Swift package library at `Packages/RetryKit`.
- **Attached to:** `SearchFeature` only.
- **Integration:** `Tuist/Package.swift`, unchanged. It already declared RetryKit as a `.staticFramework`, so no manifest entry was needed.
- **Version constraint:** none, because it's a path dependency like the other local packages.
- **Edge check:** `SearchFeature -> RetryKit: no usage found`, as expected with no `import RetryKit` yet.

## Validation Performed
| Step | Result |
|---|---|
| `tuist install` | Passed |
| `tuist generate --no-open` | Passed |
| `xcodebuild build`, `SearchFeature` scheme (iOS Simulator) | Passed |
| `xcodebuild build`, `App` scheme (iOS Simulator) | Passed |
| `check-consumer-edges.sh` | Ran; 1 edge added, 0 removed |

## Build Result
`SearchFeature` and `App` both report `BUILD SUCCEEDED`.

## Test Result
Not run. `SearchFeature` has no test target, and no source code changed.

## Unverified Items
- `import RetryKit` hasn't been compiled from `SearchFeature`, because nothing imports it yet. The builds only show that the dependency resolves and the graph builds.
- Retry behaviour doesn't exist yet, so there's nothing to verify.

## Risks / Follow-up
- **Adding retries:** `RetryPolicy` only holds a `limit` and an `attempts` list; it doesn't run or retry anything. `HTTPClient` in `CoreNetworking` only describes requests in the code `SearchViewModel` uses, so the retry logic would still need writing. I can add that in `SearchViewModel` if you'd like.
- **Generated files:** the repo has no `.gitignore`, so `Derived/`, `*.xcodeproj`, `*.xcworkspace`, `.build/` and the package equivalents now show as untracked. Stage only `Project.swift` when you commit.
- **Existing warning:** `tuist generate` warns that the static `CoreUtilities` target is linked from both `App` and `LegacyHelpers`. This change didn't cause that, and I left it alone.

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
  - "import RetryKit has not been compiled from SearchFeature because nothing imports it yet"
  - "Retry behaviour does not exist yet, so it was not verified"
```