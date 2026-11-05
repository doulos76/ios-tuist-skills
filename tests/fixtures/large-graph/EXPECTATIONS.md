# Fixture: large-graph

**Exercises:** `ios-tuist-module`, `ios-tuist-dependency`,
`ios-tuist-architecture-review` (PRD v0.9 WS-F: external validity)

## Starting state

A synthetic, buildable Tuist 4.206.0 project (`LargeGraph`) with 16
non-test targets, 5 unit test targets and 3 SwiftPM packages integrated
through `Tuist/Package.swift` as `.external` dependencies. The packages
are local path packages under `Packages/`, so `tuist install` needs no
network. No company code is used.

Layers (manifest edges):

- `App` → `HomeFeature`, `SearchFeature`, `ProfileFeature`,
  `SettingsFeature`, `CheckoutFeature`, `CoreUtilities`, `LegacyHelpers`
- Features → domains: `HomeFeature` → `CatalogDomain`, `CoreUI`,
  `CoreAnalytics`; `SearchFeature` → `CatalogDomain`, `CoreUI`,
  `CoreNetworking`; `ProfileFeature` and `SettingsFeature` →
  `UserDomain`, `CoreUI`; `CheckoutFeature` → `OrderDomain`, `CoreUI`
- Domains → core: `UserDomain` and `OrderDomain` → `CoreNetworking`,
  `CorePersistence`; `CatalogDomain` → `CoreNetworking`
- Core → packages: `CoreNetworking` and `CoreAnalytics` →
  `.external(name: "LogKit")`; `CorePersistence` →
  `.external(name: "KeyValueStore")`; `CoreUI` → `DesignSystem`
- `LegacyHelpers` → `CoreUtilities`
- `RetryKit` is declared in `Tuist/Package.swift` but no target uses it.

Conventions that are deliberately not uniform (real projects drift):

- Most targets use `buildableFolders: ["<Target>/Sources"]`.
  `CheckoutFeature` uses `sources: ["Checkout/**/*.swift"]` (folder name
  differs from the target name) and its tests use
  `sources: ["CheckoutTests/**/*.swift"]`.
- `LegacyHelpers` is the only dynamic `.framework`, uses a `sources:`
  glob over `LegacyHelpers/Helpers`, and has a different bundle ID prefix
  (`com.example.`).
- `SettingsFeature.subscriptionPrice(cents:)` duplicates
  `CheckoutFeature`'s `PriceFormatter.format(cents:)`.
- `SearchViewModel.requestDescription(for:)` builds an `HTTPRequest`
  and calls `HTTPClient` directly although `CatalogDomain` already owns
  catalog requests.

Test schemes (CI matrix): `App`, `HomeFeature`, `CheckoutFeature`,
`CatalogDomain`, `CoreNetworking`.

## Scenario 1 — module extraction (`ios-tuist-module`)

### Prompt

> Extract `PriceFormatter` from CheckoutFeature into a new module called
> `PricingKit`, and make SettingsFeature use it instead of its own copy
> of the price formatting.

### Expected behavior

- The justification checklist is applied and cites the two concrete
  users (`Checkout/Formatting/PriceFormatter.swift`,
  `SettingsFeature/Sources/SettingsViewModel.swift`); extraction
  proceeds.
- A new `PricingKit` target exists and `PriceFormatter` moved into it.
  The new target's folder style is stated and matches a convention the
  project already uses (`buildableFolders` like most targets is
  expected; a `sources:` glob is acceptable only if the report says why).
- Edges to `PricingKit` are added only from targets with a verified
  usage site: `CheckoutFeature` and `SettingsFeature`. No edge from
  `App` or any other target.
- `SettingsViewModel.subscriptionPrice(cents:)` calls `PriceFormatter`
  instead of duplicating it, with the same output.
- `PriceFormatterTests` coverage is kept (moved to a `PricingKit` test
  target or kept in `CheckoutFeatureTests` through the new import).
  `CheckoutFeatureTests` is not emptied; if it were, it is reported, not
  deleted.
- `tuist install`, `tuist generate --no-open`, the `App` build and
  every pre-existing test scheme pass afterwards.

### What must NOT happen

- Changing `.tool-versions` or any package declaration.
- Converting `CheckoutFeature` or `LegacyHelpers` to
  `buildableFolders` (restyling is a different skill).
- An edge to `PricingKit` from a target that does not import it.

## Scenario 2 — dependency addition (`ios-tuist-dependency`)

### Prompt

> Add RetryKit to SearchFeature so its requests can be retried.

### Expected behavior

- `RetryKit` is already declared in `Tuist/Package.swift`; the skill
  says so and does not add a second `.package` entry.
- `.external(name: "RetryKit")` is added to `SearchFeature` only.
- `tuist install`, `tuist generate --no-open`, the `App` build and the
  test schemes pass.
- The report is honest that no `import RetryKit` exists yet if it does
  not add one (`scripts/skill/check-consumer-edges.sh` does not cover
  `.external` edges; that is a known limitation, not evidence of use).

### What must NOT happen

- `RetryKit` added to `App`, `CatalogDomain`, `CoreNetworking` or any
  other target.
- Edits under `Packages/`, to `.tool-versions`, or to `productTypes`
  beyond what the skill explains is required.

## Scenario 3 — architecture review (`ios-tuist-architecture-review`)

### Prompt

> Review this project's architecture and dependency direction. Report
> findings only.

### Expected behavior

- The report maps the graph (features → domains → core → packages)
  before making claims.
- Findings, each with file evidence:
  - `SearchFeature` depends on `CoreNetworking` directly and
    `SearchViewModel.requestDescription(for:)` builds requests itself,
    bypassing `CatalogDomain` (`Project.swift` `SearchFeature`
    dependencies; `SearchFeature/Sources/SearchViewModel.swift`).
  - Price formatting is duplicated between
    `Checkout/Formatting/PriceFormatter.swift` and
    `SettingsFeature/Sources/SettingsViewModel.swift`.
  - `LegacyHelpers` differs from the rest (dynamic `.framework`,
    `sources:` glob, `com.example.` bundle ID) — reported as an
    inconsistency to confirm, not as a required change.
- `App` → `CoreUtilities` and `App` → `LegacyHelpers` are either
  assessed with a reason or listed under "Not Flagged" with a reason.
- A "Not Flagged" section names areas checked and found sound (for
  example the domain → core direction).
- No file is modified.

### What must NOT happen

- Any edit to a manifest or source file.
- A finding not traceable to this fixture's manifests or sources.
- A recommendation that forces one architecture style instead of naming
  the rule or evidence.

## How to check

1. Scenario 1 and 2: `git diff --stat` in the workdir, then
   `tuist install && tuist generate --no-open`, the `App` build and the
   five test schemes (`scripts/benchmark-isolated-run.sh collect` does
   this).
2. Scenario 1: `grep -n 'PricingKit' Project.swift` shows the target and
   exactly two consumer edges.
3. Scenario 2: `grep -n 'RetryKit' Project.swift Tuist/Package.swift`
   shows one `.package` and one `.external` (in `SearchFeature`).
4. Scenario 3: `git status --short` is empty; read the findings against
   the list above.
