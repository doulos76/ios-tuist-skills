# ios-tuist-skills v0.5 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Implementation owner: Codex.** The Claude session in this repository
> produces spec + plan only (brainstorming through writing-plans) and
> must not execute this plan — not even if later asked to "proceed" or
> "실행해주세요." Stop after this plan is saved and committed; hand off
> to Codex for execution.

**Goal:** Ship the v0.5 milestone of `ios-tuist-skills`: one new skill,
`ios-tuist-test-target`, that creates a new unit/integration/UI test
target for a user-named existing target and enrolls it in the relevant
scheme's test action — as a skeleton only (one labeled placeholder test,
no real coverage). Includes one new real, buildable fixture proving both
the "create it" and "already exists, refuse" paths, validated by CI.

**Architecture:** Same flat plugin repo shape as prior milestones — no
new top-level directories. One self-contained `SKILL.md` lands in
`skills/ios-tuist-test-target/`. No shared reference file changes — this
skill reads `references/testing.md` (framework choice, the
labeled-smoke-test exception extended to a freshly created target),
`references/source-of-truth.md` (existing conventions win; the
`Workspace.swift` decision rule governing when a custom `Scheme`
exists), and `references/version-safety.md`. One new fixture extends the
existing `.github/workflows/validate-fixtures.yml` matrix job — no new
workflow file, and no change needed to
`scripts/validate-fixtures-locally.sh` (it reads the matrix directly, so
a new entry is picked up automatically).

