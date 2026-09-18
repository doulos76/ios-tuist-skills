# restyle-candidate

## Starting state

- Pinned Tuist version: **4.206.0** (matches this repository's other
  fixtures; well above the 4.62.0 `buildableFolders` floor).
- Six targets: `App`/`AppTests` (entry point depending on both
  features), `CleanFeature`/`CleanFeatureTests`, `ExcludeFeature`/
  `ExcludeFeatureTests`.
- All targets use array-based `sources:`/`resources:` — none use
  `buildableFolders` as committed.
- Verified live: `tuist generate --no-open` succeeds; `xcodebuild build`
  for scheme `App` succeeds; `ExcludeFeature/Sources/Preview/
  PreviewOnly.swift` (which references a nonexistent type) is correctly
  omitted from compilation by its `.glob(excluding:)` pattern — proving
  the exclusion is real and load-bearing, not decorative.

## `CleanFeature`: the checklist-clear conversion candidate

- Plain `sources: ["CleanFeature/Sources/**"]` and
  `resources: ["CleanFeature/Resources/**"]` — no exclude patterns, no
  per-file flags.
- No other target references an individual file inside
  `CleanFeature/Sources/**` or `CleanFeature/Resources/**` — only a
  whole-target dependency (`App` and `CleanFeatureTests` both depend on
  the `CleanFeature` target itself, never an individual file inside it).
- No directory overlap with any other target's `sources:`/`resources:`/
  `buildableFolders` paths.
- No generated/derived sources — every file under `CleanFeature/` is a
  plain committed file.
- **Note on the static-framework + resources checklist item:**
  `CleanFeature`'s `product:` is `.staticFramework` and it DOES declare
  `resources:` — the exact combination tuist/tuist#8547 flags as a real,
  currently-open defect (buildable-folder resources landing on the
  framework instead of the consuming app's generated bundle). This
  fixture deliberately keeps that combination so `ios-tuist-restyle`
  must reason about this checklist item explicitly (checked, not
  skipped) rather than never encountering it. Verified live: converting
  `CleanFeature` to `buildableFolders: ["CleanFeature/Sources",
  "CleanFeature/Resources"]` still generates, builds, and passes
  `xcodebuild test -scheme CleanFeature` successfully in this fixture's
  specific case — tuist/tuist#8547 is about resource *runtime
  placement* inside the built bundle, not generate/build/test success,
  so this fixture cannot itself prove the bug is absent or present; a
  real invocation of `ios-tuist-restyle` against a project where this
  matters should still report the risk per the skill's Decision Rules,
  it just doesn't happen to manifest as a build/test failure in this
  fixture's minimal case.

## `ExcludeFeature`: the checklist-failing conversion candidate

- `sources: [.glob("ExcludeFeature/Sources/**", excluding:
  ["ExcludeFeature/Sources/Preview/**"])]` — a real Tuist exclusion
  pattern with no `buildableFolders` equivalent.
- `ios-tuist-restyle` is expected to refuse converting `ExcludeFeature`,
  citing this exact exclude pattern, and make no changes to its
  manifest declaration.

## What `ios-tuist-restyle` is expected to do against this fixture

Given a request naming both `CleanFeature` and `ExcludeFeature`:

- Convert `CleanFeature`: `Project.swift`'s `CleanFeature` target's
  `sources: ["CleanFeature/Sources/**"], resources:
  ["CleanFeature/Resources/**"]` replaced with `buildableFolders:
  ["CleanFeature/Sources", "CleanFeature/Resources"]`.
- Refuse `ExcludeFeature`: no changes to its manifest declaration;
  report cites the `.glob(excluding:)` pattern as the reason.
- Leave `App`, `AppTests`, `CleanFeatureTests`, `ExcludeFeatureTests`
  manifest declarations and all source/resource file contents
  byte-identical.

## What must NOT change

- Any `.swift` source file's contents (including
  `ExcludeFeature/Sources/Preview/PreviewOnly.swift`, which must remain
  excluded and unmodified).
- `CleanFeature/Resources/dummy.txt`'s contents.
- `ExcludeFeature`'s manifest declaration (refused, so untouched).
- `App`, `AppTests`, `CleanFeatureTests`, `ExcludeFeatureTests` manifest
  declarations (not named in the request, so untouched).
- Bundle IDs, target names, and dependency edges.

## Manual validation (not run by the outer CI matrix)

1. `mise exec tuist@4.206.0 -- tuist install` and `tuist generate
   --no-open` succeed from this directory as committed.
2. `xcodebuild -workspace RestyleCandidate.xcworkspace -scheme App
   -destination 'generic/platform=iOS Simulator' build` succeeds.
3. Applying `ios-tuist-restyle`'s conversion to `CleanFeature` only,
   then `tuist generate --no-open` succeeds, `xcodebuild build` for
   scheme `App` succeeds, and `xcodebuild test -scheme CleanFeature`
   succeeds.
4. `ExcludeFeature`'s manifest and behavior are unchanged throughout.

CI (`validate-fixtures.yml`) only proves step 1–2's pre-conversion state
is real and buildable at 4.206.0 — steps 3–4 are `ios-tuist-restyle`'s
own Validation step, exercised when the skill actually runs, per the
v0.4 spec §4.2.
