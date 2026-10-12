## Version Context

| Axis | Evidence |
|---|---|
| Tool version (project pin) | `.tool-versions:1` → `tuist 4.206.0` |
| Tool version (active) | **Unverified** — `tuist version` not approved in this environment |
| Xcode / Swift | **Unverified** — `xcodebuild -version`, `swift --version` not approved |
| Manifest compatibility | Consistent with Tuist 4.x: `Tuist.swift` uses the bare `Tuist()` initializer; `Project.swift` uses `.target(...)` with `destinations:`/`deploymentTargets:` and `buildableFolders:` (4.x-era API, not the pre-4 `sources:`/`platform:` form). No deprecated 3.x syntax present. |

No pinned-vs-active mismatch could be computed, since the active version is unverified.

## Graph Summary

6 targets, all `destinations: .iOS`, deployment target 17.0. 5 declared dependency edges. Linkage types present: `.app` (1), `.staticFramework` (2), `.unitTests` (3). No external/SPM dependencies, no binary dependencies.

| Target | Product | Declared deps | Declared dependents |
|---|---|---|---|
| App | app | FeatureA | AppTests |
| AppTests | unitTests | App | — |
| FeatureA | staticFramework | CoreKit | App, FeatureATests |
| FeatureATests | unitTests | FeatureA | — |
| CoreKit | staticFramework | *(none)* | FeatureA, CoreKitTests |
| CoreKitTests | unitTests | CoreKit | — |

Declared direction: `App → FeatureA → CoreKit`. Acyclic.

Actual source-level direction (from every `import` in the repo): `App → FeatureA`. `FeatureA` imports only `SwiftUI`; `CoreKit` imports only `Foundation`.

## Findings

### 1. FeatureA → CoreKit is a phantom edge

- **Target(s):** FeatureA, CoreKit
- **Rule violated:** Declared graph must match real coupling (dependency-direction / graph-accuracy rule).
- **Evidence:** `Project.swift:34` declares `dependencies: [.target(name: "CoreKit")]` for FeatureA. A grep of every `import` statement in the repository returns no `import CoreKit` outside `CoreKit/Tests/CoreKitTests.swift:2` (`@testable import CoreKit`). `FeatureA/Sources/FeatureA.swift:1` imports only `SwiftUI`. No CoreKit symbol is referenced anywhere in FeatureA's sources.
- **Consequence here:** Because both are `.staticFramework`, CoreKit's object code is linked into FeatureA and transitively into the App binary while contributing zero used symbols, and the manifest overstates coupling to any reader or tooling that trusts it (including `tuist graph` and cache invalidation scope — a CoreKit edit rebuilds FeatureA and App for no semantic reason).
- **Recommendation:** Resolve together with Finding 2 — either make FeatureA genuinely consume CoreKit, or drop the edge. Changing the edge is `ios-tuist-dependency` work.

### 2. CoreKit's single public API is duplicated verbatim inside FeatureA

