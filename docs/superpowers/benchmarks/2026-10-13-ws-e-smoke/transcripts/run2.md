Read-only review complete — no files were modified.

## Version Context

| Axis | Evidence |
|---|---|
| Tuist (effective) | **4.206.0**, from `.tool-versions` (only pin source present) |
| Tuist (active) | 4.206.0 (`tuist version`) — **no conflict** |
| Xcode | Active 27.0; `compatibleXcodeVersions` not declared (`Tuist.swift:3` is a bare `Tuist()`) |
| Swift | Active 6.4; no `swiftVersion` pin, no `Package.swift` |
| Manifest compatibility | `buildableFolders:` + `.target(...)` used throughout — requires Tuist ≥ 4.42; satisfied by 4.206.0 |

Version evidence collected with the bundled script.

## Graph Summary

6 targets, 5 dependency edges, verified via `tuist graph --format dot`:

```
App (.app)            -> FeatureA
FeatureA (.staticFramework) -> CoreKit
CoreKit (.staticFramework)  -> (none)
AppTests (.unitTests)      -> App
FeatureATests (.unitTests) -> FeatureA
CoreKitTests (.unitTests)  -> CoreKit
```

Linkage types present: `.app`, `.staticFramework` (×2), `.unitTests` (×3). All targets: `destinations: .iOS`, `deploymentTargets: .iOS("17.0")`. Graph is acyclic.

## Findings

**1. `FeatureA` declares a dependency on `CoreKit` that no FeatureA source uses**

- Rule violated: reusability / build cost (modularization.md pre-module checklist)
- Evidence: `Project.swift:34` declares `dependencies: [.target(name: "CoreKit")]` for `FeatureA`. `FeatureA/Sources/FeatureA.swift:1` imports only `SwiftUI`. A grep for `CoreKit` and `CoreDisplayFormatter` across all `*.swift` returns no hit anywhere under `FeatureA/Sources` — the only non-manifest references to CoreKit symbols are inside CoreKit itself and `CoreKit/Tests/CoreKitTests.swift:5`.
- Recommendation: either resolve via finding 2 (make FeatureA actually consume CoreKit) or drop the edge — a task for `ios-tuist-dependency`.

**2. `CoreKit`'s shared formatter is duplicated in `FeatureA` rather than reused**

- Rule violated: reusability; public API surface
- Evidence: `CoreKit/Sources/CoreKit.swift:3-7` defines `CoreDisplayFormatter.title(for:)` returning `rawValue.uppercased()`. `FeatureA/Sources/FeatureA.swift:12-16` defines `FeatureATitleFormatter.title(for:)` with an identical body. The tests are duplicated too: `CoreKit/Tests/CoreKitTests.swift:4-6` and `FeatureA/Tests/FeatureATests.swift:4-6` are the same test name (`titleUppercasesRawValue`) asserting the same `"profile"` → `"PROFILE"` behavior. The declared `FeatureA -> CoreKit` edge exists precisely to permit this reuse, and it is unused.
- Recommendation: have `FeatureAView` (`FeatureA/Sources/FeatureA.swift:7`) call `CoreDisplayFormatter` and delete `FeatureATitleFormatter`, or consolidate deliberately in the other direction — a task for `ios-tuist-feature`.

**3. `CoreKit`'s continued existence as a separate target is not currently justified**

- Rule violated: ownership boundary; reusability; compile-time isolation benefit
- Evidence: `CoreKit` has one declared production dependent (`FeatureA`, `Project.swift:34`) which does not use it (finding 1), so its only real consumer is its own test target (`CoreKitTests`, `Project.swift:64`). Its entire surface is one 5-line enum with one static function (`CoreKit/Sources/CoreKit.swift:3-7`); isolating that cannot measurably reduce incremental build time for other targets. It declares `dependencies: []` (`Project.swift:54`).
- Recommendation: this finding is resolved *either* by fixing finding 2 (which gives CoreKit a real consumer and a reason to exist) *or* by merging it back into `FeatureA` — merge-back is a task for `ios-tuist-module`. Prefer the former only if a second consumer is concretely near-term; otherwise the target is boilerplate.

## Not Flagged

- **Dependency direction.** No reverse edge: `CoreKit` depends on nothing in the manifest (`Project.swift:54`) and imports only `Foundation` (`CoreKit/Sources/CoreKit.swift:1`). No core→feature import exists in source either.
- **Cycles.** The `tuist graph` DOT output above contains no cycle, existing or latent.
- **Duplicate-symbol risk from static fan-out.** Both static frameworks are checked and found sound: each linked image embeds each static target at most once (app image: `FeatureA` + `CoreKit`; `FeatureATests`: `FeatureA`+`CoreKit`; `CoreKitTests`: `CoreKit`). There is no target that two statically-linked siblings both pull into the same image, so the fan-out condition in modularization.md does not arise here.
- **Version pin consistency.** Single pin source, matching active CLI — nothing to reconcile.
- **Platform/deployment uniformity.** All six targets declare `.iOS` / `iOS 17.0`.

## Unverified Items

- **Resource ownership** — not evaluated: no `resources:` declaration on any target and no asset/strings/storyboard files anywhere in the tree, so there is nothing to separate.
- **External and binary dependencies** — none present (no `Tuist/Package.swift`, no `.external(...)` or `.xcframework(...)` edges), so linkage-vs-external-binary constraints were not assessed.
- **App extension / widget constraints** — no extension targets exist, so those linkage constraints were not assessed.
- **Test host configuration** for `FeatureATests` / `CoreKitTests` — outside this review's graph-direction scope; not inspected.
- **Build / test behavior** — `tuist generate`, `build` and `test` were not run; this skill makes no changes and validates no build. All claims above come from manifest content and `tuist graph` output.

```ios-tuist-result
skill: ios-tuist-architecture-review
outcome: completed
version_evidence:
  effective: 4.206.0
  source: .tool-versions
  conflicts: []
  collected_by: script
files_changed: []
dependency_edges_added: []
dependency_edges_removed: []
validation: {generate: not-run, build: not-run, test: not-run}
unverified:
  - "Resource ownership not evaluated: no resources declared or present in any target"
  - "External/binary dependencies not assessed: none present in the graph"
  - "App extension / widget linkage constraints not assessed: no extension targets exist"
  - "Test host configuration for FeatureATests/CoreKitTests not inspected (outside graph-direction scope)"
  - "tuist generate/build/test not run (read-only skill)"
```

The three findings are one underlying smell: `CoreKit` was split out, the edge to it was wired up, and then `FeatureA` reimplemented its only function locally instead of importing it. Fixing finding 2 clears all three; deleting `CoreKit` clears them too. Both are separate, explicit tasks — tell me which direction you want and I'll route it.