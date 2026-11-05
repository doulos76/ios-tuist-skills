Review complete. The graph is largely sound — layering is clean with no cycles or reverse edges — but I found four concrete issues, the most significant being a duplicate-symbol risk around the one dynamic framework.

## Version Context

- Tuist: **4.206.0**, pinned in `.tool-versions`, matches the active CLI; no conflicting pin sources (evidence collected by the bundled script).
- Xcode 27.1 active; no `compatibleXcodeVersions` constraint declared.
- Swift 6.4 active; `Tuist/Package.swift` uses tools-version 5.9. Manifests use current Tuist 4 syntax (`buildableFolders`, `Tuist.swift`, `PackageSettings`) — compatible with the pinned version; `tuist install` and `tuist graph` both succeeded.

## Graph Summary

Verified against `tuist graph --format dot` output (matches `Project.swift` edge-for-edge):

- **21 project targets**: 1 app, 15 frameworks, 5 unit-test targets; plus 3 local Swift packages (LogKit, KeyValueStore, RetryKit) mapped to `.staticFramework`.
- **Layering**: App → 5 feature frameworks → 3 domain frameworks (User/Catalog/Order) → core frameworks (Networking, Persistence, UI, Analytics, Utilities, DesignSystem) → external packages. 34 dependency edges.
- **Linkage**: everything is `.staticFramework` except `LegacyHelpers`, which is a dynamic `.framework`.

## Findings

**1. LegacyHelpers — duplicate-symbol risk (graph rule: static linkage shared across a dynamic boundary)**
- Evidence: `LegacyHelpers` is the only dynamic framework (`product: .framework`, `Project.swift:240`) and depends on static `CoreUtilities` (`Project.swift:245`); `App` also links `CoreUtilities` statically and directly (`Project.swift:20`). CoreUtilities' object code will be linked into the LegacyHelpers dynamic binary *and* into the App binary, giving two copies of `TextUtilities` at runtime.
- Recommendation: either make LegacyHelpers static like the rest of the graph, or remove App's direct static edge to CoreUtilities — a linkage decision per modularization.md's "linkage is a graph decision" rule.

**2. LegacyHelpers — weak modularization justification (checklist: ownership, reuse, build cost)**
- Evidence: the target contains a single 7-line file (`LegacyHelpers/Helpers/LegacyStringHelper.swift`) that only wraps `TextUtilities.trimmed(...).lowercased()`, has exactly one dependent (App), no tests, and an off-convention bundle id `com.example.legacy-helpers` (every other target uses `dev.ios-tuist-skills.large-graph.*`) — suggesting no clear current owner.
- Recommendation: candidate for merge-back into CoreUtilities or App via `ios-tuist-module`; merging also dissolves finding 1.

**3. CheckoutFeature → CoreUI — declared edge with no usage (checklist: build cost)**
- Evidence: the dependency is declared at `Project.swift:108`, but no file under `Checkout/` imports CoreUI (grep over the target's sources: only `Cart.swift` imports `OrderDomain`; `PriceFormatter.swift` imports nothing). The edge makes CheckoutFeature rebuild whenever CoreUI or DesignSystem changes, for no benefit.
- Recommendation: remove the edge via `ios-tuist-dependency` (or confirm imminent planned usage).

**4. RetryKit — external package with zero consumers (checklist: reuse, build cost)**
- Evidence: declared in `Tuist/Package.swift:21` with a `.staticFramework` product-type override (`Tuist/Package.swift:11`), but no target declares `.external(name: "RetryKit")`, no source imports it, and it does not appear as a node in the `tuist graph` output.
- Recommendation: remove it from `Tuist/Package.swift` via `ios-tuist-dependency`, or wire it to the target that was meant to use it.

**5. CheckoutFeature — boundary layout breaks the project's target↔folder ownership convention (checklist: ownership boundary; minor)**
- Evidence: every other target owns a folder named after itself with `buildableFolders` (e.g. `HomeFeature/Sources`), but CheckoutFeature uses glob `sources:` arrays over two root folders named differently from the target — `Checkout/**/*.swift` (`Project.swift:105`) and `CheckoutTests/**/*.swift` (`Project.swift:118`).
- Recommendation: align the folder names/integration with the rest of the project; a `buildableFolders` conversion would be an explicit `ios-tuist-restyle` request, not something to sweep in.

## Not Flagged

- **Dependency direction**: clean throughout — no core or domain target depends on a feature target, and source imports match declared edges in every target except finding 3 (no undeclared "hidden" imports found).
- **Cycles**: none, existing or latent, in the `tuist graph` output.
- **Static linkage fan-out among the static frameworks themselves** (e.g. CoreNetworking with 4 dependents, CoreUI with 5): all converge into the single App binary through one final link, so no duplicate-symbol evidence apart from the dynamic-boundary case in finding 1.
- **Shared-dependency hygiene**: LogKit's two consumers (CoreNetworking, CoreAnalytics) and KeyValueStore's one (CorePersistence) are all declared and imported correctly.

## Unverified Items

- Test coverage breadth: 10 of 15 framework targets (SearchFeature, ProfileFeature, SettingsFeature, UserDomain, OrderDomain, CorePersistence, CoreUI, CoreUtilities, CoreAnalytics, DesignSystem) have no test target. Noted as context for the test-boundary checklist item rather than a finding, since intent (test strategy) can't be verified from the graph alone.
- Resource ownership per target not inspected — no resource declarations or asset catalogs present in this project.
- No build was run (read-only review); duplicate-symbol risk in finding 1 is asserted from linkage topology, not from observed linker warnings.

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
  - "10 of 15 framework targets have no test target; test strategy intent not verifiable from graph"
  - "Resource ownership per target not inspected (no resources present)"
  - "Duplicate-symbol risk inferred from linkage topology; no build/linker output observed"
```