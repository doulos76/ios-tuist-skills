# ios-tuist-skills v0.3 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the v0.3 milestone of `ios-tuist-skills`: one new skill,
`ios-tuist-migrate`, that performs the one thing every other skill in
this repository explicitly refuses to do — change a project's pinned
Tuist version — but only on an explicit user request and only for the
minimum manifest syntax that version actually forces. Includes one new
real, buildable fixture proving a genuine breaking change, validated by
CI.

**Architecture:** Same flat plugin repo shape as v0.1/v0.2 — no new
top-level directories. One self-contained `SKILL.md` lands in `skills/
ios-tuist-migrate/`. No shared reference file changes — this skill reads
`version-safety.md` (for detection order) but doesn't need a new shared
procedure; its "research the actual breaking changes live" step is
specific to this one skill and belongs in its own `SKILL.md`, not a
shared reference other skills would never use. One new fixture extends
the existing `.github/workflows/validate-fixtures.yml` matrix job — no
new workflow file.

**Tech Stack:** Tuist 4.206.0 (target version, matches this repo's other
fixtures) and Tuist 3.42.2 (fixture's starting version — verified
installable via `mise install tuist@3.42.2`, confirmed to report exactly
`3.42.2` via `tuist version`), Xcode 27 / Swift 6.4, GitHub Actions
(macOS runner, existing `jdx/mise-action` version-pin pattern), Claude
Code plugin format.

**Spec:** `docs/superpowers/specs/2026-09-18-ios-tuist-skills-v0.3-design.md`

## Global Constraints

- Never hard-code a single Tuist version anywhere in `skills/`content
  (spec §3; carried over from v0.1 spec §10 / v0.2 spec §9) — version
  literals belong only in the fixture and the CI matrix, exactly like
  every other skill in this repo.
- `ios-tuist-migrate` links to `version-safety.md` by relative path for
  its detection-order procedure — never restates it inline (spec §3).
- `SKILL.md` follows the same section structure as the other six skills:
  Purpose, Trigger Conditions, Non-Trigger Conditions, Preconditions,
  Version Safety, Workflow, Decision Rules, Validation, Failure Handling,
  Output Contract (spec §3).
- `ios-tuist-migrate` is the **only** skill in this repository permitted
  to change a project's pinned Tuist version, and only on an explicit,
  version-specific user request — never as a side effect of any other
  skill's mismatch report (spec §3, Non-Trigger Conditions).
- Never bundle a structural/style migration (folder-integration mode,
  linkage strategy, naming convention) into a version migration — only
  the manifest syntax the target version's real breaking changes force
  (spec §1, §3 Decision Rules, §6).
- No downgrade support — forward migration only; a downgrade request is a
  refusal, not an error (spec §3 Non-Trigger Conditions, §6).
- Fixtures under `tests/fixtures/` must be real, independently buildable
  Tuist projects — not structure-only stand-ins (spec §4.1).
- The new fixture joins the existing `validate-fixtures.yml` matrix (one
  job, extended) — do not create a second CI workflow file (spec §4.2).
- **GitHub Actions credit is currently exhausted on this repository's
  account** (confirmed 2026-09-18: every recent `validate-fixtures.yml`
  run fails in ~10s with zero steps executed — a billing/spend-limit
  block, not a code defect). Every task below that would normally end
  with "push and confirm CI is green" instead ends with **local**
  validation: run the exact same `mise`/`tuist`/`xcodebuild` commands the
  workflow file runs, directly, and treat their real output as the
  evidence. Do not skip validation — substitute its mechanism. Do not
  push to `origin` until told to; commit locally and stop, same as this
  repository's established Codex/Claude ownership split for
  implementation vs. publishing decisions.
- MIT license header style is not required per-file; `LICENSE` at repo
  root already covers the whole repo.

---

### Task 1: `ios-tuist-migrate` skill

**Files:**
- Create: `skills/ios-tuist-migrate/SKILL.md`
- Create: `skills/ios-tuist-migrate/references/.gitkeep`

**Interfaces:**
- Consumes: `references/version-safety.md` (detection order, authority
  rule, the "explicit user-requested migration" exception it already
  names).
- Produces: nothing later tasks import structurally — Task 2's fixture
  is validated independently against this skill's Output Contract shape,
  not linked to it in code.

