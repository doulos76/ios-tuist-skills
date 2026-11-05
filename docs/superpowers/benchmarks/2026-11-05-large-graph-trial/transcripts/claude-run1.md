Extraction complete and fully validated. `PriceFormatter` now lives in a new `PricingKit` module, and `SettingsFeature` calls it instead of its duplicated formatting code.

**Version Context**
- Tuist: 4.206.0 (project-pinned via `.tool-versions`, matches active CLI — no conflict)
- Xcode: 27.1 (active; no `compatibleXcodeVersions` constraint)
- Swift: 6.4 active (Tuist/Package.swift tools-version 5.9)
- Manifest syntax generated for Tuist 4.x, matching the existing `Project.swift` style.

**Checklist gate (passed)** — concrete reuse: `SettingsViewModel.subscriptionPrice` was a verbatim copy of the formatter; clear ownership boundary (single well-bounded concern, already in its own file); existing tests move with it; tiny stable public API (one static function); no dependencies, so no cycle risk. Linkage chosen as `.staticFramework` because that's the convention of every library target in this project (only `LegacyHelpers` differs), PricingKit owns no resources, and it's a leaf node shared by two features — the same pattern as `CoreUI`/`CatalogDomain`.

**Changes Made**
- Created `PricingKit` target (moved `Checkout/Formatting/PriceFormatter.swift` → `PricingKit/Sources/PriceFormatter.swift`) and `PricingKitTests`.
- Split the old mixed test file: the `PriceFormatter` test moved to `PricingKit/Tests/PriceFormatterTests.swift`; the `Cart` test stayed in CheckoutFeatureTests as `CheckoutTests/CartTests.swift` (it tests `Cart`, which remains in CheckoutFeature). No orphaned tests, no new tests invented.
- `SettingsViewModel.subscriptionPrice` now delegates to `PriceFormatter.format(cents:)`; `Cart.swift` imports `PricingKit`.

**Files Changed**: `Project.swift`, `PricingKit/Sources/PriceFormatter.swift` (moved), `PricingKit/Tests/PriceFormatterTests.swift` (new), `CheckoutTests/CartTests.swift` (new), `CheckoutTests/PriceFormatterTests.swift` (deleted), `Checkout/Cart/Cart.swift`, `SettingsFeature/Sources/SettingsViewModel.swift`

**Dependency Changes** (edge-check script results)
- CheckoutFeature → PricingKit (usage: `Checkout/Cart/Cart.swift:2`, symbol at line 19)
- SettingsFeature → PricingKit (usage: `SettingsFeature/Sources/SettingsViewModel.swift:2`, symbol at line 12)
- PricingKitTests → PricingKit (usage: `PricingKit/Tests/PriceFormatterTests.swift:2`)

**Validation Performed / Build / Test**
- Baseline before changes: all 5 pre-existing test suites passed at `f2967b7`.
- `tuist generate`: success (only the pre-existing CoreUtilities static-linkage warning, unchanged).
- Builds: PricingKit, CheckoutFeature, SettingsFeature, App — all succeeded.
- `tuist test --no-selective-testing`: all 6 suites passed (AppTests, HomeFeatureTests, CatalogDomainTests, CoreNetworkingTests, CheckoutFeatureTests, PricingKitTests) — every pre-existing scheme re-ran and passed.

**Unverified Items**: none.

**Risks / Follow-up**: PricingKit is a static product linked by two features that both link into App — same accepted pattern as CoreUI/CatalogDomain here; Tuist raised no new warning for it. Nothing else.

```ios-tuist-result
skill: ios-tuist-module
outcome: completed
version_evidence:
  effective: 4.206.0
  source: .tool-versions
  conflicts: []
  collected_by: script
files_changed: [Project.swift, PricingKit/Sources/PriceFormatter.swift, PricingKit/Tests/PriceFormatterTests.swift, CheckoutTests/CartTests.swift, CheckoutTests/PriceFormatterTests.swift, Checkout/Formatting/PriceFormatter.swift, Checkout/Cart/Cart.swift, SettingsFeature/Sources/SettingsViewModel.swift]
dependency_edges_added:
  - {from: CheckoutFeature, to: PricingKit, usage: "Checkout/Cart/Cart.swift:2"}
  - {from: SettingsFeature, to: PricingKit, usage: "SettingsFeature/Sources/SettingsViewModel.swift:2"}
  - {from: PricingKitTests, to: PricingKit, usage: "PricingKit/Tests/PriceFormatterTests.swift:2"}
dependency_edges_removed: []
validation: {generate: pass, build: pass, test: pass}
unverified: []
```