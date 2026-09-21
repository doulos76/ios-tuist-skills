# Comparison 1 — `new-project` — with-skill

## Task prompt

> Create a new SwiftUI iOS app using Tuist with a feature-modular structure.

## Condition

Real `claude --plugin-dir /Users/dave/Documents/GitHub/ios-tuist-skills`
session, run by the user in the `.worktrees/benchmark-with-skill`
worktree, fixture freshly reset beforehand via
`scripts/benchmark-prep-run.sh new-project`.

## Fixture

`tests/fixtures/new-project/` (empty starting state — only
`EXPECTATIONS.md` and `.gitkeep` existed before this run).

## What this response did

- Explicitly invoked `ios-tuist-skills:ios-tuist-bootstrap` before
  taking any action.
- Ran a real Tuist Context detection pass: searched for a
  project-pinned version (`mise.toml`, `.tool-versions`, `Tuist.swift`,
  `Package.swift` — none found, correctly treated as "none detected"
  rather than assumed), then ran `tuist version` / `xcodebuild
  -version` / `swift --version` live to establish the active toolchain
  (Tuist 4.206.0, Xcode 27.0, Swift 6.4).
- Explicitly reported that active Tuist matches the version the
  `templates/feature-modular/` profile was authored/verified against —
  a real version-alignment check, not an assumption.
- Used this repo's own `templates/feature-modular/` profile as-is,
  copying its structure (`App` → `ExampleFeature`, one-way dependency,
  each with its own Swift Testing target) rather than inventing a
  structure from scratch.
- No `Workspace.swift`, no `Config.swift` — matches
  `references/source-of-truth.md`'s rules.
- Produced a full Output Contract report: Version Context, Changes
  Made, Files Changed, Dependency Changes, Validation Performed
  (with real command output cited), Build Result, Test Result,
  Unverified Items, Risks/Follow-up.
- Flagged, unprompted, that no project-pinned Tuist version exists yet
  and recommended adding one for reproducibility — did not add it
  itself since it wasn't requested (correct scope discipline).
- Noted the originally-authored destination (iPhone 17, OS 26.5) wasn't
  available locally and substituted an available iPhone 17 runtime
  instead, disclosing this as an "Unverified Items" entry rather than
  silently substituting.

## Real verification performed (as reported by the response, all commands actually run)

```
$ tuist install
✔ Success — Plugins resolved and fetched successfully.

$ tuist generate --no-open
✔ Success — Project generated.

$ xcodebuild -workspace App.xcworkspace -scheme App \
    -destination 'generic/platform=iOS Simulator' build
** BUILD SUCCEEDED **

$ xcodebuild test -workspace App.xcworkspace -scheme App \
    -destination 'platform=iOS Simulator,name=iPhone 17'
AppTests: 1/1 passed (rootConfigurationProvidesAName)
** TEST SUCCEEDED **

$ xcodebuild test -workspace App.xcworkspace -scheme ExampleFeature \
    -destination 'platform=iOS Simulator,name=iPhone 17'
ExampleFeatureTests: 1/1 passed (greetingIncludesTheProvidedName)
** TEST SUCCEEDED **
```

Both test targets were run via their own scheme (`App` and
`ExampleFeature` separately) — this response did not encounter the
"feature test silently excluded from the App scheme's testAction" gap
the contaminated baseline hit, because the copied
`templates/feature-modular/` structure appears to have been verified as
a known-good profile in advance (this repo's own template, not
improvised per-run).

## `git diff` (untracked files added)

```
?? tests/fixtures/new-project/App/
?? tests/fixtures/new-project/ExampleFeature/
?? tests/fixtures/new-project/Project.swift
?? tests/fixtures/new-project/Tuist.swift
```

## Comparison to contaminated baseline (`new-project-baseline.md`)

| Aspect | Baseline (contaminated) | With-skill |
|---|---|---|
| Version detection | Used ambient active version, no explicit detection procedure or alignment check | Ran live `tuist version`/`xcodebuild -version`/`swift --version`, explicitly reported alignment with the template's authored version |
| Structure | Invented 4-target structure ad hoc, unaware of this repo's canonical profile | Used `templates/feature-modular/` as-is |
| Test coverage | `HomeFeatureTests` silently excluded from `App` scheme's testAction — under-verified | Both `AppTests` and `ExampleFeatureTests` run via their own schemes, both reported explicitly |
| Output legibility | No structured report — just described actions in prose | Full Output Contract (Version Context / Changes Made / Validation Performed / Unverified Items / Risks) |
| Unverified-item disclosure | None | Explicitly disclosed the simulator-OS substitution as unverified |

## Rubric scoring — NOT PERFORMED

Scoring deferred until all 14 with-skill runs are captured, to score in
one batch per PRD §5.1 methodology (independent scoring, not
pre-deciding which condition "should" win).

## Real-artifact pass/fail

| Axis | Result |
|---|---|
| BUILD | PASS |
| TEST (App scheme) | PASS |
| TEST (ExampleFeature scheme) | PASS |
