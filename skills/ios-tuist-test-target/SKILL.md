---
name: ios-tuist-test-target
description: >
  Use when adding a unit, integration, or UI test target to one
  explicitly named existing target in a Tuist project; not for adding
  test cases to an existing test target, broad scheme audits, or
  project-wide test-target sweeps.
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
   default to `{Target}Tests` (unit/integration) or `{Target}UITests`
   (UI) — see below for how unit vs. integration is distinguished,
   since Tuist has no separate `product` case for "integration test."
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
`.unitTests` and `.uiTests` — there is no separate integration-test
product case. This skill represents "integration test target" as a
second `.unitTests` target distinguished by name and folder only (e.g.
`FeatureATests` for unit, `FeatureAIntegrationTests` for integration) —
never by inventing an unsupported product type. State this fact plainly
in the Output Contract when the request is for an integration-test kind,
so the user understands why the generated target's `product:` reads
`.unitTests`.

### Scheme enrollment

Most projects have no custom `Scheme` at all — Tuist generates one
default scheme per target automatically, and that default scheme already
includes the new test target's own default scheme the moment `tuist
generate` runs; nothing needs to be written for this case. Enrollment
work is only needed, and only performed, when the project already defines
a **custom** `Scheme` (in `Project.swift`'s `schemes:` argument or a
`Workspace.swift`) whose `testAction` bundles multiple test targets
together. In that case:

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
- Never invent an unsupported integration-test product case — represent
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
