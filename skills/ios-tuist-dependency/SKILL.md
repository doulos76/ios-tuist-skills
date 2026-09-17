---
name: ios-tuist-dependency
description: >
  Adds, removes, or relocates Swift Package, binary, or local
  dependencies in a Tuist-based iOS project using the correct
  Tuist integration approach, scoped to the narrowest target that
  actually requires the dependency.
---

# Core Rule

Never attach a dependency to a wider target than necessary. Identify the
actual consumer target before writing any manifest change. See
[dependencies](../../references/dependencies.md).

## Purpose

Add, remove, or relocate a dependency using the Tuist integration
approach already established in the project (or the correct one for a
new dependency type), attached only to the target(s) that need it.

## Trigger Conditions

- "Add [Package] to [Target]"
- "Remove [Package] from [Target]"
- "Move [Package] from [Target A] to [Target B]"
- "Add [Package] only to [Target]" (narrowest-target framing is often
  explicit — always honor it)

## Non-Trigger Conditions

- The request requires creating new feature scaffolding beyond wiring the
  dependency in — the feature-creation part belongs to
  `ios-tuist-feature`; this skill handles the dependency-attachment
  portion once the target exists.
- No existing Tuist project — `ios-tuist-bootstrap` territory (a brand
  new project's initial dependencies are chosen during bootstrap, not
  here).

## Preconditions

The consumer target must be identifiable — either stated explicitly in
the request, or inferable from actual/clearly-intended `import` usage in
the codebase. If genuinely ambiguous, ask rather than guessing widely.

## Version Safety

Apply [version-safety](../../references/version-safety.md) in full. The
project's pinned Tuist version determines which dependency-declaration
syntax is valid (Tuist-native `Tuist/Package.swift` integration vs
Xcode-native SwiftPM integration). Generate for the pinned version.

Apply [source-of-truth](../../references/source-of-truth.md)'s
**Existing Project Mode** before changing any dependency declaration.

## Workflow

1. **Identify the consumer target.** Use the explicit target from the
   request if given. If ambiguous, search actual/intended `import`
   statements and prefer the narrowest valid target — never default to
   the app target to sidestep the question.
2. **Check the current dependency integration mechanism** already used in
   this repository (inspect existing `Tuist/Package.swift` or Xcode
   project SwiftPM references).
3. **Classify the dependency** using
   [dependencies](../../references/dependencies.md)'s taxonomy (Swift
   package library, macro, build tool plugin, binary framework,
   XCFramework, local package, local Tuist project, system framework).
4. **Determine the compatible declaration approach** for the detected
   Tuist version and the existing integration mechanism. Do not convert
   the project from one integration mechanism to another unless the task
   explicitly requires it.
5. **Attach to the identified target only.** Never widen to the app
   target or to unrelated targets "to be safe."
6. **Resolve/install** the dependency (e.g. `tuist install`).
7. **Generate** (`tuist generate`).
8. **Build** the affected target(s) and the app.

## Decision Rules

- The narrowest-target rule is non-negotiable: a dependency only used by
  `ProfileFeature` is attached to `ProfileFeature`, never to `App`, even
  if `App` transitively depends on `ProfileFeature` and "it would still
  work."
- Do not convert an existing SPM integration mechanism unless the task
  explicitly requires it.
- Preserve existing version-constraint style unless the task requires
  changing it (see
  [dependencies](../../references/dependencies.md)).
- If integrating a binary or local target requires an explicit linkage
  choice, apply [modularization](../../references/modularization.md)'s
  graph-based linkage decision rather than selecting a universal default.

## Validation

Required before declaring the task complete:

1. The dependency resolves successfully (`tuist install` or equivalent).
2. `tuist generate` — must succeed.
3. The consumer target and the app build successfully.

## Failure Handling

Same Evidence-Driven Debugging procedure as the other two skills.
Additional first hypothesis to consider here specifically: a version
constraint conflict between the newly added dependency and an existing
one in the graph.

## Output Contract

Same structure as the other two skills, with "Dependency Changes"
populated with specifics:

```text
Version Context
Changes Made
Files Changed
Dependency Changes
Validation Performed
Build Result
Test Result
Unverified Items
Risks / Follow-up
```

Example:

```text
Tuist: 4.x.y (project-pinned)
Active Tuist: 4.x.y (matches)

Changed:
- attached Kingfisher (Swift package library) to ProfileFeature target only

Dependency Changes:
- Package: Kingfisher
- Version constraint: from: "7.0.0" (matches repo's existing constraint style)
- Attached to: ProfileFeature (only)
- Integration mechanism: Tuist/Package.swift (existing repo convention, unchanged)

Validation:
- tuist install: success
- tuist generate: success
- ProfileFeature build: success
- App build: success

Not changed:
- App target's own dependency list
- Any other feature target
```
