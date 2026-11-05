Extracted `PriceFormatter` into dependency-free `PricingKit`. CheckoutFeature and SettingsFeature now use it, preserving formatting behavior. Formatter tests moved to `PricingKitTests`; cart coverage remains in Checkout.

Verified with Tuist 4.206.0: project generation, full App build, both test schemes, dependency edges, and diff checks pass. Review found no issues. The existing CoreUtilities linkage warning remains; nothing is unverified.

```ios-tuist-result
skill: ios-tuist-module
outcome: completed
version_evidence:
  effective: 4.206.0
  source: .tool-versions
  conflicts: []
  collected_by: script
files_changed:
  - Project.swift
  - Checkout/Cart/Cart.swift
  - Checkout/Formatting/PriceFormatter.swift
  - CheckoutTests/PriceFormatterTests.swift
  - CheckoutTests/CartTests.swift
  - SettingsFeature/Sources/SettingsViewModel.swift
  - PricingKit/Sources/PriceFormatter.swift
  - PricingKit/Tests/PriceFormatterTests.swift
dependency_edges_added:
  - {from: CheckoutFeature, to: PricingKit, usage: "Checkout/Cart/Cart.swift:2"}
  - {from: SettingsFeature, to: PricingKit, usage: "SettingsFeature/Sources/SettingsViewModel.swift:2"}
  - {from: PricingKitTests, to: PricingKit, usage: "PricingKit/Tests/PriceFormatterTests.swift:2"}
dependency_edges_removed: []
validation: {generate: pass, build: pass, test: pass}
unverified: []
```