- **Target(s):** CoreKit, FeatureA
- **Rule violated:** Pre-module checklist — a module must have real, actual reuse; shared code must live on one side of the boundary.
- **Evidence:** `CoreKit/Sources/CoreKit.swift:3-7` defines `CoreDisplayFormatter.title(for:) -> rawValue.uppercased()`. `FeatureA/Sources/FeatureA.swift:12-16` defines `FeatureATitleFormatter.title(for:)` with an identical body, and `FeatureA/Sources/FeatureA.swift:7` calls the local copy. The two test files are also identical apart from the type name (`CoreKit/Tests/CoreKitTests.swift:4-6` vs `FeatureA/Tests/FeatureATests.swift:4-6`), including the same test-function name `titleUppercasesRawValue`.
- **Recommendation:** Delete `FeatureATitleFormatter` and call `CoreDisplayFormatter` through the already-declared dependency (which also makes Finding 1's edge real), or collapse CoreKit per Finding 3. The duplicated test function name is a side effect of the duplication, not a separate defect.

### 3. CoreKit has no consumer that justifies it as a target

- **Target(s):** CoreKit
- **Rule violated:** Pre-module checklist — a module needs a clear owner and ≥1 genuine non-test consumer; targets existing only for their own test target fail it.
- **Evidence:** CoreKit's only two declared dependents are FeatureA (whose dependency is non-functional per Finding 1) and CoreKitTests (`Project.swift:64`), its own test target. Its entire surface is one 5-line enum with one static function (`CoreKit/Sources/CoreKit.swift:3-7`), with no resources, no external dependencies (`Project.swift:54` → `dependencies: []`), and no second consumer anywhere in the graph. In effect, the compile-time cost and manifest surface of a separate static framework currently buys zero reuse.
- **Recommendation:** Either (a) fix Finding 2 so CoreKit gains one real consumer and the boundary starts earning its keep, or (b) merge CoreKit back into FeatureA — an `ios-tuist-module` merge-back candidate. Option (a) is the smaller change and the only one that preserves a place for a second feature's shared code; this review does not prescribe which.

## Not Flagged

- **Cycles:** None, existing or latent. The declared graph is a strict chain `App → FeatureA → CoreKit`, and the source-level graph is a subset of it.
- **Dependency direction:** Correctly pointed. CoreKit declares no dependencies (`Project.swift:54`) and no CoreKit source file imports or references FeatureA or App — no core-depends-on-feature reversal.
- **Static-linkage fan-out / duplicate symbols:** No risk found. CoreKit is reachable by exactly one static path (`App → FeatureA → CoreKit`); FeatureA is the only static framework linked into App. No target is statically linked into two independent binaries.
- **Test-target wiring:** Each of the three code targets has exactly one unit-test target depending on it, with matching `buildableFolders` and distinct bundle IDs (`Project.swift:20, 40, 60`). No test target is missing or cross-wired.
- **Manifest hygiene:** All six targets share `destinations: .iOS` and `deploymentTargets: .iOS("17.0")` with no drift; bundle IDs are unique and consistently prefixed.
- **Resource ownership:** Not applicable — no target declares `resources:`, and no resource files exist in the tree.

## Unverified Items

- `tuist graph` was not run — the command required an approval that was not granted. All graph claims above come from direct manifest reading (`Project.swift`) cross-checked against an exhaustive `import` grep of `App/`, `FeatureA/`, and `CoreKit/`. The graph here is small and fully declared in one manifest, so manifest reading is complete for structure, but transitive linkage as Tuist actually resolves it is unconfirmed.
- The bundled `collect-version-evidence.sh` was not used: script execution was not approved. Version evidence was gathered manually from `.tool-versions` and `Tuist.swift`; the active tool versions remain unknown.
- `references/modularization.md` and `references/output-contract.md` were not readable (permission not granted). Checklist items and the result-block shape below are cited from the skill body's own descriptions; exact checklist wording and the canonical block schema are therefore unverified.
- No build or test run was attempted — this skill makes no changes and performs no build validation. Whether Findings 1–3 would surface as compiler warnings is unconfirmed.

```yaml
ios-tuist-result:
  skill: ios-tuist-architecture-review
  status: completed
  changes_made: false
  tuist_version_pinned: "4.206.0"
  tuist_version_active: unverified
  targets_reviewed: 6
  dependency_edges: 5
  findings:
    - id: phantom-dependency-edge
      targets: [FeatureA, CoreKit]
      rule: graph-accuracy
      evidence: "Project.swift:34 declares FeatureA -> CoreKit; no `import CoreKit` exists outside CoreKitTests"
      recommendation: "make the dependency real or remove it (ios-tuist-dependency)"
    - id: duplicated-shared-api
      targets: [CoreKit, FeatureA]
      rule: pre-module-checklist/real-reuse
      evidence: "CoreKit/Sources/CoreKit.swift:3-7 and FeatureA/Sources/FeatureA.swift:12-16 are identical implementations"
      recommendation: "delete FeatureATitleFormatter and consume CoreDisplayFormatter"
    - id: module-without-consumer
      targets: [CoreKit]
      rule: pre-module-checklist/owner-and-consumer
      evidence: "only dependents are CoreKitTests and the non-functional FeatureA edge; surface is one 5-line enum"
      recommendation: "gain a real consumer, or merge back (ios-tuist-module)"
  not_flagged: [cycles, dependency-direction, static-linkage-fanout, test-target-wiring, manifest-hygiene, resource-ownership]
  unverified: ["tuist graph not run (approval denied)", "active tool versions unknown", "evidence script not used: execution not approved", "references/modularization.md and references/output-contract.md unreadable (permission denied)"]
```

The three findings are one root cause: FeatureA reimplements CoreKit's only function instead of calling it, which leaves the declared edge inert and CoreKit without a consumer. Fixing Finding 2 resolves all three.
