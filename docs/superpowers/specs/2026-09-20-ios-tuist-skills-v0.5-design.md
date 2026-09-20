# ios-tuist-skills v0.5 — Design Spec

- **Status:** Approved for planning
- **Date:** 2026-09-20
- **Source:** Defined in-conversation (no external PRD). User-selected
  direction: test/scheme management, narrowed to a concrete, previously
  uncovered gap — creating a new test target and wiring it into a
  scheme.
- **Scope:** One new skill — `ios-tuist-test-target` — scoped to
  **creating a new unit/integration/UI test target for a user-named
  existing target, and enrolling it in the appropriate scheme's test
  action**, as an empty skeleton (no real test logic, one labeled
  placeholder file only).
- **Planning/review owner:** Claude

## 1. Purpose

`references/testing.md` already states this repository's test-framework
policy (Swift Testing preferred, XCTest preserved where already
standardized, XCUI for UI tests), and `ios-tuist-feature` already
consumes that policy when adding test *code* to an existing test target.
But nothing in this repository creates a **new test target** — the
structural, target-graph-level operation of adding a `.unitTests` /
`.uiTests` product to a project and making sure a scheme actually runs
it. Today, a user who wants to add, say, an integration-test target
alongside an existing feature's unit tests has no skill that performs
this safely; they'd have to hand-edit `Project.swift` and hope the
generated (or custom) scheme picks up the new target.

v0.5 closes that gap: `ios-tuist-test-target` creates one new test
target for one user-named existing target, using the project's own
testing conventions (framework, naming, folder layout), and enrolls it
in that target's scheme test action when a custom scheme already exists
— never inventing test logic beyond a single, clearly labeled skeleton
file proving the target builds and runs.

This is a different axis from every existing skill:

- `ios-tuist-feature` adds real test *code* inside a test target that
  already exists; it never creates a new test target.
- `ios-tuist-module` extracts existing code (and its existing tests)
  into a new non-test target; it never creates a test-only target from
  scratch.
- `ios-tuist-ci` audits CI workflow files, not `Project.swift`/
  `Workspace.swift` scheme definitions.

Explicitly out of scope for v0.5 (deferred or never): writing real test
assertions or business-logic coverage (that's `ios-tuist-feature`, once
the target exists); a general "audit all schemes for gaps" mode (a
read-only scheme-audit skill is a plausible future milestone, not this
one); test plans (`.xctestplan` files) as a distinct concept from scheme
test actions; any change to a target that isn't a test product.

## 2. Repository layout additions

```text
ios-tuist-skills/
├── skills/
│   └── ios-tuist-test-target/
│       └── SKILL.md
├── tests/fixtures/
│   └── test-target-candidate/     # ios-tuist-test-target
```

No new shared reference file — `ios-tuist-test-target` reads
`references/testing.md` (framework choice, "no placeholder tests except
a labeled template smoke test" policy — extended here, see §3.3),
`references/source-of-truth.md` (existing conventions win; Workspace.swift
decision rule for custom schemes), and `references/version-safety.md`.

## 3. `ios-tuist-test-target`

**Purpose:** Create a new unit, integration, or UI test target for one
explicitly user-named existing target, following the project's own
testing and naming conventions, and enroll the new target in the
relevant scheme's test action — refusing when a test target of the
requested kind already exists for that target, or reporting explicitly
when no custom scheme exists to enroll into (Tuist's default generated
scheme already covers it).

**Trigger conditions:** "Add a unit test target for FeatureA", "Create
an integration test target for NetworkingKit", "Set up UI tests for the
App target." The request must name one specific existing target and,
explicitly or by clear implication, one test kind (unit / integration /
UI).

**Non-trigger conditions:**

- The request names no existing target, or asks to add test targets
  "everywhere" / "for the whole project" — out of scope for this pass;
  ask which target to scope to rather than sweeping every target in one
  run (same per-target discipline as `ios-tuist-module` and
  `ios-tuist-restyle`).
- The named target already has a test target of the requested kind —
  report the existing target's name and stop; do not create a second
  one.
- The request is to add actual test *cases* / assertions to a test
  target that already exists — that's `ios-tuist-feature`; state this
  explicitly rather than silently writing test logic here.
- The request is to extract existing code (and its tests) into a new
  non-test module — that's `ios-tuist-module`.
- The request is a general audit of whether existing schemes have gaps,
  with no specific new target wanted — out of scope for this pass (see
  §1); state this rather than guessing at a broad audit.
- No existing Tuist project, or the named target doesn't exist in the
  project's manifests.

**Preconditions:** An existing Tuist project is present and readable;
one specific existing non-test target is named; the requested test kind
(unit / integration / UI) is stated or unambiguous from context.

**Version Safety:** Full
[version-safety](../../references/version-safety.md) procedure, Existing
Project Mode. No version floor is introduced by this skill itself (test
targets and `Scheme`/`TestAction` are long-stable `ProjectDescription`
API); still confirm the pinned version to generate syntax the pinned
version actually accepts, per the repo-wide rule.

**Workflow:**

1. **Resolve the named target** — confirm it exists in the project's
   manifests and is not itself a test product.
2. **Resolve the test kind and target name.** Inspect the project's
   existing test-target naming convention (e.g. `{Target}Tests`,
   `{Target}UITests`) from neighboring targets; if none exists yet,
   default to `{Target}Tests` (unit/integration) or `{Target}UITests`
   (UI) — see §3.1 for how unit vs. integration is distinguished, since
   Tuist has no separate `product` case for "integration test."
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
     has no distinct "integration test" product — see §3.1); `product:
     .uiTests` for UI.
   - `dependencies: [.target(name: "<namedTarget>")]` so Tuist
     auto-configures the host/target-under-test relationship.
   - One labeled placeholder test file only (§3.3) — no real test logic.
