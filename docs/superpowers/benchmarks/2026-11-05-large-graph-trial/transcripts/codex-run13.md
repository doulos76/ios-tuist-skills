Found five architecture findings. No files were changed.

**Version context:** Tuist is pinned to `4.206.0` in `.tool-versions`, with no conflicting pins detected. The evidence script reports Xcode `27.1` and Swift `6.4`. Active Tuist verification failed under sandbox restrictions.

**Graph summary:** Manifest inspection identifies 21 project targets: one app, five test bundles, 14 static frameworks, and one dynamic framework. There are 31 internal dependency edges and three package edges. Three local packages are declared; `RetryKit` has no consumer.

1. **Medium — `CoreUtilities` crosses two linkage boundaries.**  
   `App` depends directly on static `CoreUtilities` and dynamic `LegacyHelpers`; `LegacyHelpers` also depends on `CoreUtilities`. This creates a risk of including the same static implementation in both executable images. The declarations are in [Project.swift:14](Project.swift#L14) and [Project.swift:238](Project.swift#L238).  
   **Recommendation:** Inspect generated link commands for duplicate inclusion and choose a single runtime owner for `CoreUtilities`. This is a verified graph shape, not a confirmed duplicate-symbol failure.

2. **Medium — `LegacyHelpers` has no functional consumer.**  
   Its entire implementation wraps `TextUtilities.trimmed(...).lowercased()` in [LegacyStringHelper.swift:3](LegacyHelpers/Helpers/LegacyStringHelper.swift#L3). The app imports the module but never calls its API; its title uses `TextUtilities` directly in [LargeGraphApp.swift:20](App/Sources/LargeGraphApp.swift#L20). There are no dedicated tests or resources. The current boundary therefore lacks demonstrated reuse or isolation benefit while introducing a dynamic framework.  
   **Recommendation:** Remove the unused app dependency and assess retiring or merging the wrapper.

3. **Medium — Price formatting has two owners.**  
   [PriceFormatter.swift:2](Checkout/Formatting/PriceFormatter.swift#L2) and [SettingsViewModel.swift:11](SettingsFeature/Sources/SettingsViewModel.swift#L11) contain the same dollars-and-cents algorithm. Only Checkout’s implementation has tests. This duplicates a responsibility across feature boundaries and permits behavior to diverge.  
   **Recommendation:** Consolidate formatting in a shared location justified by these two actual consumers, without adding a Settings-to-Checkout dependency.

4. **Low — Three features declare unused `CoreUI` dependencies.**  
   `SearchFeature`, `SettingsFeature`, and `CheckoutFeature` depend on `CoreUI` in [Project.swift:66](Project.swift#L66), [Project.swift:93](Project.swift#L93), and [Project.swift:106](Project.swift#L106). Search and Settings only import it; neither uses its API. Checkout does not import it. These edges unnecessarily couple the features to `CoreUI → DesignSystem`.  
   **Recommendation:** Remove the unused imports and dependency edges.

5. **Low — `RetryKit` is registered without a consumer.**  
   [Tuist/Package.swift:11](Tuist/Package.swift#L11) configures its static product and [Tuist/Package.swift:21](Tuist/Package.swift#L21) declares the package, but no target depends on it and no source imports or uses it.  
   **Recommendation:** Remove its integration until a concrete consumer requires it.

**Not flagged:** The declared graph is acyclic. No core/domain target depends back on a feature, and no feature depends on another feature. Shared static fan-out through networking, persistence, UI, and logging alone does not establish a linker defect.

**Unverified items:** Tuist graph evaluation and exact manifest compatibility remain unverified: `tuist version` and `tuist graph --help` failed on session/cache permissions, including `Operation not permitted` for `/Users/dave/.cache/clang/ModuleCache`. Generated link behavior, build performance, startup impact, and team ownership were not verified. No generation, build, or tests were run.

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
  - Active Tuist, graph evaluation, and exact manifest compatibility could not be verified due to sandbox permissions.
  - Generated link behavior and duplicate static inclusion were not verified.
  - Build performance, startup impact, and team ownership were not verified.
```