# Comparison 2 — `legacy-tuist` — baseline (REAL, but partially skill-aware)

Real baseline: fresh `claude` session (no `--plugin-dir`), run by the
user in `.worktrees/benchmark-baseline`.

> **⚠️ Partial-awareness caveat (distinct from "contaminated"):** unlike
> comparison 1's fully naive session, this session — while never having
> `ios-tuist-skills` loaded via `--plugin-dir` — read this repo's own
> project memory/CLAUDE.md context (the "Implementation ownership" note
> about Claude doing spec+plan only, Codex implementing) and, from that,
> **inferred the existence and name of `ios-tuist-feature`**, correctly
> identified this fixture as that skill's benchmark target, and asked
> the user whether to explicitly invoke it. The user redirected it to
> proceed without invoking the skill (option 2: "일반적인 방식으로 직접
> 구현"). The resulting implementation is therefore a genuine
> **non-skill-invoked** response, but the session's own awareness that
> a matching skill exists (even though it wasn't loaded/read) is a
> real, if narrower, form of contamination worth flagging — a truly
> isolated baseline session would have no memory/CLAUDE.md context
> exposing the skill's name at all. Scored/read with that caveat in
> mind, not discarded, since the actual code produced was written
> without consulting the skill's content.

*(A separately CONTAMINATED reference exists in
`new-project-baseline-CONTAMINATED.md` for comparison 1 — this file
sits at a different, intermediate point on the contamination spectrum:
name/existence awareness, not content awareness.)*

## Task prompt

> Add LoginFeature.

## Fixture

`tests/fixtures/legacy-tuist/` — real, buildable project using
`sources: ["Sources/**"]`/`resources: ["Resources/**"]`-style array
folder integration, single `App` production target + XCTest target.

## What this response did

- Detected `.tool-versions` pin (4.206.0), used it without modification.
- Inspected the existing convention (array-based `sources`/`resources`,
  XCTest) before proposing anything.
- **Stopped and asked the user** whether to add `LoginFeature` as a
  separate Tuist target (own framework + own XCTest target) or as files
  inside the existing `App` target — presented both options with a
  code-shape preview. User selected "separate target."
- Implemented: new `LoginFeature` (`.staticFramework`) + `LoginFeatureTests`
  (XCTest) targets, `App` gains a single dependency edge on
  `LoginFeature`.
- Preserved array-based sources/resources (no `buildableFolders`
  switch), preserved XCTest (no Swift Testing), did not touch
  `.tool-versions`.
- Explicitly declined to commit the change, left the fixture as a dirty
  working tree with reset instructions given.

## Real verification performed (as reported)

```
$ tuist generate
succeeded

$ xcodebuild build (App scheme, iPhone 17 simulator)
BUILD SUCCEEDED

$ xcodebuild test (App scheme -> AppTests)
PASS

$ xcodebuild test (LoginFeature scheme -> LoginFeatureTests)
PASS
```

## `git diff`

```diff
diff --git a/tests/fixtures/legacy-tuist/Project.swift b/tests/fixtures/legacy-tuist/Project.swift
index 3b53ce2..243536d 100644
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
+            product: .staticFramework,
+            bundleId: "dev.ios-tuist-skills.legacy.loginfeature",
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
+            bundleId: "dev.ios-tuist-skills.legacy.loginfeature-tests",
+            deploymentTargets: .iOS("17.0"),
+            infoPlist: .default,
+            sources: ["LoginFeature/Tests/**"],
+            resources: [],
+            dependencies: [.target(name: "LoginFeature")]
+        ),
     ]
 )
```
Plus new untracked: `LoginFeature/Sources/LoginFeature.swift`,
`LoginFeature/Tests/LoginFeatureTests.swift`.

## Comparison to with-skill (`legacy-tuist-with-skill.md`)

| Aspect | Real baseline (partially skill-aware) | With-skill |
|---|---|---|
| Structural approach | New separate `LoginFeature`/`LoginFeatureTests` targets — **converged on the same shape** as with-skill's run | Same: new separate `LoginFeature`/`LoginFeatureTests` targets |
| Convention preservation | Preserved (array sources/resources, XCTest) | Preserved (same) |
| Version-pin narration | Detected and used `.tool-versions` (4.206.0), but not framed as an explicit "check for mismatch" step | Explicitly detected and confirmed the pin matches active version |
| Structural decision process | Stopped and asked the user which shape to build (target vs. in-place) | Decided independently, no user confirmation step for this choice |
| BUILD/TEST | PASS | PASS |

Notably, this real (if partially skill-name-aware) baseline converged
on the **identical structural shape** the with-skill run chose
independently (new target, not in-App files) — different from the
earlier CONTAMINATED baseline of this same comparison, which chose
files-inside-`App` instead. With N=1 per condition, this is a single
data point, not a trend, but it's worth noting the two real/live
sessions (baseline and with-skill) agreed on structure while the
fully-contaminated one diverged.

## Rubric scoring — NOT PERFORMED

Deferred to the batch scoring pass — should replace
`RUBRIC-SCORES-1-4.md`'s comparison-2 section, which currently scores
the fully-contaminated version.

## Real-artifact pass/fail

| Axis | Result |
|---|---|
| BUILD | PASS |
| TEST (App scheme) | PASS |
| TEST (LoginFeature scheme) | PASS |
| Convention preservation (array sources/resources, XCTest) | PASS |
