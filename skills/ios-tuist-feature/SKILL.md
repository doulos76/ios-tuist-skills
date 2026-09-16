---
name: ios-tuist-feature
description: >
  Adds or modifies features in an existing Tuist-based iOS project
  while preserving project architecture, dependency conventions,
  Tuist version compatibility, and validation requirements.
---

# Core Rule

Do not create a feature before inspecting the project's Tuist version,
neighboring feature structure, target graph, and test conventions. See
[version-safety](../../references/version-safety.md) and
[source-of-truth](../../references/source-of-truth.md).

## Purpose

Add a feature to an existing Tuist project while preserving its existing
architecture, folder layout, dependency conventions, and test style —
never introducing a new pattern inside a single feature.

## Trigger Conditions

- "Add [Feature] to this project" (e.g. "Add LoginFeature")
- "Create a new screen/module for [X]" in a repository that already has a
  Tuist project.

## Non-Trigger Conditions

- No existing Tuist project at the target path — that's
  `ios-tuist-bootstrap`.
- The request is purely about adding/removing/moving a dependency with no
  new feature code — that's `ios-tuist-dependency` (though this skill may
  hand off to that one's reasoning for the dependency-wiring step of a
  larger feature request).

## Preconditions

An existing Tuist project must be present and readable at the target
path (`Project.swift`/`Tuist.swift` present).

## Version Safety

Apply [version-safety](../../references/version-safety.md) in full. This
is **Existing Project Mode**
(see [source-of-truth](../../references/source-of-truth.md)): the
project-pinned version is authoritative. If the active version differs
from the pinned version, report the mismatch as a risk in the Output
Contract and generate manifest syntax for the **pinned** version, not the
active one.

## Workflow

1. **Inspect neighboring features** before writing anything:
   - Target definitions (naming, structure) of at least one existing
     feature.
   - Dependency declarations on those targets.
   - File/folder organization convention.
   - Test style in use (XCTest vs Swift Testing — see
     [testing](../../references/testing.md)).
   - Whether a Tuist scaffold/template already exists for features in
     this repo (check for a `Tuist/Templates/` or similar directory).
   - Target naming convention (e.g. `XFeature`, `XKit`, `Feature.X`).
   - Resource organization (where assets/strings live per feature).
2. **Decide: scaffold or minimal files.**
   ```text
   Existing scaffold found for this repo's feature pattern?
           |
          Yes -> reuse the scaffold as-is
           |
           No
           |
           Is this the Nth time a near-identical structure would be
           hand-written (i.e. is repetition already established, not
           merely anticipated)?
                   |
                  Yes -> creating a new scaffold may be justified;
                         state the justification explicitly
                  No  -> create only the minimum files needed for this
                         one feature
   ```
3. **Connect dependencies minimally** — attach only what the new feature
   actually needs, to the new feature's own target, following
   [dependencies](../../references/dependencies.md)'s narrowest-target
   rule. Do not add dependencies the feature doesn't use "for
   consistency."
4. **Validate** — generate, then build/test only the affected target(s),
   not the whole repository, unless the change is graph-wide (e.g. it
   touches a shared module every target depends on).

## Decision Rules

- Never introduce a new architecture style inside one feature (e.g. don't
  bring MVVM into a repo that is consistently VIPER, even if MVVM is "the
  skill's opinion" — it has none).
- Never migrate an unrelated existing convention as a side effect. If the
  repo uses `sources: ["Sources/**"]` everywhere, the new feature also
  uses `sources: ["Sources/**"]` — do not switch that one feature to
  `buildableFolders`.
- If the user explicitly asks for an architectural change alongside the
  feature, treat that as two things: the architectural change is a
  separate, explicit decision to confirm before proceeding, not something
  to fold in silently.

## Validation

Required before declaring the task complete:

1. `tuist generate` — must succeed.
2. The new feature target and its immediate consumer(s) (e.g. the app
   target that will use it) build successfully.
3. The feature's own tests run and pass, using the repo's existing test
   framework convention.

## Failure Handling

Same Evidence-Driven Debugging procedure as `ios-tuist-bootstrap`
(Observed Facts -> Hypotheses -> Contradiction Search -> Minimal Change).
First hypothesis to consider here specifically: a version mismatch
between the project pin and the active toolchain causing a
`ProjectDescription` API used by neighboring features to fail when
touched.

## Output Contract

Same structure as `ios-tuist-bootstrap`:

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
Tuist: 4.x.y (project-pinned via Tuist.swift)
Active Tuist: 4.x.y (matches)
Xcode: 16.x
Swift: 6.x

Changed:
- added LoginFeature target (matches existing feature-module pattern)
- added dependency on SharedUI (existing shared target)
- added LoginFeatureTests (Swift Testing, matching repo convention)

Validation:
- tuist generate: success
- App build (consumer of LoginFeature): success
- LoginFeatureTests: success

Not changed:
- existing folder integration strategy (sources arrays, unchanged)
- no other feature targets touched
```
