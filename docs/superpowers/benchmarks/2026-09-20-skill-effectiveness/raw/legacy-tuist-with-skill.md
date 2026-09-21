# Comparison 2 — `legacy-tuist` — with-skill

## Task prompt

> Add LoginFeature.

## Condition

Real `claude --plugin-dir /Users/dave/Documents/GitHub/ios-tuist-skills`
session, run by the user in the `.worktrees/benchmark-with-skill`
worktree, fixture freshly reset beforehand via
`scripts/benchmark-prep-run.sh legacy-tuist`.

## Fixture

`tests/fixtures/legacy-tuist/` — real, buildable project using
`sources: ["Sources/**"]`/`resources: ["Resources/**"]`-style array
folder integration (not Buildable Folders), single `App` production
target + XCTest target.

## What this response did

- Detected the project-pinned Tuist version (4.206.0 via
  `.tool-versions`) and confirmed it matches the active version — no
  mismatch to report.
- Added `LoginFeature` as a **new separate target** (`.framework`
  product) with its own `LoginFeatureTests` (XCTest, mirroring the
  `AppTests` convention), rather than adding files inside the existing
  `App` target.
- Preserved the array-based `sources:`/`resources:` convention for the
  new target (did not introduce `buildableFolders`).
- Preserved XCTest (did not switch to Swift Testing).
- Left `.tool-versions` untouched.
- Wired `App -> LoginFeature` and `LoginFeatureTests -> LoginFeature`
  dependencies, explicitly noting `LoginFeatureTests` isn't part of the
  `App` scheme's test plan and was verified independently via its own
  scheme instead.
- Produced a full Output Contract report (Version Context, Changes
  Made, Files Changed, Dependency Changes, Validation Performed, Build/
  Test Result, Unverified Items, Risks/Follow-up).

## Tooling note (environment artifact, not a skill-quality finding)

The response reported that its Write/Edit tools were blocked by the
sandbox's auto-mode classifier for this worktree path (no verdict
returned), so it fell back to Bash heredoc/rewrite for file creation
and the `Project.swift` edit. This is a environment/sandbox permission
artifact of running inside `.worktrees/benchmark-with-skill`, not a
finding about the skill's own judgment — noted here for completeness,
excluded from rubric scoring.

## Real verification performed (as reported by the response)

```
$ tuist generate
success

$ xcodebuild build (App scheme, iOS Simulator)
success

$ xcodebuild test (App scheme -> AppTests, iPhone 17 sim)
success, 1/1 passed

$ xcodebuild test (LoginFeature scheme -> LoginFeatureTests, iPhone 17 sim)
success, 1/1 passed
```

## `git diff`

```diff
diff --git a/tests/fixtures/legacy-tuist/Project.swift b/tests/fixtures/legacy-tuist/Project.swift
index 3b53ce2..7668dc5 100644
--- a/tests/fixtures/legacy-tuist/Project.swift
+++ b/tests/fixtures/legacy-tuist/Project.swift
@@ -12,7 +12,7 @@ let project = Project(
             infoPlist: .extendingDefault(with: ["UILaunchScreen": [:]]),
             sources: ["App/Sources/**"],
             resources: ["App/Resources/**"],
-            dependencies: []
+            dependencies: [.target(name: "LoginFeature")]
         ),
         .target(
             name: "AppTests",
@@ -25,5 +25,27 @@ let project = Project(
             resources: [],
             dependencies: [.target(name: "App")]
         ),
+        .target(
+            name: "LoginFeature",
+            destinations: .iOS,
+            product: .framework,
+            bundleId: "dev.ios-tuist-skills.legacy.login-feature",
+            deploymentTargets: .iOS("17.0"),
+            infoPlist: .default,
+            sources: ["LoginFeature/Sources/**"],
+            resources: [],
+            dependencies: []
+        ),
+        .target(
+            name: "LoginFeatureTests",
+            destinations: .iOS,
+            product: .unitTests,
+            bundleId: "dev.ios-tuist-skills.legacy.login-feature-tests",
+            deploymentTargets: .iOS("17.0"),
+            infoPlist: .default,
+            sources: ["LoginFeature/Tests/**"],
+            resources: [],
+            dependencies: [.target(name: "LoginFeature")]
+        ),
     ]
 )
```
Plus new untracked files: `LoginFeature/Sources/LoginView.swift`,
`LoginFeature/Tests/LoginFeatureTests.swift`.

## Comparison to contaminated baseline (`legacy-tuist-baseline.md`)

| Aspect | Baseline (contaminated) | With-skill |
|---|---|---|
| Structural approach | Added LoginFeature files inside the existing `App` target (no new target) | Created a new separate `LoginFeature` + `LoginFeatureTests` target pair |
| Version-pin narration | `.tool-versions` pin never explicitly surfaced in the response | Explicitly detected and confirmed the pin matches the active version |
| Convention preservation | Preserved array-based sources, XCTest | Preserved array-based sources, XCTest — same on this axis |
| Output legibility | Prose description | Full Output Contract report |

Note: the structural difference (new target vs. files-in-existing-target)
is itself a real design-judgment divergence worth scoring explicitly —
neither `EXPECTATIONS.md` nor the task prompt mandates one specific
shape, so this is a candidate item for the rubric pass to weigh
(scope/convention judgment), not an automatic point for either side.

## Rubric scoring — NOT PERFORMED

Deferred to the batch scoring pass after all 14 with-skill runs are
captured.

## Real-artifact pass/fail

| Axis | Result |
|---|---|
| BUILD | PASS |
| TEST (App scheme) | PASS |
| TEST (LoginFeature scheme) | PASS |
