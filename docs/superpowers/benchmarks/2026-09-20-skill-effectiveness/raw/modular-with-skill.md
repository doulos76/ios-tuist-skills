# Comparison 4 — `modular` — with-skill

## Task prompt

> Add Kingfisher only to ProfileFeature.

## Condition

Real `claude --plugin-dir /Users/dave/Documents/GitHub/ios-tuist-skills`
session, run by the user in the `.worktrees/benchmark-with-skill`
worktree, fixture freshly reset beforehand via
`scripts/benchmark-prep-run.sh modular`.

## Fixture

`tests/fixtures/modular/` — real, buildable feature-modular project,
dependency graph `App -> ProfileFeature -> SharedUI`.

## What this response did

- Confirmed project-pinned Tuist (4.206.0) matches active version.
- Created `Tuist/Package.swift` (no prior external-package manifest
  existed) declaring Kingfisher with `from: "7.0.0"` — resolved to
  **7.12.0**.
- Attached Kingfisher via `.external(name: "Kingfisher")` to
  **`ProfileFeature` only** — confirmed via `git diff`: the only
  `Project.swift` change is the one-line addition to `ProfileFeature`'s
  `dependencies:` array. `App` and `SharedUI` untouched.
- Ran `tuist install` (Kingfisher resolved/fetched successfully) and
  `tuist generate --no-open` (success), then `tuist build ProfileFeature`
  and `tuist build App` — both succeeded.
- **Did not run the test schemes** — the response's own report states
  this explicitly under "Unverified Items" rather than silently
  omitting it, and asked the user whether to keep or revert the
  fixture change (correctly treating this benchmark dry-run context as
  something requiring a decision, rather than unilaterally reverting or
  unilaterally committing).

## Real verification performed BY THIS REPORT'S AUTHOR (not the with-skill session itself)

Since the with-skill response explicitly flagged tests as unrun, they
were run independently here, per this benchmark's own verification
discipline (never trust a claim without checking):

```
$ xcodebuild -workspace App.xcworkspace -scheme App \
    -destination 'platform=iOS Simulator,name=iPhone 17' test
Test appProvidesAnInitialProfileName() passed
** TEST SUCCEEDED **

$ xcodebuild -workspace App.xcworkspace -scheme ProfileFeature \
    -destination 'platform=iOS Simulator,name=iPhone 17' test
Test profileGreetingIncludesTheName() passed
** TEST SUCCEEDED **

$ xcodebuild -workspace App.xcworkspace -scheme SharedUITests \
    -destination 'platform=iOS Simulator,name=iPhone 17' test
Test badgeLabelsAreUppercased() passed
** TEST SUCCEEDED **
```

All three schemes named in `EXPECTATIONS.md`'s "How to check" section
(App, ProfileFeature, SharedUITests) pass.

## `git diff`

```diff
diff --git a/tests/fixtures/modular/Project.swift b/tests/fixtures/modular/Project.swift
index f4dd3e5..a28a092 100644
--- a/tests/fixtures/modular/Project.swift
+++ b/tests/fixtures/modular/Project.swift
@@ -31,7 +31,7 @@ let project = Project(
             deploymentTargets: .iOS("17.0"),
             infoPlist: .default,
             buildableFolders: ["ProfileFeature/Sources"],
-            dependencies: [.target(name: "SharedUI")]
+            dependencies: [.target(name: "SharedUI"), .external(name: "Kingfisher")]
         ),
```
Plus new: `Tuist/Package.swift` (declares Kingfisher `from: "7.0.0"`),
`Tuist/Package.resolved` (pins resolved `Kingfisher` revision), and
`Tuist/.build/` (resolution cache, not meaningful content).

## Comparison to contaminated baseline (`modular-baseline.md`)

| Aspect | Baseline (contaminated) | With-skill |
|---|---|---|
| Scope discipline | Correct — only ProfileFeature touched | Correct — only ProfileFeature touched |
| Kingfisher version constraint | Not specified/pinned in the way that led to 8.12.0 resolving | `from: "7.0.0"` explicitly specified, resolved to 7.12.0 |
| **BUILD result** | **FAIL** — Kingfisher 8.12.0's manifest requires `.iOS(.v13)`+, incompatible with this toolchain's floor as attempted | **PASS** — 7.x line avoided the incompatibility entirely |
| TEST result | FAIL (blocked by build failure) | PASS (all 3 schemes, verified independently since the with-skill response itself didn't run them) |
| Self-reported unverified items | Not applicable (baseline format doesn't include this section) | Explicitly flagged "tests not run" rather than silently claiming success |

This is the sharpest divergence captured across all 4 with-skill runs
so far: the contaminated baseline produced a **real, reproducible build
failure** by not constraining the dependency version, while the
with-skill run's explicit `from: "7.0.0"` constraint avoided it. Whether
this reflects the skill's own guidance toward being conservative with
new dependency version constraints, or an incidental difference in how
each session phrased the `.package(url:from:)` call, is worth checking
against `references/dependencies.md` during the rubric scoring pass —
but the *outcome* difference (FAIL vs. PASS on a real `xcodebuild`
invocation) is not in question; both were independently re-verified.

## Rubric scoring — NOT PERFORMED

Deferred to the batch scoring pass after all 14 with-skill runs are
captured.

## Real-artifact pass/fail

| Axis | Result |
|---|---|
| BUILD (ProfileFeature, App) | PASS |
| TEST (App, ProfileFeature, SharedUITests) | PASS (verified independently — response itself left this unverified) |
| Scope discipline (git diff limited to ProfileFeature) | PASS |
