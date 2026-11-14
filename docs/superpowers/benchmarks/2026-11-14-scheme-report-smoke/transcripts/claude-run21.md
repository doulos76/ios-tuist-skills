`PriceFormatter` now lives in a new `PricingKit` module, and both CheckoutFeature and SettingsFeature consume it. SettingsFeature's hand-rolled duplicate is gone. Everything generates, builds, and all six test bundles pass. Changes are left uncommitted in the working tree.

**Version Context**
Tuist 4.206.0 is pinned in `.tool-versions` and matches the active CLI, with no conflicts. Xcode 27.2 and Swift 6.4.2 are active. The manifest uses `Project(targets:)` with mostly `buildableFolders`, and dependencies come through `Tuist/Package.swift`.

**Why the extraction passed the checklist**
- **Reusability is concrete, not hypothetical.** SettingsViewModel contained a byte-for-byte copy of the formatting algorithm.
- **Clear ownership boundary and tiny public surface.** One enum with one static function, and it imports nothing.
- **Test boundary.** It already had a dedicated direct test, which moved with it.
- **No cycle risk.** PricingKit is a leaf with zero dependencies. Having Settings import CheckoutFeature instead would have created a feature-to-feature edge.
- **Compile-time isolation benefit is negligible** given the file size. The split is justified by the other items, not this one.

**Changes Made**
- Created the `PricingKit` static framework target and a `PricingKitTests` unit test target in `Project.swift`, using buildableFolders to match the dominant project convention. Static linkage matches every other library target in the project, and the module has no resources or external dependencies.
- Moved the formatter source into `PricingKit/Sources` with git history preserved.
- Moved the `formatsDollarsAndCents` test into `PricingKit/Tests`. The remaining Cart test stayed in CheckoutFeatureTests, and that file was renamed to `CartTests.swift` to match its content.
- Cart now imports PricingKit. SettingsViewModel's `subscriptionPrice` now delegates to `PriceFormatter.format`.

**Files Changed**
- `Project.swift`
- `Checkout/Formatting/PriceFormatter.swift` moved to `PricingKit/Sources/PriceFormatter.swift`
- `PricingKit/Tests/PriceFormatterTests.swift` (new)
- `CheckoutTests/PriceFormatterTests.swift` renamed to `CheckoutTests/CartTests.swift` and trimmed
- `Checkout/Cart/Cart.swift`
- `SettingsFeature/Sources/SettingsViewModel.swift`

**Dependency Changes** (each verified by the edge-check script)
- CheckoutFeature to PricingKit. Usage at `Checkout/Cart/Cart.swift:2`.
- SettingsFeature to PricingKit. Usage at `SettingsFeature/Sources/SettingsViewModel.swift:2`.
- PricingKitTests to PricingKit. Usage at `PricingKit/Tests/PriceFormatterTests.swift:2`.
- No edges removed.

**Validation Performed**
- Baseline before changes: the `LargeGraph-Workspace` test scheme ran all five pre-existing test bundles and passed.
- After changes: `tuist generate` succeeded. The same workspace scheme built every target, including PricingKit, CheckoutFeature, SettingsFeature and App, and ran six test bundles. All passed.
- Pre-existing test schemes: AppTests, HomeFeatureTests, CheckoutFeatureTests, CatalogDomainTests, CoreNetworkingTests: all success.

**Build Result:** success. **Test Result:** success.

**Unverified Items**
- CI test scheme list not found. No `.github`, `fastlane`, `scripts` or `Makefile` exists, so CI coverage of PricingKitTests could not be checked.

**Risks / Follow-up**
- CI test scheme list not found. If a pipeline exists outside this repo, add PricingKitTests or the PricingKit scheme to its test list.
- The pre-existing generate warning about CoreUtilities being statically linked from both App and LegacyHelpers is unrelated to this change and was left as is.

```ios-tuist-result
skill: ios-tuist-module
outcome: completed
version_evidence:
  effective: 4.206.0
  source: .tool-versions
  conflicts: []
  collected_by: script
files_changed: [Project.swift, Checkout/Formatting/PriceFormatter.swift, PricingKit/Sources/PriceFormatter.swift, PricingKit/Tests/PriceFormatterTests.swift, CheckoutTests/PriceFormatterTests.swift, CheckoutTests/CartTests.swift, Checkout/Cart/Cart.swift, SettingsFeature/Sources/SettingsViewModel.swift]
dependency_edges_added:
  - {from: CheckoutFeature, to: PricingKit, usage: "Checkout/Cart/Cart.swift:2"}
  - {from: SettingsFeature, to: PricingKit, usage: "SettingsFeature/Sources/SettingsViewModel.swift:2"}
  - {from: PricingKitTests, to: PricingKit, usage: "PricingKit/Tests/PriceFormatterTests.swift:2"}
dependency_edges_removed: []
validation: {generate: pass, build: pass, test: pass}
unverified: ["CI test scheme list not found"]
```