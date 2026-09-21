# Comparison 8 — `migrate-candidate` — with-skill

## Task prompt

> Migrate this project's Tuist manifests from 3.42.2 to 4.206.0.

## Condition

Real `claude --plugin-dir /Users/dave/Documents/GitHub/ios-tuist-skills`
session, run by the user in the `.worktrees/benchmark-with-skill`
worktree, fixture freshly reset beforehand via
`scripts/benchmark-prep-run.sh migrate-candidate`.

## Fixture

`tests/fixtures/migrate-candidate/` — Tuist 3.42.2 project using
`Tuist/Config.swift` and the 3.x `Target(name:platform:...)`
member-wise initializer, which does not compile under Tuist 4.x.

## Note on scope: a mid-run correction

The response's initial migration plan proposed also updating
`.github/workflows/validate-fixtures.yml`'s `migrate-candidate` matrix
entry (Tuist version pin + `resolve_cmd`). **This file is this repo's
own real CI configuration, not part of the `migrate-candidate` fixture
itself** — editing it would have been an unwanted side effect of
running this benchmark (a benchmark run should never touch the host
repo's actual operational files). The report's author selected "Apply
manifests only, skip CI workflow edit" from the response's own
presented options when this was noticed, and the response respected
that scope boundary exactly — see "Risks/Follow-up" below, where it
explicitly flagged the resulting pin mismatch as a consequence of that
choice rather than silently reconciling it.

## What this response did

- Established a real Tuist Context baseline **before** proposing
  anything: confirmed `.tool-versions`-free but
  `.github/workflows/validate-fixtures.yml`'s matrix entry and
  `Tuist/Config.swift`'s 3.x `Config` type both point to 3.42.2;
  validated the pre-migration state under 3.42.2 for real (`tuist
  fetch`, `tuist generate`, `xcodebuild build` all passed) before
  touching anything.
- Researched the breaking-change surface from **Tuist's own migration
  guide** (`references/migrations/from-v3-to-v4.md`) and live evidence
  (running `tuist version` under 4.206.0 against the unmigrated project
  to capture the actual deprecation warning text), not from memory —
  cited both sources explicitly per finding.
- **Presented a full migration plan and stopped for explicit approval**
  before editing anything — listed every breaking change with its
  source, every file to be touched, and explicitly what would NOT be
  touched (source files, target/bundle-ID names, `buildableFolders`
  adoption left as a style choice not forced by the migration).
- After approval (scoped to manifests only, per the mid-run correction
  above), applied:
  - `Tuist/Config.swift` → `Tuist/Tuist.swift`
    (`Config(...)` → `Tuist(...)`).
  - Both `Target(name:platform:...)` calls → `.target(name:
    destinations:...)`, `platform: .iOS` → `destinations: .iOS`,
    `deploymentTarget: .iOS(targetVersion:...)` →
    `deploymentTargets: .iOS(...)`.
  - Source files (`MigrateCandidateApp.swift`, `AppTests.swift`)
    confirmed untouched via `git status`.
- Validated **both** pre- and post-migration states for real (not just
  the end state): 3.42.2 baseline (`tuist fetch`/`generate`/`build` all
  PASS) and 4.206.0 post-migration (`tuist install`/`generate`/`build`/
  `test` all PASS, 1/1 test).
- Explicitly flagged, unprompted, that the CI workflow's matrix entry
  now mismatches the manifests (still pins 3.42.2 + `fetch`) as a
  direct, named consequence of the scope choice — not hidden.
- Did not commit the change, explicitly leaving that decision to the
  user.

## Real verification performed (as reported)

```
Before (3.42.2):
$ tuist fetch        -> success
$ tuist generate --no-open -> success
$ xcodebuild build    -> BUILD SUCCEEDED

After (4.206.0):
$ tuist install       -> success
$ tuist generate --no-open -> success (no warnings)
$ xcodebuild build    -> BUILD SUCCEEDED
$ xcodebuild test     -> TEST SUCCEEDED (1/1 passed)
```

## `git diff`

```diff
diff --git a/tests/fixtures/migrate-candidate/Project.swift b/tests/fixtures/migrate-candidate/Project.swift
index 9566bd9..984a305 100644
--- a/tests/fixtures/migrate-candidate/Project.swift
+++ b/tests/fixtures/migrate-candidate/Project.swift
@@ -3,21 +3,21 @@ import ProjectDescription
 let project = Project(
     name: "MigrateCandidate",
     targets: [
-        Target(
+        .target(
             name: "App",
-            platform: .iOS,
+            destinations: .iOS,
             product: .app,
             bundleId: "dev.ios-tuist-skills.migrate-candidate",
-            deploymentTarget: .iOS(targetVersion: "17.0", devices: [.iphone]),
+            deploymentTargets: .iOS("17.0"),
             infoPlist: .default,
             sources: ["App/Sources/**"]
         ),
-        Target(
+        .target(
             name: "AppTests",
-            platform: .iOS,
+            destinations: .iOS,
             product: .unitTests,
             bundleId: "dev.ios-tuist-skills.migrate-candidate-tests",
-            deploymentTarget: .iOS(targetVersion: "17.0", devices: [.iphone]),
+            deploymentTargets: .iOS("17.0"),
             infoPlist: .default,
             sources: ["App/Tests/**"],
             dependencies: [
```
Plus: `Tuist/Config.swift` renamed to `Tuist/Tuist.swift`
(`Config(...)` → `Tuist(...)`). `.github/workflows/validate-fixtures.yml`
**untouched**, per the scope correction above.

## Comparison to contaminated baseline (`migrate-candidate-baseline.md`)

| Aspect | Baseline (contaminated) | With-skill |
|---|---|---|
| Pre/post verification | Verified both states | Verified both states, plus captured the live 4.x deprecation-warning text as evidence rather than only citing the migration guide |
| Approve-before-apply | Applied directly (no plan/approval step reported) | Presented a full plan with explicit approval gate before any edit |
| Scope | Manifests only | Manifests only — but only *after* a scope correction; the initial plan would have also touched this repo's real CI config, a boundary the baseline never had occasion to cross since it wasn't asked to |
| Post-migration validation | BUILD/TEST PASS | BUILD/TEST PASS |
| Consequence disclosure | Not applicable (CI file not touched by baseline in the first place) | Explicitly named the resulting CI-pin mismatch as a stated, unresolved follow-up |

## Rubric scoring — NOT PERFORMED

Deferred to the batch scoring pass after all 14 with-skill runs are
captured.

## Real-artifact pass/fail

| Axis | Result |
|---|---|
| BUILD (post-migration, 4.206.0) | PASS |
| TEST (post-migration, 4.206.0) | PASS (1/1) |
| Scope discipline (fixture manifests only, host repo CI file untouched) | PASS |