- [ ] **Step 1: Create the skill directory and empty references folder**

```bash
mkdir -p skills/ios-tuist-migrate/references
touch skills/ios-tuist-migrate/references/.gitkeep
```

- [ ] **Step 2: Write `skills/ios-tuist-migrate/SKILL.md`**

Create with this exact content:

```markdown
---
name: ios-tuist-migrate
description: >
  Moves a project's pinned Tuist version forward to a user-specified
  target version, updating version-pin sources and the minimum manifest
  syntax the target version actually requires. The only skill in this
  repository permitted to change a project's Tuist version pin, and only
  on an explicit, version-specific request.
---

# Core Rule

Never migrate to a version the user didn't name or confirm. Never bundle
a structural/style change into a version migration — apply exactly what
the target version's real breaking changes force, nothing more.

## Purpose

Move a project's pinned Tuist version forward to a user-specified target
version: update the version-pin sources
([version-safety](../../references/version-safety.md) detection order)
and the minimum set of manifest syntax changes the target version
actually requires.

## Trigger Conditions

- "Upgrade Tuist to 4.x"
- "Migrate this project from Tuist 3 to Tuist 4"
- "Bump our pinned Tuist version"

The request must name or clearly imply a specific target version.

## Non-Trigger Conditions

- No target version is named or impliable from the request — ask for one
  rather than choosing a version to migrate to.
- The request is really about a structural/style convention (e.g. "move
  us to buildableFolders") with no version driver — out of scope; state
  this explicitly rather than bundling a style change into a version
  bump.
- No existing Tuist project (nothing to migrate — see
  `ios-tuist-bootstrap` for a new one).
- The active installed Tuist version simply differs from the
  project-pinned version with no user request to change the pin — that's
  a mismatch to *report* via the normal
  [version-safety](../../references/version-safety.md) procedure in
  whichever skill surfaced it, not an implicit invitation for this skill
  to run.

## Preconditions

An existing Tuist project is present and readable; a target Tuist
version is specified; the current project-pinned version is
determinable via [version-safety](../../references/version-safety.md)'s
detection order.

## Version Safety

This is the one skill in the repository permitted to change the outcome
of [version-safety](../../references/version-safety.md)'s detection
order — every other skill treats the project-pinned version as fixed;
this skill's entire job is changing it, deliberately and visibly. Still
apply the full detection procedure first: an accurate starting point is
required to know what actually needs to change between the two versions.

## Workflow

1. **Establish current and target versions** — run
   [version-safety](../../references/version-safety.md)'s detection
   order for the current project-pinned version; take the target
   version from the user's request. If the request doesn't name one
   plainly (e.g. "the latest" without a resolved number), resolve it to
   an exact version via `tuist version` output, Tuist's own release
   channel, or ask — never migrate to an ambiguous target.
2. **Check the delta is forward and non-trivial** — if current equals
   target, report there is nothing to migrate and stop. If the target is
   older than the current pin, refuse: downgrades are out of scope for
   this skill.
3. **Research the actual breaking changes** between current and target
   versions — Tuist's own migration/release notes for every version in
   the range, not just the endpoints; a multi-version jump can carry
   changes from intermediate releases. Never assume a delta from memory
   of "what changed in Tuist N" — verify against the actual release
   notes/changelog for the versions in play.
4. **Inventory affected manifest surface** — scan every `Project.swift`,
   `Tuist.swift`/`Config.swift`, `Workspace.swift`, `Package.swift`
   (Tuist-native), and `ProjectDescriptionHelpers` file in the project
   for syntax the researched breaking changes actually affect. Anything
   not touched by an identified breaking change is left untouched, even
   if it "could look more modern" under the new version.
5. **Propose the migration plan** — present, before editing anything:
   the version-pin sources that will change (e.g. `.mise.toml`,
   `.tool-versions`, CI workflow install steps, any documented version
   reference) and, file by file, exactly which manifest syntax will
   change and why (which breaking change forces it). This is a shared,
   high-blast-radius, hard-to-reverse change — proposal before edit is
   required, not optional, regardless of auto-mode.
6. **Apply approved changes:**
   - Update every version-pin source identified in step 5 to the target
     version.
   - Apply only the manifest syntax changes the target version actually
     requires, file by file.
   - Do not touch unrelated manifest content, formatting, or convention
     choices that remain valid under the target version.
7. **Validate** — `tuist install` (if applicable) and `tuist generate`
   succeed under the new pinned version; the full project builds; the
   full existing test suite runs and passes. A version migration is
   whole-project by nature — validate the whole graph, not just the
   files touched.

## Decision Rules

- Never migrate to a version the user didn't specify or confirm.
- Never bundle a structural/style migration into a version migration —
  if a breaking change *forces* a syntax change, make exactly that
  change; if a style choice merely *becomes possible* under the new
  version, leave it alone and note it as a separate future option in
  Risks/Follow-up rather than applying it.
- Never guess at a version's breaking changes from training-data memory
  of "what Tuist N used to require" — verify against actual release
  notes/changelog content for every version in the migrated range.
- Never leave the project half-migrated on failure — if validation fails
  partway, report exactly what succeeded and what didn't; do not leave
  version-pin sources and manifest syntax in an inconsistent state
  without saying so plainly.
- A refusal (no target version, ambiguous target, downgrade requested,
  nothing to migrate) is a valid, complete outcome of this skill.

## Validation

Required before declaring success: every previously passing validation
still passes after migration — `tuist install` (where applicable) and
`tuist generate` succeed under the target version; the full project
builds; the full existing test suite runs and passes. Compare against a
pre-migration baseline run of the same commands so a regression is
attributable to the migration, not pre-existing project state.

## Failure Handling

Evidence-Driven Debugging, same procedure as the other skills. First
hypothesis to consider here specifically: a breaking change from an
intermediate version in a multi-version jump was missed because only the
endpoint versions' release notes were checked.

## Output Contract

```text
Version Context (before -> after)
Breaking Changes Applied (one per change: source, evidence, files affected)
Version-Pin Sources Updated
Manifest Changes Made (file by file)
Validation Performed (install/generate/build/test, before and after)
Unverified Items
Risks / Follow-up
```

Example:

```text
Version Context: Tuist 3.42.2 (project-pinned, before) -> Tuist 4.206.0 (after)