6. **Resolve scheme enrollment** (§3.2):
   - If a custom `Scheme` already exists that builds/tests the named
     target, add the new test target to that scheme's `testAction`.
   - If no custom scheme exists (the project relies on Tuist's default
     generated per-target schemes), state this explicitly in the Output
     Contract — Tuist will generate a default scheme for the new test
     target automatically; no manifest scheme change is needed or made.
7. **Validate** — `tuist generate` succeeds; the new test target builds;
   the placeholder test runs and passes (a trivial, always-true
   assertion is the *point* here — it exists only to prove the target is
   wired correctly, per the labeled-smoke-test exception in
   [testing.md](../../references/testing.md)); no other target's
   manifest or generated output changes.

### 3.1 Unit vs. integration: naming, not a distinct product

Tuist's `ProjectDescription` has exactly two test product cases,
`.unitTests` and `.uiTests` — there is no `.integrationTests` case
(verified against the current `ProjectDescription` API surface). This
skill represents "integration test target" as a second `.unitTests`
target distinguished by name and folder only (e.g. `FeatureATests` for
unit, `FeatureAIntegrationTests` for integration) — never by inventing
an unsupported product type. State this fact plainly in the Output
Contract when the request is for an integration-test kind, so the user
understands why the generated target's `product:` reads `.unitTests`.

### 3.2 Scheme enrollment

