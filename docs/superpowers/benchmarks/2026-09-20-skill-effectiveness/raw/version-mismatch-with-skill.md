# Comparison 3 — `version-mismatch` — with-skill

## Task prompt

> Add a simple settings screen to this project.

## Condition

Real `claude --plugin-dir /Users/dave/Documents/GitHub/ios-tuist-skills`
session, run by the user in the `.worktrees/benchmark-with-skill`
worktree, fixture freshly reset beforehand via
`scripts/benchmark-prep-run.sh version-mismatch`.

## Fixture

`tests/fixtures/version-mismatch/` — project-pinned Tuist version
`4.62.0` (via `.tool-versions`), deliberately different from other
versions present on the authoring machine (`4.206.0` installed,
`4.194.1` as the machine's global `mise` default).

## What this response did

This is the fixture whose entire purpose is to test whether a
version-mismatch gets silently glossed over. The response:

- Detected the project pin (`4.62.0` via `.tool-versions`) as the
  highest-priority version source.
- **Explicitly detected and reported the mismatch**: pinned 4.62.0 ≠
  machine-available versions (4.206.0 installed, 4.194.1 global
  default) — flagged with a ⚠️ marker in both Version Context and
  Risks/Follow-up.
- Ran every validation command through `mise exec tuist@4.62.0 --`,
  i.e. explicitly pinned to the *project's* version rather than
  whatever was ambiently active — the pinned version was authoritative
  for all manifest syntax choices, per the fixture's own expected
  behavior.
- Did not install/switch/upgrade/downgrade Tuist — confirmed via `git
  status` that `.tool-versions` and `Tuist.swift` were untouched.
- Added `SettingsView.swift` inside the existing `App` target's
  `sources: ["App/Sources/**"]` glob — no manifest change needed since
  the existing convention already covers it.
- Explicitly declined to introduce a new feature target or scaffold
  structure, reasoning that a single-feature, non-repeating case
  doesn't justify one — direct scope discipline reasoning stated in
  the report, not just implied by the diff.
- Added one new test (`testSettingsViewBuilds`) matching the existing
  XCTest convention.
- Disclosed as an "Unverified Item" that it could not independently
  reproduce whether 4.206.0 was literally the exact "authoring time
  active version" `EXPECTATIONS.md` claims — inferred from current
  machine state rather than asserted as directly verified.

## Real verification performed (as reported, all run via `mise exec tuist@4.62.0 --`)

```
$ tuist install
success

$ tuist generate --no-open
success

$ xcodebuild build (App, iOS Simulator)
BUILD SUCCEEDED

$ xcodebuild test (AppTests, iPhone 17 / iOS 26.0)
TEST SUCCEEDED — 2 tests, 0 failures
```

## `git diff`

```diff
diff --git a/tests/fixtures/version-mismatch/App/Sources/VersionMismatchApp.swift b/tests/fixtures/version-mismatch/App/Sources/VersionMismatchApp.swift
index 969f7dc..46b44a8 100644
--- a/tests/fixtures/version-mismatch/App/Sources/VersionMismatchApp.swift
+++ b/tests/fixtures/version-mismatch/App/Sources/VersionMismatchApp.swift
@@ -4,8 +4,7 @@ import SwiftUI
 struct VersionMismatchApp: App {
     var body: some Scene {
         WindowGroup {
-            Text(SettingsTitle.value)
-                .padding()
+            SettingsView()
         }
     }
 }
diff --git a/tests/fixtures/version-mismatch/App/Tests/AppTests.swift b/tests/fixtures/version-mismatch/App/Tests/AppTests.swift
index 711c500..42d0e45 100644
--- a/tests/fixtures/version-mismatch/App/Tests/AppTests.swift
+++ b/tests/fixtures/version-mismatch/App/Tests/AppTests.swift
@@ -5,4 +5,8 @@ final class AppTests: XCTestCase {
     func testSettingsTitleIsStable() {
         XCTAssertEqual(SettingsTitle.value, "Settings")
     }
+
+    func testSettingsViewBuilds() {
+        _ = SettingsView()
+    }
 }
```
Plus new untracked file: `App/Sources/SettingsView.swift`.

## Comparison to contaminated baseline (`version-mismatch-baseline.md`)

| Aspect | Baseline (contaminated) | With-skill |
|---|---|---|
| Version-mismatch detection | Never explicitly surfaced in the response, even though `mise` resolved the pin correctly under the hood | **Explicitly detected and flagged** the mismatch with a ⚠️ marker, in both Version Context and Risks sections |
| Manifest syntax authority | Not discussed | Explicitly stated the pinned version (4.62.0) — not the active/installed version — was authoritative for manifest syntax |
| Scope discipline | Added SettingsView + tests, no explicit reasoning about feature-module vs. inline placement | Same placement decision, but with explicit stated reasoning ("no repeating pattern to justify a new module/scaffold") |
| Output legibility | Prose | Full Output Contract, explicit ⚠️ markers on the risk this fixture is designed to test |

This is the clearest divergence captured so far: this fixture's stated
purpose (per its own `EXPECTATIONS.md`) is specifically to test whether
version mismatch goes unreported — the contaminated baseline's own
generation process never surfaced it, while the with-skill run did,
unprompted.

## Rubric scoring — NOT PERFORMED

Deferred to the batch scoring pass after all 14 with-skill runs are
captured.

## Real-artifact pass/fail

| Axis | Result |
|---|---|
| BUILD | PASS |
| TEST | PASS (2/2) |