Breaking Changes Applied:
- Source: Tuist 4.0 migration notes — Config.swift renamed to
  Tuist.swift; the top-level configuration type renamed from `Config` to
  `Tuist`; `ProjectDescription.Target`'s 3.x member-wise initializer was
  removed (4.x's `Target` only exposes `init(from: Decoder)`), so
  Project.swift's target construction moves to the `.target(...)` static
  factory, `platform:` becomes `destinations:`, and singular
  `deploymentTarget:` becomes plural `deploymentTargets:`.
  Evidence: project has Tuist/Config.swift using `Config(...)`, and
  Project.swift uses `Target(name:platform:product:bundleId:
  deploymentTarget:infoPlist:sources:...)`; generating as-is under 4.206.0
  fails with "extra arguments ... in call" at each `Target(` call site.
  Files affected: Tuist/Config.swift -> Tuist/Tuist.swift (renamed, API
  updated), Project.swift (target construction syntax updated)

Version-Pin Sources Updated:
- .mise.toml: tuist 3.42.2 -> 4.206.0
- .github/workflows/ci.yml: mise tool_versions pin updated

Manifest Changes Made:
- Tuist/Config.swift renamed to Tuist/Tuist.swift; `let config =
  Config(...)` replaced with `let tuist = Tuist()`.
- Project.swift: each `Target(name:platform:product:bundleId:
  deploymentTarget:infoPlist:sources:...)` call replaced with
  `.target(name:destinations:product:bundleId:deploymentTargets:
  infoPlist:sources:...)`, `platform: .iOS` replaced with `destinations:
  .iOS`, `deploymentTarget: .iOS(targetVersion: "17.0", devices:
  [.iphone])` replaced with `deploymentTargets: .iOS("17.0")`. No other
  manifest content changed.

Validation:
- Before: tuist generate (3.42.2) succeeded, build succeeded, 1 test passed
- After: tuist generate (4.206.0) succeeded, build succeeded, 1 test passed

Risks / Follow-up:
- Tuist 4.206.0 makes Buildable Folders available for this project; not
  applied here since it's a style choice, not a required change — a
  future ios-tuist-module/manual change could adopt it if desired.
```
```

- [ ] **Step 3: Verify the frontmatter and section structure**

```bash
head -8 skills/ios-tuist-migrate/SKILL.md
grep -c "^## " skills/ios-tuist-migrate/SKILL.md
```

Expected: frontmatter block with `name: ios-tuist-migrate` and a
`description`; 10 `##`-level sections matching the other skills' pattern
(Purpose, Trigger Conditions, Non-Trigger Conditions, Preconditions,
Version Safety, Workflow, Decision Rules, Validation, Failure Handling,
Output Contract).

- [ ] **Step 4: Verify the relative reference link resolves**

```bash
test -f references/version-safety.md && echo "OK: version-safety.md exists"
grep -c "version-safety.md" skills/ios-tuist-migrate/SKILL.md
```

Expected: `OK: version-safety.md exists`, and at least 3 (the link
appears in Purpose, Trigger context, Version Safety, and Workflow step
1).

- [ ] **Step 5: Commit**

```bash
git add skills/ios-tuist-migrate/
git commit -m "docs: add ios-tuist-migrate skill"
```

---

### Task 2: Fixture — `tests/fixtures/migrate-candidate/`

**Files:**
- Create: `tests/fixtures/migrate-candidate/Tuist/Config.swift`
- Create: `tests/fixtures/migrate-candidate/Project.swift`
- Create: `tests/fixtures/migrate-candidate/App/Sources/MigrateCandidateApp.swift`
- Create: `tests/fixtures/migrate-candidate/App/Tests/AppTests.swift`
- Create: `tests/fixtures/migrate-candidate/EXPECTATIONS.md`

**Interfaces:**
- Consumes: nothing from Task 1 structurally (the fixture is plain Tuist
  project content, not skill code).
- Produces: a real Tuist 3.42.2 project that Task 3's CI matrix entry
  validates at its starting version, and that a human (or an agent
  invoking `ios-tuist-migrate`) can migrate to Tuist 4.206.0 as a manual
  exercise of the skill's Workflow.

This fixture is deliberately **minimal** — one app target and one test
target, unlike `architecture-smells`' three-target graph — because the
breaking change under test is manifest-*syntax*-level (Tuist 3.x's
`Config`/`Target(...)`/`platform:`/`deploymentTarget:` vs. Tuist 4.x's
`Tuist`/`.target(...)`/`destinations:`/`deploymentTargets:`), not
graph-level, so two targets (enough to prove a real dependency edge
survives migration) are sufficient. This exact breaking change and both
version numbers were verified live during plan authoring, full
generate/build/test cycle both before and after:

- `mise install tuist@3.42.2` succeeds; `tuist version` reports exactly
  `3.42.2`.
- The 3.x-syntax manifest below (Steps 1–2, with `deploymentTarget:`)
  generates, builds (`xcodebuild build`), and tests (`xcodebuild test`)
  successfully under 3.42.2.
- The identical manifest, unmigrated, fails to compile under 4.206.0.
  The actual first error is `error: extra arguments at positions #1,
  #2, #3, #4, #5, #6, #7 in call` at the `Target(` call site — Tuist
  4.x's `ProjectDescription.Target` struct only exposes
  `init(from: Decoder)` (its 3.x member-wise initializer no longer
  exists), so the call doesn't match any initializer at all. A cascade
  of `cannot infer contextual base` errors follows on every `.iOS`/
  `.app`/`.default`/`.unitTests`/`.iphone` member reference in the same
  call, and a final `type 'Any' has no member 'target'` on the
  `dependencies:` array, because the whole expression fails to
  type-check as a `Target` call. All of this is one real, connected
  failure, not several unrelated ones — reported here as the specific
  evidence a migration diagnosis would actually see.
- The migrated syntax (also shown below, for reference — not created by
  this task) generates, builds, and tests successfully under 4.206.0.

- [ ] **Step 1: Create `Tuist/Config.swift`** (3.x manifest, NOT
  `Tuist.swift` — this is deliberate, it's the fixture's condition)

```swift
import ProjectDescription

let config = Config(
    generationOptions: .options()
)
```

- [ ] **Step 2: Create `Project.swift`** (3.x `Target(...)` initializer
  with `platform:`, NOT the 4.x `.target(...)` factory with
  `destinations:` — deliberate)

```swift
import ProjectDescription

let project = Project(
    name: "MigrateCandidate",
    targets: [
        Target(
            name: "App",
            platform: .iOS,
            product: .app,
            bundleId: "dev.ios-tuist-skills.migrate-candidate",
            deploymentTarget: .iOS(targetVersion: "17.0", devices: [.iphone]),
            infoPlist: .default,
            sources: ["App/Sources/**"]
        ),
        Target(
            name: "AppTests",
            platform: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.migrate-candidate-tests",
            deploymentTarget: .iOS(targetVersion: "17.0", devices: [.iphone]),
            infoPlist: .default,
            sources: ["App/Tests/**"],
            dependencies: [
                .target(name: "App")
            ]
        )
    ]
)
```

`deploymentTarget:` is required here, not optional style — verified live
during plan authoring that omitting it makes Tuist 3.42.2 default the
built app to the host machine's installed Xcode SDK version (27.0 at
authoring time), which no locally available iOS Simulator runtime
matches, breaking `xcodebuild test` even though `generate` and `build`
both succeed. Note the 3.x API shape: a singular `deploymentTarget:`
parameter taking `.iOS(targetVersion:devices:)` — this itself is part of
what changes in Step 2 of the migration (4.x uses the plural
`deploymentTargets:` parameter with the simpler `.iOS("17.0")` form, as
this repository's other fixtures already show, e.g.
`tests/fixtures/legacy-tuist/Project.swift`).

