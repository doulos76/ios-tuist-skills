I've moved `PriceFormatter` out of CheckoutFeature into a new `PricingKit` module, and SettingsFeature now calls it instead of keeping its own copy. The project generates, everything builds, and all test schemes pass, including the new one. One gap: CI doesn't run the new tests yet (see the end).

**Why the extraction made sense**
- **Real reuse:** CheckoutFeature (`Cart`) and SettingsFeature (`subscriptionPrice`) each had the same formatting code, character for character.
- **Better dependency direction:** without a shared module, SettingsFeature would have had to depend on CheckoutFeature, one feature depending on another. PricingKit avoids that and depends on nothing.
- **Its own tests:** the existing formatter test now runs on its own target.
- **Low cost:** it exposes one small public enum, owns no resources, and can't create a cycle.

**Versions**
- Tuist 4.206.0, pinned in `.tool-versions` (CI pins the same version, and it's the one installed).
- Xcode 27.2, Swift 6.4.2.

**What changed**
- **New target `PricingKit`:** a `.staticFramework`, matching every other library in the project. It has no resources, extensions or binaries, so nothing pointed to another linkage. It uses `buildableFolders` like most targets.
- **New target `PricingKitTests`.**
- `Checkout/Formatting/PriceFormatter.swift` moved to `PricingKit/Sources/PriceFormatter.swift` with no changes to its contents.
- The formatter test `formatsDollarsAndCents` moved to `PricingKit/Tests/PriceFormatterTests.swift`. The cart test `cartTotalIsFormatted` stays in `CheckoutTests/PriceFormatterTests.swift`.
- `Checkout/Cart/Cart.swift` now imports `PricingKit`.
- `SettingsFeature/Sources/SettingsViewModel.swift`: `subscriptionPrice(cents:)` keeps its public signature and now just calls `PriceFormatter.format(cents:)`. The output is the same as before.
- `Project.swift` has the two new targets and the new dependency edges.

**Dependency changes** (the edge check confirmed a real use for each)
- CheckoutFeature → PricingKit (used at `Checkout/Cart/Cart.swift:2`)
- SettingsFeature → PricingKit (used at `SettingsFeature/Sources/SettingsViewModel.swift:2`)
- PricingKitTests → PricingKit (used at `PricingKit/Tests/PriceFormatterTests.swift:2`)

**Checks run**
- **Before the change:** the five existing test schemes (App, HomeFeature, CheckoutFeature, CatalogDomain, CoreNetworking) all passed on an iOS 26.0 iPhone 17 Pro simulator.
- **Generate:** `tuist generate` succeeded. It still shows the same `CoreUtilities` static-linking warning as before; that's unrelated to this change.
- **Build:** PricingKit, SettingsFeature, CheckoutFeature and App all built.
- **Tests:** all six schemes pass, including the new PricingKit scheme, where `formatsDollarsAndCents` ran and passed. In CheckoutFeature, `cartTotalIsFormatted` passed.

**Not verified**
- CI doesn't run `PricingKitTests`. `.github/workflows/ci.yml` lines 33–53 test only App, HomeFeature, CheckoutFeature, CatalogDomain and CoreNetworking, and none of those runs PricingKit's tests. I didn't edit CI.

**Decision for you**
- CI needs a "Test PricingKit" step (`-scheme PricingKit`), or the moved formatter test will only run locally. Should I add it?

Nothing is committed yet.

```ios-tuist-result
skill: ios-tuist-module
outcome: completed
version_evidence:
  effective: 4.206.0
  source: .tool-versions
  conflicts: []
  collected_by: script
files_changed: [Project.swift, PricingKit/Sources/PriceFormatter.swift, Checkout/Formatting/PriceFormatter.swift, PricingKit/Tests/PriceFormatterTests.swift, CheckoutTests/PriceFormatterTests.swift, Checkout/Cart/Cart.swift, SettingsFeature/Sources/SettingsViewModel.swift]
dependency_edges_added:
  - {from: CheckoutFeature, to: PricingKit, usage: "Checkout/Cart/Cart.swift:2"}
  - {from: SettingsFeature, to: PricingKit, usage: "SettingsFeature/Sources/SettingsViewModel.swift:2"}
  - {from: PricingKitTests, to: PricingKit, usage: "PricingKit/Tests/PriceFormatterTests.swift:2"}
dependency_edges_removed: []
validation: {generate: pass, build: pass, test: pass}
unverified: ["PricingKitTests not covered by any CI test scheme (.github/workflows/ci.yml:33-53)"]
```