**Tech Stack:** Tuist 4.206.0 (matches this repo's other fixtures),
Xcode 27 / Swift 6.4, GitHub Actions (currently routed to a self-hosted
macOS runner per the temporary CI-credit measure — see
`.github/workflows/validate-fixtures.yml`'s `runs-on:` comment).

**Spec:** `docs/superpowers/specs/2026-09-20-ios-tuist-skills-v0.5-design.md`

## Global Constraints

- `SKILL.md` follows the same section structure as the other eight
  skills: Purpose, Trigger Conditions, Non-Trigger Conditions,
  Preconditions, Version Safety, Workflow, Decision Rules, Validation,
  Failure Handling, Output Contract (spec §3).
- Never create a test target for a target the user didn't name; never
  sweep "the whole project" or "every target" in one run (spec §3
  Non-Trigger Conditions, Decision Rules).
- Never create a second test target of the same kind for a target that
  already has one — report the existing target's name and stop (spec
  §3 Non-Trigger Conditions, Decision Rules).
- Never write real test assertions or business-logic coverage — exactly
  one labeled placeholder test file per created target (spec §3.3,
  Decision Rules).
- Tuist's `ProjectDescription` has exactly two test product cases,
  `.unitTests` and `.uiTests` — there is no `.integrationTests` case
  (verified live during plan authoring via Context7 Tuist docs).
  "Integration test target" is represented as a second `.unitTests`
  target distinguished by name only (e.g. `FeatureAIntegrationTests`) —
  never invent an unsupported product type, and always state this fact
  explicitly in the skill's own output when the request is for an
  integration-test kind (spec §3.1).
- Never create a brand-new custom `Scheme` where none existed — only
  enroll into a custom scheme that already exists and already tests the
  named target; if no custom scheme covers it, rely on Tuist's default
  generated scheme and say so (spec §3.2, Decision Rules).
- Fixtures under `tests/fixtures/` must be real, independently buildable
  Tuist projects — not structure-only stand-ins (spec §4.1).
- The new fixture joins the existing `validate-fixtures.yml` matrix (one
  job, extended) — do not create a second CI workflow file (spec §4.2).
- The verified, real Tuist API shapes used throughout this plan
  (confirmed live via Context7 `/tuist/tuist` docs during plan
  authoring):
  - `.target(name:destinations:product:bundleId:deploymentTargets:infoPlist:sources:resources:dependencies:)`
    for targets; `product: .unitTests` / `.uiTests` for test targets;
    `.target(name: "<hostTarget>")` as a test target's dependency
    auto-configures the test host.
  - `.scheme(name:shared:buildAction:testAction:runAction:)` for a
    custom scheme; `.testAction(targets: ["Target1", "Target2"])` takes
    a plain array of target-name strings (string-literal
    `TestableTarget` values) — appending a new test target means adding
    one more string to that array, not a separate API.
  - Do not substitute any other shape (e.g. a `TestableTarget(...)`
    struct literal, or a `Scheme(...)`/`TestAction.targets(...)`
    top-level free-function form) if improvising beyond what's written
    in this plan — both the capitalized-initializer form
    (`Scheme(...)`, `TestAction.targets(...)`) and the lowercase
    static-factory form (`.scheme(...)`, `.testAction(...)`) are valid
    current Tuist API; this plan uses the lowercase static-factory form
    throughout for consistency with the fixture's `Project.swift`.
- MIT license header style is not required per-file; `LICENSE` at repo
  root already covers the whole repo.

---

### Task 1: `ios-tuist-test-target` skill

**Files:**
- Create: `skills/ios-tuist-test-target/SKILL.md`
- Create: `skills/ios-tuist-test-target/references/.gitkeep`

**Interfaces:**
- Consumes: `references/testing.md` (framework choice, smoke-test
  exception), `references/source-of-truth.md` (existing conventions win,
  `Workspace.swift` decision rule), `references/version-safety.md`
  (detection order).
- Produces: nothing later tasks import structurally — Task 2's fixture
  is validated independently against this skill's Output Contract
  shape, not linked to it in code.

- [ ] **Step 1: Create the skill directory and empty references folder**

```bash
mkdir -p skills/ios-tuist-test-target/references
touch skills/ios-tuist-test-target/references/.gitkeep
```

- [ ] **Step 2: Write `skills/ios-tuist-test-target/SKILL.md`**

Create with this exact content:

```markdown
---
name: ios-tuist-test-target
description: >
  Creates a new unit, integration, or UI test target for one explicitly
  user-named existing target and enrolls it in the relevant scheme's
  test action, following the project's own testing and naming
  conventions. Never writes real test logic beyond a single labeled
  placeholder, never sweeps multiple targets, never creates a duplicate
  test target for a target that already has one of the requested kind.
---

# Core Rule

Create a test target only for the target the user explicitly names, and
only the specific kind (unit / integration / UI) they ask for. A test
target of that kind already existing for the named target is a refusal,
not something to overwrite or duplicate. This skill's only generated
code is a single labeled structural placeholder — never real test
assertions or coverage.

## Purpose

Create a new unit, integration, or UI test target for one explicitly
user-named existing target, following the project's own testing and
naming conventions, and enroll the new target in the relevant scheme's
test action — refusing when a test target of the requested kind already
exists for that target, or reporting explicitly when no custom scheme
exists to enroll into (Tuist's default generated scheme already covers
it).

## Trigger Conditions

- "Add a unit test target for FeatureA"
- "Create an integration test target for NetworkingKit"
- "Set up UI tests for the App target"

The request must name one specific existing target and, explicitly or
by clear implication, one test kind (unit / integration / UI).

## Non-Trigger Conditions

- The request names no existing target, or asks to add test targets
  "everywhere" / "for the whole project" — out of scope for this pass;
  ask which target to scope to rather than sweeping every target in one
  run.
- The named target already has a test target of the requested kind —
  report the existing target's name and stop; do not create a second
  one.
- The request is to add actual test *cases* / assertions to a test
  target that already exists — that's
  [`ios-tuist-feature`](../ios-tuist-feature/SKILL.md); state this
  explicitly rather than silently writing test logic here.
- The request is to extract existing code (and its tests) into a new
  non-test module — that's
  [`ios-tuist-module`](../ios-tuist-module/SKILL.md).
- The request is a general audit of whether existing schemes have gaps,
  with no specific new target wanted — out of scope for this pass;
  state this rather than guessing at a broad audit.
- No existing Tuist project, or the named target doesn't exist in the
  project's manifests.

## Preconditions

An existing Tuist project is present and readable; one specific existing
non-test target is named; the requested test kind (unit / integration /
UI) is stated or unambiguous from context.

## Version Safety

Full [version-safety](../../references/version-safety.md) procedure,
Existing Project Mode. No version floor is introduced by this skill
itself (test targets and `Scheme`/`TestAction` are long-stable
`ProjectDescription` API); still confirm the pinned version to generate
syntax the pinned version actually accepts, per the repo-wide rule.

## Workflow

1. **Resolve the named target** — confirm it exists in the project's
   manifests and is not itself a test product.
2. **Resolve the test kind and target name.** Inspect the project's
   existing test-target naming convention (e.g. `{Target}Tests`,
   `{Target}UITests`) from neighboring targets; if none exists yet,
   default to `{Target}Tests` (unit), `{Target}IntegrationTests`
   (integration), or `{Target}UITests` (UI) — see below for how unit vs.
   integration is distinguished, since Tuist has no separate `product`
   case for "integration test."
3. **Check for an existing test target of the requested kind** for the
   named target. If found: report its name, make no changes, stop.
4. **Resolve the test framework** per
   [testing.md](../../references/testing.md): inspect the project's
   existing test targets first (Existing Project Mode — an established
   XCTest-only project keeps XCTest); if none exist yet and the detected
   Swift/Xcode version supports it, prefer Swift Testing for
   unit/integration; UI tests always use XCTest/XCUIAutomation
   regardless of the unit-test framework choice.
5. **Create the new target** in `Project.swift`:
   - `product: .unitTests` for both unit and integration kinds (Tuist
     has no distinct "integration test" product — see below); `product:
     .uiTests` for UI.
   - `dependencies: [.target(name: "<namedTarget>")]` so Tuist
     auto-configures the host/target-under-test relationship.
   - One labeled placeholder test file only — no real test logic.
6. **Resolve scheme enrollment:**
   - If a custom `Scheme` already exists that builds/tests the named
     target, add the new test target's name to that scheme's
     `testAction` target list.
   - If no custom scheme exists (the project relies on Tuist's default
     generated per-target schemes), state this explicitly in the Output
     Contract — Tuist generates a default scheme for the new test target
     automatically; no manifest scheme change is needed or made.
7. **Validate** — `tuist generate` succeeds; the new test target builds;
   the placeholder test runs and passes (a trivial, always-true
   assertion is the *point* here — it exists only to prove the target is
   wired correctly, per the labeled-smoke-test exception in
   [testing.md](../../references/testing.md)); no other target's
   manifest or generated output changes.

### Unit vs. integration: naming, not a distinct product

Tuist's `ProjectDescription` has exactly two test product cases,
`.unitTests` and `.uiTests` — there is no `.integrationTests` case. This
skill represents "integration test target" as a second `.unitTests`
target distinguished by name and folder only (e.g. `FeatureATests` for
unit, `FeatureAIntegrationTests` for integration) — never by inventing
an unsupported product type. State this fact plainly in the Output
Contract when the request is for an integration-test kind, so the user
understands why the generated target's `product:` reads `.unitTests`.

### Scheme enrollment

Most projects have no custom `Scheme` at all — Tuist generates one
default scheme per target automatically, and that default scheme
already includes the new test target's own default scheme the moment
`tuist generate` runs; nothing needs to be written for this case.
Enrollment work is only needed, and only performed, when the project
already defines a **custom** `Scheme` (in `Project.swift`'s `schemes:`
argument or a `Workspace.swift`) whose `testAction` bundles multiple
test targets together. In that case:

- Locate the specific custom `Scheme` value(s) that test the named
  target.
- Add the new test target's name to that `Scheme`'s `testAction` target
  list — appending to the existing array of target-name strings, never
  replacing the list.
- Never create a brand-new custom `Scheme` where none existed — that is
  a larger structural decision, out of scope for this skill; if no
  custom scheme covers the named target, rely on Tuist's default
  generated scheme and say so.

### Placeholder file (skeleton, not coverage)

Exactly one file, containing exactly one empty test case, clearly
labeled as a structural placeholder:

```swift
// Structural placeholder proving FeatureATests is wired correctly.
// Replace with real coverage — not a substitute for actual tests.
import Testing
@testable import FeatureA

@Suite struct FeatureATestsPlaceholder {
    @Test func targetIsWiredCorrectly() {
        #expect(Bool(true))
    }
}
```

(XCTest equivalent when the project's existing convention is XCTest —
same one-case, same label, `XCTAssertTrue(true)`.)

## Decision Rules

- Never create a test target for a target the user didn't name.
- Never create a second test target of the same kind for a target that
  already has one — report the existing target's name instead.
- Never write real test assertions or business-logic coverage — this
  skill's only generated code is the single labeled placeholder above;
  real coverage is `ios-tuist-feature`'s job, on request.
- Never invent an `.integrationTests` product case — represent
  integration tests as a named `.unitTests` target, and say so.
- Never create a new custom `Scheme` where none existed; only enroll
  into a custom scheme that already exists and already tests the named
  target.
- Never change an existing test target's contents, dependencies, or
  scheme membership as a side effect of adding a different, new one.
- A refusal (test target of the requested kind already exists, no
  target named, named target doesn't exist) is a valid, complete
  outcome.

## Validation

Required before declaring success: `tuist generate` succeeds; the new
test target builds; the placeholder test runs and passes; the named
target and any custom scheme touched still build/test as before
(spot-check: their generated output is otherwise unchanged).

## Failure Handling

Evidence-Driven Debugging, same procedure as the other skills. First
hypothesis to consider here specifically: the new test target fails to
resolve its host/target-under-test automatically because the named
target's `product:` isn't one Tuist auto-hosts tests for (e.g. a
`.staticLibrary` with no app/framework host) — verify the named target's
actual product type before assuming the dependency declaration alone is
sufficient.

## Output Contract

```text
Version Context
Target Requested
Test Kind Requested
Existing Test Target Check (found existing / none found)
Test Target Created (name, product, dependencies)
Framework Chosen (and why — existing convention vs. testing.md default)
Scheme Enrollment (custom scheme updated, or "no custom scheme — default
generated scheme covers this target")
Validation Performed
Unverified Items
Risks / Follow-up
```

Example (target created, custom scheme enrolled):

```text
Version Context: Tuist 4.206.0 (project-pinned, matches active)

Target Requested: FeatureA
Test Kind Requested: integration

Existing Test Target Check: no FeatureAIntegrationTests target found.

Test Target Created:
- FeatureAIntegrationTests (product: .unitTests — Tuist has no distinct
  integration-test product; named to distinguish it from the existing
  FeatureATests unit-test target)
- dependencies: [.target(name: "FeatureA")]
- one labeled placeholder test (Swift Testing, matching the project's
  existing convention)

Framework Chosen: Swift Testing — matches FeatureATests' existing
convention in this project.

Scheme Enrollment: added FeatureAIntegrationTests to the custom "App"
scheme's testAction, alongside the existing FeatureATests entry.

Validation:
- tuist generate: success
- FeatureAIntegrationTests build: success
- Placeholder test: passed
- FeatureA and FeatureATests: unchanged, still build/pass

Risks / Follow-up:
- Placeholder test proves wiring only — no real integration coverage
  exists yet.
```

Example (refused — already exists):

```text
Version Context: Tuist 4.206.0 (project-pinned, matches active)

Target Requested: FeatureA
Test Kind Requested: unit

Existing Test Target Check: FeatureATests already exists and is a unit
test target for FeatureA.

Test Target Created: none — refused, already exists.

Risks / Follow-up:
- If you want additional unit coverage, that's ios-tuist-feature adding
  test cases to the existing FeatureATests target, not a new target.
```
```

- [ ] **Step 3: Verify the frontmatter and section structure**

```bash
head -9 skills/ios-tuist-test-target/SKILL.md
grep -c "^## " skills/ios-tuist-test-target/SKILL.md
```

Expected: frontmatter block with `name: ios-tuist-test-target` and a
`description`; 10 `##`-level sections matching the other skills' pattern
(Purpose, Trigger Conditions, Non-Trigger Conditions, Preconditions,
Version Safety, Workflow, Decision Rules, Validation, Failure Handling,
Output Contract).

- [ ] **Step 4: Verify the relative reference links resolve**

```bash
test -f references/testing.md && echo "OK: testing.md exists"
test -f references/source-of-truth.md && echo "OK: source-of-truth.md exists"
test -f references/version-safety.md && echo "OK: version-safety.md exists"
test -f skills/ios-tuist-feature/SKILL.md && echo "OK: ios-tuist-feature SKILL.md exists"
test -f skills/ios-tuist-module/SKILL.md && echo "OK: ios-tuist-module SKILL.md exists"
grep -c "testing.md" skills/ios-tuist-test-target/SKILL.md
```

Expected: all five `OK:` lines print, plus at least 1 occurrence of
`testing.md`.

- [ ] **Step 5: Verify no `.integrationTests` product is ever referenced
  as real Tuist API**

```bash
grep -n "\.integrationTests" skills/ios-tuist-test-target/SKILL.md || echo "OK: no invented .integrationTests product"
```

Expected: `OK: no invented .integrationTests product` (the skill only
ever *talks about* the absence of this case, never writes it as a value).

- [ ] **Step 6: Commit**

```bash
git add skills/ios-tuist-test-target/
git commit -m "docs: add ios-tuist-test-target skill"
```

---

### Task 2: Fixture — `tests/fixtures/test-target-candidate/`

**Files:**
- Create: `tests/fixtures/test-target-candidate/Tuist.swift`
- Create: `tests/fixtures/test-target-candidate/Project.swift`
- Create: `tests/fixtures/test-target-candidate/App/Sources/TestTargetCandidateApp.swift`
- Create: `tests/fixtures/test-target-candidate/App/Tests/AppTests.swift`
- Create: `tests/fixtures/test-target-candidate/FeatureA/Sources/FeatureA.swift`
- Create: `tests/fixtures/test-target-candidate/FeatureA/Tests/FeatureATests.swift`
- Create: `tests/fixtures/test-target-candidate/FeatureB/Sources/FeatureB.swift`
- Create: `tests/fixtures/test-target-candidate/EXPECTATIONS.md`

**Interfaces:**
- Consumes: nothing from Task 1 structurally (the fixture is plain Tuist
  project content, not skill code).
- Produces: a real Tuist 4.206.0 project that Task 3's CI matrix entry
  validates as-committed (both `FeatureA` and its existing test target
  buildable, `FeatureB` buildable with no test target yet, custom scheme
  bundling `FeatureATests`), and that a human (or an agent invoking
  `ios-tuist-test-target`) can exercise the "refuse — FeatureA already
  has FeatureATests" / "create FeatureBTests and enroll it in the
  existing custom scheme" dual path as a manual exercise of the skill's
  Workflow.

This fixture is deliberately a 5-target project (`App`, `AppTests`,
`FeatureA`, `FeatureATests`, `FeatureB`) plus one custom `Scheme` named
`App` that bundles `AppTests` and `FeatureATests` in its `testAction` —
`FeatureB` has no test target yet and is not in the custom scheme, so
creating `FeatureBTests` and adding it to the custom `App` scheme's
`testAction` is the fixture's "create it" path.

- [ ] **Step 1: Create `Tuist.swift`**

```swift
import ProjectDescription

let tuist = Tuist()
```

- [ ] **Step 2: Create `Project.swift`**

```swift
import ProjectDescription

let project = Project(
    name: "TestTargetCandidate",
    targets: [
        .target(
            name: "App",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.ios-tuist-skills.test-target-candidate",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["App/Sources/**"],
            dependencies: [
                .target(name: "FeatureA"),
                .target(name: "FeatureB")
            ]
        ),
        .target(
            name: "AppTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.test-target-candidate-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["App/Tests/**"],
            dependencies: [.target(name: "App")]
        ),
        .target(
            name: "FeatureA",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.test-target-candidate-featurea",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["FeatureA/Sources/**"]
        ),
        .target(
            name: "FeatureATests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.test-target-candidate-featurea-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["FeatureA/Tests/**"],
            dependencies: [.target(name: "FeatureA")]
        ),
        .target(
            name: "FeatureB",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.test-target-candidate-featureb",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["FeatureB/Sources/**"]
        )
    ],
    schemes: [
        .scheme(
            name: "App",
            shared: true,
            buildAction: .buildAction(targets: ["App", "FeatureA", "FeatureB"]),
            testAction: .testAction(targets: ["AppTests", "FeatureATests"]),
            runAction: .runAction(configuration: "Debug")
        )
    ]
)
```

`FeatureA`/`FeatureATests` is the "already has a unit test target"
candidate (proves the refuse path for a second unit-test-target
request). `FeatureB` has no test target and is deliberately left out of
the custom `App` scheme's `testAction` — proves both the "create it" and
"enroll it in the existing custom scheme" paths together.

- [ ] **Step 3: Create the app source and test**

```bash
mkdir -p tests/fixtures/test-target-candidate/App/Sources
mkdir -p tests/fixtures/test-target-candidate/App/Tests
```

`tests/fixtures/test-target-candidate/App/Sources/TestTargetCandidateApp.swift`:

```swift
import SwiftUI
import FeatureA
import FeatureB

@main
struct TestTargetCandidateApp: App {
    var body: some Scene {
        WindowGroup {
            Text(FeatureALabel.text + FeatureBLabel.text)
        }
    }
}
```

`tests/fixtures/test-target-candidate/App/Tests/AppTests.swift`:

```swift
import XCTest

final class AppTests: XCTestCase {
    func testPlaceholderPasses() {
        XCTAssertTrue(true)
    }
}
```

- [ ] **Step 4: Create `FeatureA`'s source and existing test target**

```bash
mkdir -p tests/fixtures/test-target-candidate/FeatureA/Sources
mkdir -p tests/fixtures/test-target-candidate/FeatureA/Tests
```

`tests/fixtures/test-target-candidate/FeatureA/Sources/FeatureA.swift`:

```swift
public enum FeatureALabel {
    public static let text = "FeatureA"
}
```

`tests/fixtures/test-target-candidate/FeatureA/Tests/FeatureATests.swift`:

```swift
import XCTest
@testable import FeatureA

final class FeatureATests: XCTestCase {
    func testLabel() {
        XCTAssertEqual(FeatureALabel.text, "FeatureA")
    }
}
```

- [ ] **Step 5: Create `FeatureB`'s source (no test target yet)**

```bash
mkdir -p tests/fixtures/test-target-candidate/FeatureB/Sources
```

`tests/fixtures/test-target-candidate/FeatureB/Sources/FeatureB.swift`:

```swift
public enum FeatureBLabel {
    public static let text = "FeatureB"
}
```

- [ ] **Step 6: Write `EXPECTATIONS.md`**

```markdown
# test-target-candidate

## Starting state

- Pinned Tuist version: **4.206.0** (matches this repository's other
  fixtures).
- Five targets: `App`/`AppTests` (entry point depending on both
  features), `FeatureA`/`FeatureATests`, `FeatureB` (no test target).
- One custom `Scheme` named `App`, `shared: true`, whose `buildAction`
  covers `App`/`FeatureA`/`FeatureB` and whose `testAction` bundles
  `AppTests` and `FeatureATests` — `FeatureB` is deliberately not
  included anywhere in this scheme's `testAction`, since it has no test
  target yet.
- Verified live: `tuist generate --no-open` succeeds; `xcodebuild build`
  for scheme `App` succeeds.

## `FeatureA`: the "already has a unit test target" candidate

- `FeatureATests` already exists, `product: .unitTests`, depends on
  `FeatureA`.
- `ios-tuist-test-target` is expected to refuse a "create a unit test
  target for FeatureA" request, reporting that `FeatureATests` already
  exists, and make no changes.

## `FeatureB`: the "create it" candidate

- No test target exists for `FeatureB` yet, and it is not present in the
  custom `App` scheme's `testAction`.
- `ios-tuist-test-target` is expected to, given "create a unit test
  target for FeatureB":
  - Create `FeatureBTests` (`product: .unitTests`, depends on
    `FeatureB`), with one labeled placeholder test only.
  - Add `FeatureBTests` to the existing custom `App` scheme's
    `testAction` target list, alongside `AppTests` and `FeatureATests`
    (never replacing that list).
  - Leave `App`, `AppTests`, `FeatureA`, `FeatureATests` manifest
    declarations and all source file contents byte-identical.

## What must NOT change

- Any `.swift` source file's contents in `App/`, `FeatureA/`.
- `FeatureA`'s manifest declaration or its existing `FeatureATests`
  target (not named in the "create for FeatureB" request, so untouched).
- The custom `App` scheme's `buildAction` and `runAction` (only its
  `testAction` target list gains one entry).
- Bundle IDs, target names, and dependency edges for every
  already-existing target.

## Manual validation (not run by the outer CI matrix)

1. `mise exec tuist@4.206.0 -- tuist install` and `tuist generate
   --no-open` succeed from this directory as committed.
2. `xcodebuild -workspace TestTargetCandidate.xcworkspace -scheme App
   -destination 'generic/platform=iOS Simulator' build` succeeds.
3. Applying `ios-tuist-test-target`'s creation to `FeatureB` (unit test
   target), then `tuist generate --no-open` succeeds, `xcodebuild build`
   for scheme `App` succeeds, and `xcodebuild test -scheme App` runs and
   passes `FeatureBTests`' placeholder alongside the existing
   `AppTests`/`FeatureATests`.
4. `FeatureA`/`FeatureATests` and the scheme's `buildAction`/`runAction`
   are unchanged throughout.

CI (`validate-fixtures.yml`) only proves step 1–2's pre-creation state is
real and buildable at 4.206.0 — steps 3–4 are `ios-tuist-test-target`'s
own Validation step, exercised when the skill actually runs, per the
v0.5 spec §4.2.
```

- [ ] **Step 7: Validate the fixture generates and builds at its pinned
  version**

```bash
cd tests/fixtures/test-target-candidate
mise install tuist@4.206.0
test "$(mise exec tuist@4.206.0 -- tuist version)" = "4.206.0"
mise exec tuist@4.206.0 -- tuist install
mise exec tuist@4.206.0 -- tuist generate --no-open
xcodebuild -workspace TestTargetCandidate.xcworkspace -scheme App \
  -destination 'generic/platform=iOS Simulator' build
```

Expected: version check passes; `tuist install`/`tuist generate`
succeed; `** BUILD SUCCEEDED **`.

- [ ] **Step 8: Confirm the FeatureB test-target creation works
  end-to-end (proves the fixture's "create it" path is real, not
  assumed)**

```bash
mkdir -p FeatureB/Tests
cat > FeatureB/Tests/FeatureBTests.swift <<'EOF'
// Structural placeholder proving FeatureBTests is wired correctly.
// Replace with real coverage — not a substitute for actual tests.
import XCTest
@testable import FeatureB

final class FeatureBTestsPlaceholder: XCTestCase {
    func testTargetIsWiredCorrectly() {
        XCTAssertTrue(true)
    }
}
EOF
python3 - <<'PYEOF'
content = open("Project.swift").read()

old_targets_tail = '''        .target(
            name: "FeatureB",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.test-target-candidate-featureb",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["FeatureB/Sources/**"]
        )
    ],'''
new_targets_tail = '''        .target(
            name: "FeatureB",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.test-target-candidate-featureb",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["FeatureB/Sources/**"]
        ),
        .target(
            name: "FeatureBTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.test-target-candidate-featureb-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["FeatureB/Tests/**"],
            dependencies: [.target(name: "FeatureB")]
        )
    ],'''
assert old_targets_tail in content, "expected FeatureB target block not found"
content = content.replace(old_targets_tail, new_targets_tail)

old_test_action = 'testAction: .testAction(targets: ["AppTests", "FeatureATests"]),'
new_test_action = 'testAction: .testAction(targets: ["AppTests", "FeatureATests", "FeatureBTests"]),'
assert old_test_action in content, "expected testAction target list not found"
content = content.replace(old_test_action, new_test_action)

open("Project.swift", "w").write(content)
PYEOF
rm -rf TestTargetCandidate.xcworkspace TestTargetCandidate.xcodeproj Derived
mise exec tuist@4.206.0 -- tuist generate --no-open
xcodebuild -workspace TestTargetCandidate.xcworkspace -scheme App \
  -destination 'generic/platform=iOS Simulator' build
SIMULATOR_ID="$(xcrun simctl list devices available --json | ruby -rjson -e '
  devices = JSON.parse(STDIN.read).fetch("devices").values.flatten
  iphone = devices.find { |device| device["isAvailable"] && device["name"].start_with?("iPhone") }
  abort "No available iPhone simulator found" unless iphone
  print iphone.fetch("udid")
')"
xcodebuild test -workspace TestTargetCandidate.xcworkspace -scheme App -destination "id=$SIMULATOR_ID"
```

Expected: `tuist generate` succeeds, `** BUILD SUCCEEDED **`, `**
TEST SUCCEEDED **` with `FeatureBTestsPlaceholder`,
`AppTests`, and `FeatureATests` all reported as passed. Do not proceed
to Step 9 until this is confirmed — an unexpected failure here means the
fixture's "create it" candidate isn't actually clear.

- [ ] **Step 9: Revert the probe creation — restore the committed
  pre-creation state**

```bash
git checkout -- Project.swift
rm -rf FeatureB/Tests
rm -rf TestTargetCandidate.xcworkspace TestTargetCandidate.xcodeproj Derived
```

(`git checkout -- Project.swift` only works once Task 2's files are
staged/committed — if running Steps 7–9 before Step 10's commit, restore
via the Step 2 content directly instead: re-run Step 2's heredoc, or
reverse Step 8's Python replacement. Confirm `git diff Project.swift`
shows no difference from Step 2's authored content before proceeding.)

- [ ] **Step 10: Clean generated artifacts before committing**

```bash
cd /Users/dave/Documents/GitHub/ios-tuist-skills
rm -rf tests/fixtures/test-target-candidate/Derived
rm -rf tests/fixtures/test-target-candidate/TestTargetCandidate.xcworkspace
rm -rf tests/fixtures/test-target-candidate/TestTargetCandidate.xcodeproj
rm -rf tests/fixtures/test-target-candidate/FeatureB/Tests
git status --short tests/fixtures/test-target-candidate/
```

Expected: only the 8 authored files from Steps 1–6 show as untracked —
no generated project/workspace/Derived content, no leftover
`FeatureB/Tests`, and `Project.swift` matches Step 2's content exactly
(not the Step 8 probe version).

- [ ] **Step 11: Commit**

```bash
git add tests/fixtures/test-target-candidate/
git commit -m "test: add test-target-candidate fixture (create and refuse paths)"
```

---

### Task 3: Extend `.github/workflows/validate-fixtures.yml` with the new fixture

**Files:**
- Modify: `.github/workflows/validate-fixtures.yml`

**Interfaces:**
- Consumes: `tests/fixtures/test-target-candidate/` (must already exist
  and build at 4.206.0, from Task 2).
- Produces: the extended regression gate described in spec §4.2.
  `scripts/validate-fixtures-locally.sh` requires no change — it reads
  this file's matrix directly.

- [ ] **Step 1: Read the current workflow file**

```bash
cat .github/workflows/validate-fixtures.yml
```

Confirm the existing `matrix.include` list and its `workspace`/
`resolve_cmd`/`test_schemes` fields, and the current `runs-on:` value
(routed to the self-hosted runner as a temporary measure — see its
inline comment) before editing.

- [ ] **Step 2: Add one entry to the matrix**

Add this entry to the `matrix.include` list, alongside the eight
existing entries:

```yaml
          - fixture: test-target-candidate
            tuist: 4.206.0
            workspace: TestTargetCandidate
            resolve_cmd: install
            test_schemes: App
```

- [ ] **Step 3: Verify the workflow YAML is still syntactically valid**

```bash
ruby -ryaml -e "YAML.load_file('.github/workflows/validate-fixtures.yml'); puts 'OK: YAML valid'"
```

Expected: `OK: YAML valid`.

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/validate-fixtures.yml
git commit -m "ci: validate test-target-candidate fixture"
```

- [ ] **Step 5: Validate locally via the committed script, then confirm
  on the self-hosted runner**

```bash
./scripts/validate-fixtures-locally.sh test-target-candidate
```

Expected: `test-target-candidate: PASS` in the summary. This script
reads the matrix straight from the workflow file, so it picks up the new
entry automatically.

Push to `origin` (this repo's self-hosted runner is already registered
and listening — see the "self-hosted CI" project context) is a decision
made with the user once the whole plan is done, same as prior
milestones' publish step.

---

### Task 4: README.md, CHANGELOG.md, and plugin version updates

**Files:**
- Modify: `README.md`
- Modify: `CHANGELOG.md`
- Modify: `.claude-plugin/plugin.json`

**Interfaces:**
- Consumes: everything built in Tasks 1–3 (this task documents the
  finished v0.5 state).
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

Add one new subsection after the existing `ios-tuist-restyle` entry,
matching the existing style exactly (heading, one paragraph, one example
prompt):

```markdown
### `ios-tuist-test-target`

Creates a new unit, integration, or UI test target for one explicitly
user-named existing target, following the project's own testing and
naming conventions, and enrolls the new target in the relevant scheme's
test action. Refuses when a test target of the requested kind already
exists. Generates a single labeled placeholder test only — never real
coverage. Example: "Add a unit test target for FeatureA."
```

- [ ] **Step 3: Update `README.md`'s Repository layout section**

Change:
```
skills/               Bootstrap, feature, dependency, module,
                      architecture-review, CI, migration, and
                      restyle skills
```
to:
```
skills/               Bootstrap, feature, dependency, module,
                      architecture-review, CI, migration, restyle, and
                      test-target skills
```

- [ ] **Step 4: Update `README.md`'s Fixtures and CI section**

Add one bullet after the existing nine, matching the existing style:

```markdown
- [test-target candidate](tests/fixtures/test-target-candidate/EXPECTATIONS.md):
  a target that already has a unit test target and a target that
  doesn't, plus a custom scheme `ios-tuist-test-target` must enroll the
  new target into correctly
```

- [ ] **Step 5: Update `README.md`'s spec link**

Add a line after the existing v0.4 spec link:

```markdown
The v0.5 milestone (test-target creation and scheme enrollment) is
specified in the
[v0.5 design specification](docs/superpowers/specs/2026-09-20-ios-tuist-skills-v0.5-design.md).
```

- [ ] **Step 6: Add the `[0.5.0]` entry to `CHANGELOG.md`**

Replace the `## [Unreleased]` line's empty body with:

```markdown
## [Unreleased]

## [0.5.0] - 2026-09-20

### Added

- `ios-tuist-test-target`: creates a new unit, integration, or UI test
  target for one explicitly user-named existing target and enrolls it
  in the relevant scheme's test action, following the project's own
  testing and naming conventions. Represents "integration test" as a
  named `.unitTests` target since Tuist has no distinct product case for
  it. Generates a single labeled placeholder test only — never real
  coverage. Refuses when a test target of the requested kind already
  exists.
- `test-target-candidate` fixture: a real Tuist 4.206.0 project with a
  target that already has a unit test target (FeatureA) and a target
  that doesn't (FeatureB), plus a custom scheme bundling the existing
  test target, wired into the existing fixture-validation CI matrix.
```

- [ ] **Step 7: Bump the plugin version and description**

In `.claude-plugin/plugin.json`, change:
```json
  "description": "Version-aware iOS engineering skills for Tuist-based projects: safe bootstrap, feature addition, dependency management, module extraction, architecture review, CI auditing, explicit version migration, and folder-integration restyling that detect the project's real Tuist/Xcode/Swift versions and preserve existing conventions.",
  "version": "0.4.0",
```
to:
```json
  "description": "Version-aware iOS engineering skills for Tuist-based projects: safe bootstrap, feature addition, dependency management, module extraction, architecture review, CI auditing, explicit version migration, folder-integration restyling, and test-target creation that detect the project's real Tuist/Xcode/Swift versions and preserve existing conventions.",
  "version": "0.5.0",
```

- [ ] **Step 8: Verify plugin.json is still valid JSON**

```bash
python3 -m json.tool .claude-plugin/plugin.json
```

Expected: pretty-printed JSON output, no error.

- [ ] **Step 9: Commit**

```bash
git add README.md CHANGELOG.md .claude-plugin/plugin.json
git commit -m "docs: document v0.5 test-target skill and bump plugin version"
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
# ios-tuist-test-target SKILL.md exists and starts with valid frontmatter
head -1 skills/ios-tuist-test-target/SKILL.md | grep -q '^---$' && echo "OK: SKILL.md frontmatter" || echo "MISSING/BROKEN: SKILL.md"

# test-target-candidate fixture has EXPECTATIONS.md naming both targets
test -f tests/fixtures/test-target-candidate/EXPECTATIONS.md && echo "OK: EXPECTATIONS.md exists" || echo "MISSING: EXPECTATIONS.md"
grep -q "FeatureA" tests/fixtures/test-target-candidate/EXPECTATIONS.md && grep -q "FeatureB" tests/fixtures/test-target-candidate/EXPECTATIONS.md && echo "OK: names both targets" || echo "MISSING: target detail"

# No new shared reference file was added
test $(ls references | wc -l) -eq 5 && echo "OK: still 5 shared reference files" || echo "UNEXPECTED: reference file count changed"

# CI matrix includes test-target-candidate
grep -q "fixture: test-target-candidate" .github/workflows/validate-fixtures.yml && echo "OK: CI matrix entry" || echo "MISSING: CI matrix entry"

# Plugin version bumped
grep -q '"version": "0.5.0"' .claude-plugin/plugin.json && echo "OK: plugin.json version" || echo "MISSING: plugin.json version bump"

# CHANGELOG has the 0.5.0 entry
grep -q '## \[0.5.0\]' CHANGELOG.md && echo "OK: CHANGELOG 0.5.0 entry" || echo "MISSING: CHANGELOG 0.5.0 entry"

# No invented .integrationTests product anywhere in the new skill or fixture
grep -rn "\.integrationTests" skills/ios-tuist-test-target/ tests/fixtures/test-target-candidate/ && echo "UNEXPECTED: invented .integrationTests product found" || echo "OK: no invented product case"
```

Expected: every check prints `OK:` — fix any gap found before
proceeding.

- [ ] **Step 2: Confirm local validation evidence, then the self-hosted
  CI run**

```bash
git status --short
./scripts/validate-fixtures-locally.sh
```

Expected: clean working tree (everything from Tasks 1–4 already
committed), and every fixture in the summary — including
`test-target-candidate` — prints `PASS`.

- [ ] **Step 3: Confirm no leftover `.gitkeep` made obsolete**

`skills/ios-tuist-test-target/references/` stays genuinely empty in v0.5
(no skill-specific reference content beyond root `references/` was
needed) — its `.gitkeep` remains; do not remove it.

- [ ] **Step 4: Final commit (only if Step 1 found and fixed a gap)**

```bash
git add -A
git commit -m "chore: v0.5 spec-compliance sweep"
```

If Step 1 found no gaps, skip this commit — an empty sweep commit is not
required (same precedent as v0.4 Task 5, where no gaps meant no sweep
commit was made).

---

## Post-plan note

This plan covers exactly the v0.5 milestone (spec §1, §7):
`ios-tuist-test-target` scoped to test-target creation and scheme
enrollment only. Do not push to `origin` as part of executing this plan
beyond what Task 3 Step 5 already covers (pushing the CI matrix change
itself, already done in the current session prior to this plan) —
pushing the remaining commits is a decision made with the user once the
whole plan is done and locally validated, consistent with how prior
milestones were finished.