- [ ] **Step 3: Create the app source**

```bash
mkdir -p tests/fixtures/migrate-candidate/App/Sources
mkdir -p tests/fixtures/migrate-candidate/App/Tests
```

`tests/fixtures/migrate-candidate/App/Sources/MigrateCandidateApp.swift`:

```swift
import SwiftUI

@main
struct MigrateCandidateApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Migrate Candidate")
        }
    }
}
```

- [ ] **Step 4: Create the test**

`tests/fixtures/migrate-candidate/App/Tests/AppTests.swift`:

```swift
import XCTest

final class AppTests: XCTestCase {
    func testPlaceholderPasses() {
        XCTAssertTrue(true)
    }
}
```

Use XCTest here, not Swift Testing — Tuist 3.42.2's toolchain era predates
this repository's "Swift Testing for new tests" default, and the fixture
must reflect what a real project pinned at Tuist 3.x actually looked
like at the time, not a retrofitted modern convention.

- [ ] **Step 5: Write `EXPECTATIONS.md`**

```markdown
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
```

- [ ] **Step 6: Validate the fixture generates and builds at its pinned
  version (local — GitHub Actions credit is exhausted, see Global
  Constraints)**

```bash
cd tests/fixtures/migrate-candidate
mise install tuist@3.42.2
test "$(mise exec tuist@3.42.2 -- tuist version)" = "3.42.2"
mise exec tuist@3.42.2 -- tuist generate --no-open
xcodebuild -workspace MigrateCandidate.xcworkspace -scheme App \
  -destination 'generic/platform=iOS Simulator' build
```

