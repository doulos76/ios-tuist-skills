# test-target-candidate

## Starting state

- Pinned Tuist version: **4.206.0** (matches this repository's other
  fixtures).
- Five targets: `App`/`AppTests` (entry point depending on both
  features), `FeatureA`/`FeatureATests`, `FeatureB` (no test target).
- One custom `Scheme` named `App`, `shared: true`, whose `buildAction`
  covers `App`/`FeatureA`/`FeatureB` and whose `testAction` bundles
  `AppTests` and `FeatureATests` — `FeatureB` is deliberately not
  included anywhere in this scheme's `testAction`, since it has no test
  target yet.
- Verified live: `tuist generate --no-open` succeeds; `xcodebuild build`
  for scheme `App` succeeds.

## `FeatureA`: the "already has a unit test target" candidate

- `FeatureATests` already exists, `product: .unitTests`, depends on
  `FeatureA`, and uses Swift Testing.
- `ios-tuist-test-target` is expected to refuse a "create a unit test
  target for FeatureA" request, reporting that `FeatureATests` already
  exists, and make no changes.

## `FeatureB`: the "create it" candidate

- No test target exists for `FeatureB` yet, and it is not present in the
  custom `App` scheme's `testAction`.
- `ios-tuist-test-target` is expected to, given "create a unit test
  target for FeatureB":
  - Create `FeatureBTests` (`product: .unitTests`, depends on
    `FeatureB`), with one labeled placeholder test only.
  - Add `FeatureBTests` to the existing custom `App` scheme's
    `testAction` target list, alongside `AppTests` and `FeatureATests`
    (never replacing that list).
  - Leave `App`, `AppTests`, `FeatureA`, `FeatureATests` manifest
    declarations and all source file contents byte-identical.

## What must NOT change

- Any `.swift` source file's contents in `App/`, `FeatureA/`.
- `FeatureA`'s manifest declaration or its existing `FeatureATests`
  target (not named in the "create for FeatureB" request, so untouched).
- The custom `App` scheme's `buildAction` and `runAction` (only its
  `testAction` target list gains one entry).
- Bundle IDs, target names, and dependency edges for every
  already-existing target.

## Manual validation (not run by the outer CI matrix)

1. `mise exec tuist@4.206.0 -- tuist install` and `tuist generate
   --no-open` succeed from this directory as committed.
2. `xcodebuild -workspace TestTargetCandidate.xcworkspace -scheme App
   -destination 'generic/platform=iOS Simulator' build` succeeds.
3. Applying `ios-tuist-test-target`'s creation to `FeatureB` (unit test
   target), then `tuist generate --no-open` succeeds, `xcodebuild build`
   for scheme `App` succeeds, and `xcodebuild test -scheme App` runs and
   passes `FeatureBTests`' placeholder alongside the existing
   `AppTests`/`FeatureATests`.
4. `FeatureA`/`FeatureATests` and the scheme's `buildAction`/`runAction`
   are unchanged throughout.

CI (`validate-fixtures.yml`) only proves step 1–2's pre-creation state is
real and buildable at 4.206.0 — steps 3–4 are `ios-tuist-test-target`'s
own Validation step, exercised when the skill actually runs, per the
v0.5 spec §4.2.
