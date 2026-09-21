# Comparison 5a — `extract-candidate` (networking) — with-skill

## Task prompt

> Extract the networking code into its own module called NetworkingKit.

## Condition

Real `claude --plugin-dir /Users/dave/Documents/GitHub/ios-tuist-skills`
session, run by the user in the `.worktrees/benchmark-with-skill`
worktree, fixture freshly reset beforehand via
`scripts/benchmark-prep-run.sh extract-candidate networking`.

## Fixture

`tests/fixtures/extract-candidate/` — single-target `App` containing
`Networking.swift` (dependency-free, independently testable) and
`SettingsRow.swift` (a one-off view, exercised in the sibling
`settingsrow` scenario, untouched here).

## What this response did

- Explicitly invoked `ios-tuist-skills:ios-tuist-module` before acting.
- Applied `references/modularization.md`'s checklist **concretely**,
  item by item, with a stated verdict per item (ownership boundary,
  dependency direction, reusability, compile-time isolation, test
  boundary, resource ownership, public API surface, cyclic-dependency
  risk, build cost) before touching any file — matching this fixture's
  own expected behavior ("the checklist... is applied concretely, not
  hypothetically").
- Ran a real version-safety check (searched for `.mise.toml`/
  `.tuist-version` in both the fixture and repo scope, found none,
  correctly treated the active installed version as authoritative with
  no mismatch to report).
- Extracted `Networking.swift` into a new `NetworkingKit`
  (`.staticFramework`) target via `git mv`, moved the test with the
  code (renamed `AppTests.swift` → `NetworkingKitTests.swift`,
  `@testable import App` → `@testable import NetworkingKit`).
- **Hit a real consequence of the extraction**: `AppTests` would be left
  with zero files after the move. Rather than silently deleting the
  target or silently leaving an empty/invalid one, it **stopped and
  asked the user** via an explicit multiple-choice question
  ("Remove AppTests target (Recommended)" vs. "Keep AppTests target,
  empty") before proceeding — the user selected removal.
- After confirmation, removed the `AppTests` target from `Project.swift`
  and deleted the empty `AppTests.swift` file.
- Explicitly reasoned about the linkage choice (`.staticFramework`):
  no existing convention to match (single-target starting state), no
  resources/extensions/external binaries, single consumer — static
  chosen to avoid dynamic-linking startup cost.
- `SettingsRow.swift` and `ExtractCandidateApp.swift` explicitly
  reported as untouched.

## Real verification performed (as reported)

```
$ tuist install
success

$ tuist generate --no-open
success

$ xcodebuild build (scheme App, iOS Simulator)
BUILD SUCCEEDED (also builds NetworkingKit transitively)

$ xcodebuild test (scheme NetworkingKit, iOS Simulator)
TEST SUCCEEDED — requestBuilderComposesProfilePath passed
```

## `git diff`

```
R  App/Sources/Networking.swift -> NetworkingKit/Sources/Networking.swift
R  App/Tests/AppTests.swift -> NetworkingKit/Tests/NetworkingKitTests.swift
M  Project.swift
```

```diff
diff --git a/tests/fixtures/extract-candidate/Project.swift b/tests/fixtures/extract-candidate/Project.swift
index 3c04083..da813b8 100644
--- a/tests/fixtures/extract-candidate/Project.swift
+++ b/tests/fixtures/extract-candidate/Project.swift
@@ -11,17 +11,27 @@ let project = Project(
             deploymentTargets: .iOS("17.0"),
             infoPlist: .extendingDefault(with: ["UILaunchScreen": [:]]),
             buildableFolders: ["App/Sources"],
+            dependencies: [.target(name: "NetworkingKit")]
+        ),
+        .target(
+            name: "NetworkingKit",
+            destinations: .iOS,
+            product: .staticFramework,
+            bundleId: "dev.ios-tuist-skills.extract-candidate-networkingkit",
+            deploymentTargets: .iOS("17.0"),
+            infoPlist: .default,
+            buildableFolders: ["NetworkingKit/Sources"],
             dependencies: []
         ),
         .target(
-            name: "AppTests",
+            name: "NetworkingKitTests",
             destinations: .iOS,
             product: .unitTests,
-            bundleId: "dev.ios-tuist-skills.extract-candidate-tests",
+            bundleId: "dev.ios-tuist-skills.extract-candidate-networkingkit-tests",
             deploymentTargets: .iOS("17.0"),
             infoPlist: .default,
-            buildableFolders: ["App/Tests"],
-            dependencies: [.target(name: "App")]
+            buildableFolders: ["NetworkingKit/Tests"],
+            dependencies: [.target(name: "NetworkingKit")]
         ),
     ]
 )
```

## Comparison to contaminated baseline (`extract-candidate-networking-baseline.md`)

| Aspect | Baseline (contaminated) | With-skill |
|---|---|---|
| Checklist application | Formed independent judgment, reached the same conclusion (warranted) | Applied `modularization.md`'s checklist explicitly, item-by-item, with a stated verdict per item |
| Empty-AppTests consequence | Removed the target unilaterally ("a forced consequence") | **Stopped and asked the user** for an explicit decision before removing it |
| Version-safety check | Not explicitly narrated as a distinct step | Explicit search for pin files, explicit "no mismatch" conclusion stated |
| Final structure | NetworkingKit + NetworkingKitTests, AppTests removed, no speculative App→NetworkingKit edge noted as deliberately avoided | Same final structure, but App *does* depend on NetworkingKit (necessary since App's own code presumably still needs the networking layer — the baseline explicitly chose not to add this edge since nothing in App imports it yet, a difference worth checking against actual `ExtractCandidateApp.swift` usage during scoring) |
| BUILD/TEST | PASS | PASS |

The most concrete axis-5-relevant (verification/claim discipline) and
process-quality difference here is the **explicit human-in-the-loop
confirmation** before removing the emptied `AppTests` target — this is
exactly the kind of decision-point transparency the rubric's items 3
(refusal/decision correctness) and 7 (output legibility) are meant to
reward, versus a silent unilateral choice.

## Rubric scoring — NOT PERFORMED

Deferred to the batch scoring pass after all 14 with-skill runs are
captured.

## Real-artifact pass/fail

| Axis | Result |
|---|---|
| BUILD | PASS |
| TEST | PASS (1/1) |
| Scope discipline | PASS (only Networking.swift/AppTests-derived files touched; SettingsRow/App entry point untouched) |