Expected: version check passes; `tuist generate` succeeds; `** BUILD
SUCCEEDED **`.

- [ ] **Step 7: Confirm the unmigrated manifests actually fail under
  4.206.0** (proves the fixture's condition is real, not assumed)

```bash
rm -rf MigrateCandidate.xcworkspace MigrateCandidate.xcodeproj Derived
mise exec tuist@4.206.0 -- tuist generate --no-open
```

Expected: fails with a Swift compilation error referencing `platform` or
`.iOS`/`.app`/`.default` context inference (the `Target(...)`/`platform:`
vs `.target(...)`/`destinations:` mismatch). Do not proceed to Step 8
until this failure is confirmed — an accidental success here means the
fixture doesn't actually exercise the intended breaking change.

- [ ] **Step 8: Regenerate the committed pre-migration state**

```bash
rm -rf MigrateCandidate.xcworkspace MigrateCandidate.xcodeproj Derived
mise exec tuist@3.42.2 -- tuist generate --no-open
```

(Confirms the working tree is back to the real, committable 3.42.2-valid
state after Step 7's deliberate-failure probe. `Derived`,
`*.xcworkspace`, `*.xcodeproj` are already gitignored per this
repository's `.gitignore` — nothing generated here gets committed.)

- [ ] **Step 9: Clean generated artifacts before committing**

```bash
cd /Users/dave/Documents/GitHub/ios-tuist-skills
rm -rf tests/fixtures/migrate-candidate/Derived
rm -rf tests/fixtures/migrate-candidate/MigrateCandidate.xcworkspace
rm -rf tests/fixtures/migrate-candidate/MigrateCandidate.xcodeproj
git status --short tests/fixtures/migrate-candidate/
```

Expected: only the 5 authored files from Steps 1, 2, 3, 4, 5 show as
untracked — no generated project/workspace/Derived content.

- [ ] **Step 10: Commit**

```bash
git add tests/fixtures/migrate-candidate/
git commit -m "test: add migrate-candidate fixture (Tuist 3.42.2 -> 4.206.0 breaking change)"
```

---

### Task 3: Extend `.github/workflows/validate-fixtures.yml` with the new fixture

**Files:**
- Modify: `.github/workflows/validate-fixtures.yml`

**Interfaces:**
- Consumes: `tests/fixtures/migrate-candidate/` (must already exist and
  build at 3.42.2, from Task 2).
- Produces: the extended regression gate described in spec §4.2.

- [ ] **Step 1: Read the current workflow file**

```bash
cat .github/workflows/validate-fixtures.yml
```

Confirm the existing `matrix.include` list and per-fixture `test_schemes`
shape before editing — this plan was written against the version quoted
in this task's design context; verify it still matches before assuming
line numbers.

- [ ] **Step 2: Add one entry to the matrix**

Add this entry to the `matrix.include` list, alongside the six existing
entries (`legacy-tuist`, `modular`, `version-mismatch`, `extract-candidate`,
`architecture-smells`, `ci-gaps`):

```yaml
          - fixture: migrate-candidate
            tuist: 3.42.2
            test_schemes: App
```

This entry pins `migrate-candidate` at its **starting** version
(3.42.2), matching spec §4.2 — CI validates the fixture's real
pre-migration state, not the migration itself. The workflow's existing
steps (install pinned Tuist, verify pin, `tuist install`, `tuist
generate`, build, test) apply unchanged; no new step type is needed.

- [ ] **Step 3: Verify the workflow YAML is still syntactically valid**

```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/validate-fixtures.yml'))"
```

Expected: no error.

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/validate-fixtures.yml
git commit -m "ci: validate migrate-candidate fixture at its starting version"
```

- [ ] **Step 5: Validate locally (GitHub Actions credit is exhausted —
  see Global Constraints; do not push yet)**

Run the exact sequence the new matrix entry specifies, by hand, from the
fixture directory:

```bash
cd tests/fixtures/migrate-candidate
export XDG_CACHE_HOME=/tmp/tuist-local-validate/cache
export XDG_STATE_HOME=/tmp/tuist-local-validate/state
export XDG_DATA_HOME=/tmp/tuist-local-validate/data
mise exec tuist@3.42.2 -- tuist install
mise exec tuist@3.42.2 -- tuist generate --no-open
xcodebuild -workspace MigrateCandidate.xcworkspace -scheme App \
  -destination 'generic/platform=iOS Simulator' build
SIMULATOR_ID="$(xcrun simctl list devices available --json | ruby -rjson -e '
  devices = JSON.parse(STDIN.read).fetch("devices").values.flatten
  iphone = devices.find { |device| device["isAvailable"] && device["name"].start_with?("iPhone") }
  abort "No available iPhone simulator found" unless iphone
  print iphone.fetch("udid")
')"
xcodebuild test -workspace MigrateCandidate.xcworkspace -scheme App -destination "id=$SIMULATOR_ID"
```

Expected: `tuist install` succeeds (no dependencies to resolve, but the
command must not error), `tuist generate` succeeds, `** BUILD SUCCEEDED
**`, `** TEST SUCCEEDED **`. Clean up generated artifacts afterward
(`rm -rf MigrateCandidate.xcworkspace MigrateCandidate.xcodeproj Derived`
from the fixture directory) and confirm `git status --short` is clean
before proceeding — do not commit generated project files.

Do not run `git push` or check GitHub Actions run status as this
workflow's own Task 8/Step-5-equivalent — GitHub Actions credit is
exhausted for this repository's account as of 2026-09-18 (Global
Constraints). Local validation above is the substitute evidence.
Push is a separate decision made with the user after the whole plan is
done, consistent with this repository's established practice.

---

### Task 4: README.md, CHANGELOG.md, and plugin version updates

**Files:**
- Modify: `README.md`
- Modify: `CHANGELOG.md`
- Modify: `.claude-plugin/plugin.json`

**Interfaces:**
- Consumes: everything built in Tasks 1–3 (this task documents the
  finished v0.3 state).
- Produces: the installation/usage doc and version marker a human reads
  first.

- [ ] **Step 1: Read the current README.md, CHANGELOG.md, and plugin.json**

```bash
cat README.md
cat CHANGELOG.md
cat .claude-plugin/plugin.json
```

(Confirm current content before editing so nothing existing is silently
dropped.)

- [ ] **Step 2: Update `README.md`'s Skills section**

Add one new subsection after the existing `ios-tuist-ci` entry, matching
the existing style exactly (heading, one paragraph, one example prompt):

```markdown
### `ios-tuist-migrate`

Moves a project's pinned Tuist version forward to a user-specified
target version, updating version-pin sources and the minimum manifest
syntax the target version actually requires — the only skill in this
repository permitted to change a project's Tuist version pin, and only
on explicit request. Example: "Migrate this project from Tuist 3 to
Tuist 4."
```

- [ ] **Step 3: Update `README.md`'s Repository layout section**

Change:
```
skills/               Bootstrap, feature, dependency, module,
                      architecture-review, and CI skills
```
to:
```
skills/               Bootstrap, feature, dependency, module,
                      architecture-review, CI, and migration skills
```

- [ ] **Step 4: Update `README.md`'s Fixtures and CI section**

Add one bullet after the existing seven, matching the existing style:

```markdown
- [migrate candidate](tests/fixtures/migrate-candidate/EXPECTATIONS.md):
  a real Tuist 3.42.2 project with a genuine breaking-change surface
  `ios-tuist-migrate` must detect and fix moving to Tuist 4.206.0
```

- [ ] **Step 5: Update `README.md`'s spec link**

Add a line after the existing v0.2 spec link:

```markdown
The v0.3 milestone (Tuist version migration) is specified in the
[v0.3 design specification](docs/superpowers/specs/2026-09-18-ios-tuist-skills-v0.3-design.md).
```

- [ ] **Step 6: Add the `[0.3.0]` entry to `CHANGELOG.md`**

Replace the `## [Unreleased]` line's empty body with:

```markdown
## [Unreleased]

## [0.3.0] - 2026-09-18

### Added

- `ios-tuist-migrate`: moves a project's pinned Tuist version forward to
  a user-specified target version, updating version-pin sources and the
  minimum manifest syntax the target version actually requires. The only
  skill in this repository permitted to change a project's Tuist version
  pin, and only on explicit request — never bundles a structural/style
  migration into a version bump.
- `migrate-candidate` fixture: a real Tuist 3.42.2 project with a
  verified breaking-change surface (the Tuist 4.0 `Config.swift` ->
  `Tuist.swift` rename and `Target(...)`/`platform:` ->
  `.target(...)`/`destinations:` manifest API change), wired into the
  existing fixture-validation CI matrix at its starting version.
```

- [ ] **Step 7: Bump the plugin version and description**

In `.claude-plugin/plugin.json`, change:
```json
  "description": "Version-aware iOS engineering skills for Tuist-based projects: safe bootstrap, feature addition, dependency management, module extraction, architecture review, and CI auditing that detect the project's real Tuist/Xcode/Swift versions and preserve existing conventions.",
  "version": "0.2.0",
```
to:
```json
  "description": "Version-aware iOS engineering skills for Tuist-based projects: safe bootstrap, feature addition, dependency management, module extraction, architecture review, CI auditing, and explicit version migration that detect the project's real Tuist/Xcode/Swift versions and preserve existing conventions.",
  "version": "0.3.0",
```

- [ ] **Step 8: Verify plugin.json is still valid JSON**

```bash
python3 -m json.tool .claude-plugin/plugin.json
```

Expected: pretty-printed JSON output, no error.

- [ ] **Step 9: Commit**

```bash
git add README.md CHANGELOG.md .claude-plugin/plugin.json
git commit -m "docs: document v0.3 migrate skill and bump plugin version"
```

---

### Task 5: Final spec-compliance sweep

**Files:**
- No new files — this task audits the whole repo against spec §7's
  acceptance criteria and fixes any gaps found.

**Interfaces:**
- Consumes: the entire repository state after Tasks 1–4.
- Produces: nothing new by default; only produces fixes if gaps are
  found.

- [ ] **Step 1: Run the acceptance checklist from spec §7**

```bash
# ios-tuist-migrate SKILL.md exists and starts with valid frontmatter
head -1 skills/ios-tuist-migrate/SKILL.md | grep -q '^---$' && echo "OK: SKILL.md frontmatter" || echo "MISSING/BROKEN: SKILL.md"

# migrate-candidate fixture has EXPECTATIONS.md naming the breaking change
test -f tests/fixtures/migrate-candidate/EXPECTATIONS.md && echo "OK: EXPECTATIONS.md exists" || echo "MISSING: EXPECTATIONS.md"
grep -q "Config" tests/fixtures/migrate-candidate/EXPECTATIONS.md && echo "OK: names the breaking change" || echo "MISSING: breaking-change detail"

# No new shared reference file was added
test $(ls references | wc -l) -eq 5 && echo "OK: still 5 shared reference files" || echo "UNEXPECTED: reference file count changed"

# CI matrix includes migrate-candidate
grep -q "fixture: migrate-candidate" .github/workflows/validate-fixtures.yml && echo "OK: CI matrix entry" || echo "MISSING: CI matrix entry"

# Plugin version bumped
grep -q '"version": "0.3.0"' .claude-plugin/plugin.json && echo "OK: plugin.json version" || echo "MISSING: plugin.json version bump"

# CHANGELOG has the 0.3.0 entry
grep -q '## \[0.3.0\]' CHANGELOG.md && echo "OK: CHANGELOG 0.3.0 entry" || echo "MISSING: CHANGELOG 0.3.0 entry"

# No hard-coded Tuist version inside skills/ content (version literals belong only in fixtures/CI)
grep -rnE 'Tuist [0-9]+\.[0-9]+|[0-9]+\.[0-9]+\.[0-9]+' skills/ios-tuist-migrate/SKILL.md | grep -v '3.42.2\|4.206.0' || echo "OK: no stray version literals beyond the documented example"
```

Expected: every check prints `OK:` — fix any gap found before
proceeding. The last command is expected to print nothing beyond its own
`OK:` fallback, since the Output Contract example in SKILL.md
legitimately names `3.42.2`/`4.206.0` as illustrative values, not a
hard-coded compatibility claim.

- [ ] **Step 2: Confirm local validation evidence stands in for CI**
  (GitHub Actions credit exhausted — see Global Constraints)

```bash
git status --short
```

Expected: clean working tree (everything from Tasks 1–4 already
committed). Since CI cannot run, do not attempt `gh run list` as
completion evidence for this plan — Task 2 Step 6-7 and Task 3 Step 5's
local command output are this plan's validation evidence instead.

- [ ] **Step 3: Confirm no leftover `.gitkeep` made obsolete**

`skills/ios-tuist-migrate/references/` stays genuinely empty in v0.3 (no
skill-specific reference content beyond root `references/` was needed) —
its `.gitkeep` remains; do not remove it.

- [ ] **Step 4: Final commit (only if Step 1 found and fixed a gap)**

```bash
git add -A
git commit -m "chore: v0.3 spec-compliance sweep"
```

If Step 1 found no gaps, skip this commit — an empty sweep commit is not
required (same precedent as v0.2 Task 10, where no gaps meant no
sweep commit was made).

---

## Post-plan note

This plan covers exactly the v0.3 milestone (spec §1, §7):
`ios-tuist-migrate` scoped to Tuist version upgrades only. Do not push to
`origin` as part of executing this plan — GitHub Actions credit is
exhausted (Global Constraints), and publishing is a decision made with
the user once the whole plan is done and locally validated, consistent
with how v0.2 was finished.
