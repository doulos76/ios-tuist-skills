# Comparison 10b — `test-target-candidate` (FeatureB) — with-skill

## Task prompt

> Create a unit test target for FeatureB and wire it into the existing App scheme.

## Condition

Real `claude --plugin-dir /Users/dave/Documents/GitHub/ios-tuist-skills`
session, run by the user in the `.worktrees/benchmark-with-skill`
worktree, fixture freshly reset beforehand via
`scripts/benchmark-prep-run.sh test-target-candidate featureb`.

## Fixture

`tests/fixtures/test-target-candidate/` — `FeatureB` has no test
target yet, and is not present in the custom `App` scheme's
`testAction`.

## What this response did

- Confirmed the project-pinned Tuist version (4.206.0) matches active.
- Checked for an existing `FeatureBTests` target first, found none.
- Created `FeatureBTests` (`product: .unitTests`, depends on
  `FeatureB`, `sources: ["FeatureB/Tests/**"]`) with one labeled
  placeholder test.
- **Explicitly chose Swift Testing** as the framework, reasoning that
  the applicable sibling-feature precedent is `FeatureATests` (which
  uses Swift Testing), not `AppTests` (XCTest) — correctly identified
  the more specific convention to match rather than defaulting to the
  first one found.
- **Appended** `"FeatureBTests"` to the `App` scheme's `testAction`
  target list alongside the existing `"AppTests"`/`"FeatureATests"`
  entries — did not replace the list.
- Confirmed via `git diff` that `App`, `AppTests`, `FeatureA`,
  `FeatureATests` declarations and all their source files are
  byte-identical to before.
- Disclosed the placeholder test's actual scope: "proves wiring only —
  no real FeatureB coverage exists yet," and explicitly deferred adding
  real test cases to `ios-tuist-feature`'s job, on request.

## Real verification performed (as reported)

```
$ tuist install
success

$ tuist generate --no-open
success

$ xcodebuild build -scheme App -destination generic/iOS Simulator
BUILD SUCCEEDED

$ xcodebuild test -scheme App -destination 'iPhone 17 Pro / iOS 26.0'
TEST SUCCEEDED — AppTests, FeatureATests, and FeatureBTestsPlaceholder all passed
```

## `git diff`

```diff
diff --git a/tests/fixtures/test-target-candidate/Project.swift b/tests/fixtures/test-target-candidate/Project.swift
index 55bbb3c..032e038 100644
--- a/tests/fixtures/test-target-candidate/Project.swift
+++ b/tests/fixtures/test-target-candidate/Project.swift
@@ -53,6 +53,16 @@ let project = Project(
             deploymentTargets: .iOS("17.0"),
             infoPlist: .default,
             sources: ["FeatureB/Sources/**"]
+        ),
+        .target(
+            name: "FeatureBTests",
+            destinations: .iOS,
+            product: .unitTests,
+            bundleId: "dev.ios-tuist-skills.test-target-candidate-featureb-tests",
+            deploymentTargets: .iOS("17.0"),
+            infoPlist: .default,
+            sources: ["FeatureB/Tests/**"],
+            dependencies: [.target(name: "FeatureB")]
         )
     ],
     schemes: [
@@ -60,7 +70,7 @@ let project = Project(
             name: "App",
             shared: true,
             buildAction: .buildAction(targets: ["App", "FeatureA", "FeatureB"]),
-            testAction: .targets(["AppTests", "FeatureATests"]),
+            testAction: .targets(["AppTests", "FeatureATests", "FeatureBTests"]),
             runAction: .runAction(configuration: "Debug")
         )
     ]
```
Plus new untracked: `FeatureB/Tests/` (the placeholder test file).

## Comparison to contaminated baseline (`test-target-candidate-featureb-baseline.md`)

| Aspect | Baseline (contaminated) | With-skill |
|---|---|---|
| Target created | `FeatureBTests` (`.unitTests`), depends on `FeatureB` | Same |
| Scheme wiring | Appended `FeatureBTests` to existing `testAction` list | Same — explicitly confirmed append-not-replace |
| Test framework choice | Swift Testing, inferred from sibling `FeatureA` convention | Swift Testing, explicitly reasoned as matching `FeatureATests` over `AppTests`'s XCTest |
| Scope discipline | App/AppTests/FeatureA/FeatureATests left byte-identical | Same, explicitly confirmed via diff |
| BUILD/TEST | PASS (after one unrelated flaky-simulator retry) | PASS, no retry needed in this run |

Both conditions converged on essentially the same correct shape for
this creation-path scenario — this is expected, since the fixture's
own `EXPECTATIONS.md` documents a fairly mechanical "follow the
sibling's pattern" task once the refusal-vs-create distinction (tested
in 10a) is correctly made.

## Rubric scoring — NOT PERFORMED

Deferred to the batch scoring pass after all 14 with-skill runs are
captured.

## Real-artifact pass/fail

| Axis | Result |
|---|---|
| BUILD | PASS |
| TEST | PASS (AppTests, FeatureATests, FeatureBTestsPlaceholder all passed) |
| Scope discipline | PASS (App/AppTests/FeatureA/FeatureATests confirmed byte-identical) |