Per [source-of-truth](../../references/source-of-truth.md)'s
`Workspace.swift` decision rule, most projects have no custom `Scheme`
at all — Tuist generates one default scheme per target automatically,
and that default scheme already includes the new test target's own
default scheme the moment `tuist generate` runs; nothing needs to be
written for this case. Enrollment work is only needed, and only
performed, when the project already defines a **custom** `Scheme` (in
`Project.swift`'s `schemes:` argument or a `Workspace.swift`) whose
`testAction` bundles multiple test targets together (the pattern
`ios-tuist-restyle`'s and other fixtures' `test_schemes` CI matrix field
already exercises, e.g. a shared `App` scheme running several test
targets). In that case:

- Locate the specific custom `Scheme` value(s) that test the named
  target.
- Add the new test target to that `Scheme`'s `testAction` — using
  `TestAction.targets([...])`'s existing target list, appending the new
  target rather than replacing the list.
- Never create a brand-new custom `Scheme` where none existed — that is
  a larger structural decision (see the `Workspace.swift` decision rule)
  out of scope for this skill; if no custom scheme covers the named
  target, rely on Tuist's default generated scheme and say so.

### 3.3 Placeholder file (skeleton, not coverage)

Exactly one file, containing exactly one empty test case, clearly
labeled as a structural placeholder — the same spirit as
[testing.md](../../references/testing.md)'s existing template-smoke-test
exception, extended here to cover a freshly created (non-template) test
target:

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

**Decision Rules:**

- Never create a test target for a target the user didn't name.
- Never create a second test target of the same kind for a target that
  already has one — report the existing target's name instead.
- Never write real test assertions or business-logic coverage — this
  skill's only generated code is the single labeled placeholder in
  §3.3; real coverage is `ios-tuist-feature`'s job, on request.
- Never invent an `.integrationTests` product case — represent
  integration tests as a named `.unitTests` target per §3.1, and say so.
- Never create a new custom `Scheme` where none existed; only enroll
  into a custom scheme that already exists and already tests the named
  target (§3.2).
- Never change an existing test target's contents, dependencies, or
  scheme membership as a side effect of adding a different, new one.
- A refusal (test target of the requested kind already exists, no
  target named, named target doesn't exist) is a valid, complete
  outcome.

**Validation (required before declaring success):** `tuist generate`
succeeds; the new test target builds; the placeholder test runs and
passes; the named target and any custom scheme touched still build/test
as before (spot-check: their generated output is otherwise unchanged).

**Failure Handling:** Evidence-Driven Debugging, same procedure as the
other skills. First hypothesis to consider here specifically: the new
test target fails to resolve its host/target-under-test automatically
because the named target's `product:` isn't one Tuist auto-hosts tests
for (e.g. a `.staticLibrary` with no app/framework host) — verify the
named target's actual product type before assuming the dependency
declaration alone is sufficient.

**Output Contract:**

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
scheme's testAction (Workspace.swift), alongside the existing
FeatureATests entry.

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

## 4. Fixtures and CI validation

### 4.1 `tests/fixtures/test-target-candidate/`

A real, buildable Tuist project, pinned at Tuist 4.206.0, with:

- One target (`FeatureA`) that already has a unit test target
  (`FeatureATests`, Swift Testing) — proves the "already exists, refuse"
  path when a second unit-test-target request targets it.
- One target (`FeatureB`) with **no** test target yet — proves the
  "create it" path, exercised for a unit-test-target request.
- A custom `Scheme` (in `Workspace.swift` or `Project.swift`) whose
  `testAction` already bundles `FeatureATests` — proves the scheme
  enrollment path when `FeatureB`'s new test target should be added to
  that same scheme.

### 4.2 CI (self-hosted validation matrix)

Extend the fixture-validation matrix (currently routed to the
self-hosted runner per the temporary CI-credit measure — see
`.github/workflows/validate-fixtures.yml`) with one more entry:
`test-target-candidate`, pinned at Tuist 4.206.0, validated the same way
as every other fixture. CI validates the fixture's pre-creation state
(both targets and the custom scheme must be real and buildable as
committed) — the actual create-and-revalidate cycle is this skill's own
Validation step, exercised when the skill runs, same pattern as every
prior milestone's fixture.

`scripts/validate-fixtures-locally.sh` picks up the new matrix entry
automatically, same as before.

## 5. CHANGELOG.md and plugin version

- `.claude-plugin/plugin.json` `version` bumps to `0.5.0`; `description`
  gains a mention of test-target creation alongside the existing eight
  capabilities.
- `CHANGELOG.md` gets a `[0.5.0]` entry listing `ios-tuist-test-target`
  and the `test-target-candidate` fixture, following the same
  Keep-a-Changelog style as prior entries.
- `README.md`'s skills list gains an `ios-tuist-test-target` entry
  alongside the existing eight.

## 6. Explicit non-goals (v0.5)

- No real test-case generation beyond the single labeled placeholder —
  writing actual coverage is `ios-tuist-feature`'s job, on request.
- No `.integrationTests` product invention — represented as a named
  `.unitTests` target, stated explicitly every time (§3.1).
- No general scheme-gap audit mode (a plausible future read-only skill,
  not this one).
- No `.xctestplan` test-plan file management — out of scope; this skill
  only touches `Scheme.testAction`'s target list.
- No new custom `Scheme` creation where none existed — only enrollment
  into an already-existing custom scheme (§3.2).
- No project-wide "add tests everywhere" mode — one named target, one
  test kind, per invocation.
- Same restated non-goals as prior milestones continue to apply
  repo-wide (no silent version changes, no forced architecture, no
  side-effect modernization, no changes to targets other than the one
  named and the new test target itself).

## 7. Acceptance criteria for this v0.5 implementation pass

- `ios-tuist-test-target` exists with a complete `SKILL.md` following
  the same section structure as the other eight skills (Purpose, Trigger
  Conditions, Non-Trigger Conditions, Preconditions, Version Safety,
  Workflow, Decision Rules, Validation, Failure Handling, Output
  Contract).
- `tests/fixtures/test-target-candidate/` exists as a real,
  independently buildable Tuist project pinned at Tuist 4.206.0, with
  one target that already has a unit test target, one target that
  doesn't, and a custom scheme bundling the existing test target — plus
  an `EXPECTATIONS.md` naming which target is which and why.
- The fixture-validation workflow is extended to resolve/generate/
  build/test the new fixture at its pinned version alongside the
  existing eight.
- `.claude-plugin/plugin.json` version is `0.5.0` and its description
  mentions test-target creation.
- `README.md` lists `ios-tuist-test-target` alongside the existing eight
  skills.
- `CHANGELOG.md` has a `[0.5.0]` entry.
