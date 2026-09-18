# migrate-candidate

## Starting state

- Pinned Tuist version: **3.42.2** (verified installable via `mise
  install tuist@3.42.2`; `tuist version` reports exactly `3.42.2`).
- `Tuist/Config.swift` (not `Tuist.swift`) using the Tuist 3.x top-level
  `Config` type.
- `Project.swift` using the Tuist 3.x `Target(name:platform:product:
  bundleId:deploymentTarget:infoPlist:sources:...)` member-wise
  initializer, with `platform:` and singular `deploymentTarget:`
  parameters.
- One app target (`App`) and one test target (`AppTests`, depending on
  `App`), both real and buildable (generate, build, and test all pass)
  under 3.42.2.

## Target migration

- Target Tuist version: **4.206.0** (matches this repository's other
  fixtures).
- Breaking change under test: Tuist 4.0 renamed the top-level
  configuration manifest from `Config.swift`/`Config(...)` to
  `Tuist.swift`/`Tuist(...)`, and removed `ProjectDescription.Target`'s
  3.x member-wise initializer entirely — Tuist 4.x's `Target` struct
  only exposes `init(from: Decoder)`, so any 3.x-style `Target(name:
  platform:...)` call site fails outright. Manifests move to the
  `.target(...)` static factory with a `destinations:` parameter
  (replacing `platform:`) and a plural `deploymentTargets:` parameter
  (replacing singular `deploymentTarget:`).
  Verified live: generating this fixture's manifests as-is under Tuist
  4.206.0 fails, first, with `error: extra arguments at positions #1,
  #2, #3, #4, #5, #6, #7 in call` at each `Target(` call site (no
  matching initializer exists in 4.x), then a cascade of `cannot infer
  contextual base in reference to member 'iOS'`/`'app'`/`'default'`/
  `'unitTests'`/`'iphone'` errors on every enum-literal argument in the
  same call (each one loses its contextual type once the call itself
  fails to resolve), and a final `type 'Any' has no member 'target'` on
  the `dependencies:` array. All of this is one connected failure from
  the same root cause, not several unrelated defects.

## What `ios-tuist-migrate` is expected to do against this fixture

- Rename `Tuist/Config.swift` to `Tuist/Tuist.swift`; replace
  `let config = Config(generationOptions: .options())` with `let tuist =
  Tuist()`.
- Rewrite `Project.swift`'s two `Target(...)` initializer calls to
  `.target(...)` static factory calls: `platform: .iOS` becomes
  `destinations: .iOS`, and `deploymentTarget: .iOS(targetVersion:
  "17.0", devices: [.iphone])` becomes `deploymentTargets: .iOS("17.0")`.
- Leave `App/Sources/MigrateCandidateApp.swift` and
  `App/Tests/AppTests.swift` byte-identical — no breaking change in this
  jump touches source files, only manifests.
- Update whatever version-pin source names 3.42.2 for this fixture (this
  repository's own `.github/workflows/validate-fixtures.yml` matrix
  entry, if the fixture is migrated in place — see that file's
  `migrate-candidate` entry) to 4.206.0.

## What must NOT change

- `App/Sources/MigrateCandidateApp.swift` (no source-level breaking
  change in this jump).
- `App/Tests/AppTests.swift` (same).
- The app's bundle ID, target names, and test's dependency on `App`.

## Manual validation (not run by the outer CI matrix)

1. `mise exec tuist@3.42.2 -- tuist generate --no-open` succeeds from this
   directory as committed.
2. `xcodebuild -workspace MigrateCandidate.xcworkspace -scheme App
   -destination 'generic/platform=iOS Simulator' build` succeeds.
3. Applying the migration described above, then `mise exec tuist@4.206.0
   -- tuist generate --no-open` succeeds.
4. The same `xcodebuild build` and an `xcodebuild test` for scheme `App`
   succeed post-migration.

CI (`validate-fixtures.yml`) only proves step 1's pre-migration state is
real and buildable at 3.42.2 — steps 3–4 are `ios-tuist-migrate`'s own
Validation step, exercised when the skill actually runs, per the v0.3
spec §4.2.
