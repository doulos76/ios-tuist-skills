---
name: ios-tuist-restyle
description: >
  Converts one or more explicitly user-named targets' folder integration
  from array-based sources:/resources: declarations to buildableFolders,
  gated by a per-target safety checklist grounded in real Tuist defects
  and their regression history. Never sweeps a whole project, never
  bundles a version bump, never silently drops an exclusion.
---

# Core Rule

Convert only targets the user explicitly names. Evaluate each named
target's safety checklist independently — one target's refusal never
blocks another named target's conversion. A refusal is a complete, valid
outcome, never a partial or best-effort conversion.

## Purpose

Convert one or more explicitly user-named targets' folder integration
from array-based `sources:`/`resources:` declarations to
`buildableFolders`, applying a safety checklist before acting — refusing
the conversion (and saying why) for any named target where the
checklist finds a real risk, per target, independently.

## Trigger Conditions

- "Convert FeatureA to buildableFolders"
- "Migrate the App target's sources/resources arrays to buildable
  folders"
- "Switch NetworkingKit away from sources arrays"

The request must name one or more specific targets.

## Non-Trigger Conditions

- The request asks to convert "the whole project" or names no specific
  target(s) — out of scope for this pass; ask which target(s) to
  convert rather than sweeping every target in one run.
- The named target(s) already use `buildableFolders` — report there is
  nothing to convert and stop.
- The request is about a different structural/style convention (linkage
  strategy, dependency integration method, architecture pattern) — out
  of scope; state this explicitly rather than bundling an unrelated
  convention change into a folder-integration request.
- The request is really a version migration ("upgrade Tuist and
  modernize the folder structure") — the version part belongs to
  [`ios-tuist-migrate`](../ios-tuist-migrate/SKILL.md); if the user
  wants both, they are two separate, sequential requests, not one
  combined operation.
- No existing Tuist project, or the named target doesn't exist in the
  project's manifests.

## Preconditions

An existing Tuist project is present and readable; one or more specific
existing target names are given; each named target's current manifest
declares `sources:` and/or `resources:` as literal arrays (not already
`buildableFolders`).

## Version Safety

Full [version-safety](../../references/version-safety.md) procedure,
Existing Project Mode. `buildableFolders` requires **Tuist 4.62.0 or
later** (introduced in that release, mapping to Xcode 16's
synchronized-groups feature). If the project-pinned Tuist version is
older than 4.62.0, refuse every named target and say so — do not
proceed, and do not silently suggest a version bump (that decision
belongs to `ios-tuist-migrate`, on a separate explicit request per the
Non-Trigger Conditions above).

## Workflow

1. **Resolve the target list** — the specific target name(s) named in
   the request. For each, confirm it exists in the project's manifests
   and currently declares `sources:`/`resources:` arrays (not already
   `buildableFolders`).
2. **Confirm the Tuist version floor** — project-pinned version ≥ 4.62.0
   ([version-safety](../../references/version-safety.md)). Below the
   floor: refuse all named targets, report why, stop.
3. **Apply the per-target safety checklist** (below) to each named
   target independently — one target's refusal does not block another
   named target's conversion; report both outcomes.
4. **Decision gate, per target:**
   ```text
   Checklist clear for this target (no item flags a real risk)?
           |
          Yes -> convert this target
           |
          No  -> refuse this target's conversion; report which
                 checklist item(s) failed and why; make no changes to
                 this target's manifest
   ```
5. **If converting: rewrite the target's manifest declaration** —
   replace the `sources:`/`resources:` array arguments with a single
   `buildableFolders:` array covering the same directories. Do not move,
   rename, or alter any source or resource file on disk — this is a
   manifest-only structural change, never a file-content or file-layout
   change.
6. **Validate** — `tuist generate` succeeds for the affected target(s)
   and any dependent target(s); the affected target(s) build; the
   affected target(s)' existing tests run and pass; no other target's
   manifest or generated output changes.

### Per-target safety checklist (refusal gate)

Every item must have a concrete, stated answer, checked against the
actual target's manifest and file tree — never assumed. Any item
answered "yes, this risk is present" is a reason to refuse that target's
conversion and report why; it is not a box to check past. A refusal is a
valid, complete outcome for that target.

- **Exclude patterns:** Does the target's current `sources:`/
  `resources:` arrays use Tuist's real exclusion mechanism — the
  `.glob(pattern:excluding:)` case (e.g. `sources: [.glob("Sources/**",
  excluding: ["Sources/Generated/**"])]`) — or any per-file compiler
  flag/setting? `buildableFolders` has no supported equivalent for
  excluding specific files or paths within an included folder as of the
  project-pinned version — a target relying on exclusion cannot be
  safely converted without silently losing that exclusion.
- **Cross-target file references:** Does any *other* target's manifest
  reference an individual file that lives inside this target's
  source/resource directories (rather than depending on the target as a
  whole)? Tuist's buildable-folders implementation can fail to add such
  a file to the right build phase once the owning target is converted —
  a real Tuist defect (tuist/tuist#8337, closed as "not planned," i.e.
  the limitation itself is acknowledged and intentionally left as-is,
  not a bug awaiting a fix), not a hypothetical.
- **Static framework + resources:** Is the target's `product:`
  `.staticFramework` (or `.staticLibrary`) AND does it declare
  `resources:`? Buildable-folder resource placement for static products
  has a real history of breakage in Tuist — the original defect
  (tuist/tuist#8547) was fixed in ~4.100.0, but the same resource-bundle
  path has regressed at least twice since (tuist/tuist#9156, a
  `BundleNotFound` crash introduced in 4.128.2; tuist/tuist#9289, a
  missed resource-bundle copy introduced in 4.133.1) — so "fixed once"
  does not mean "stable," and no single version floor can be cited as
  safe going forward. Never wave this item through solely because the
  project-pinned version is newer than 4.100.0. Instead: check Tuist's
  release notes for the project-pinned version and any versions between
  it and the nearest prior stable point for a static-framework-resources
  regression; if none is found, note this item as checked-with-residual-
  risk (not "clear") in the Output Contract rather than silently
  treating absence of a known issue as proof of safety.
- **Directory-level overlap:** Would the resulting `buildableFolders`
  paths overlap with another target's `buildableFolders` or
  `sources`/`resources` paths (e.g. two targets both claiming a parent
  directory)? Overlapping folder ownership is unsupported/undefined
  behavior, not merely discouraged style.
- **Generated or derived sources:** Does the target's current sources
  include any path generated by a build step (codegen output, a symlink
  into another location, anything not a plain committed file under the
  target's own directory)? `buildableFolders` assumes ordinary on-disk
  files under the given paths.

### Verified conversion shape

```swift
// Before
Target(
    // ...
    sources: ["Sources/**/*.swift"],
    resources: ["Resources/**"]
)

// After
Target(
    // ...
    buildableFolders: ["Sources", "Resources"]
)
```

A single `buildableFolders:` array replaces **both** `sources:` and
`resources:` — it is not two separate one-to-one replacements. Do not
retain `sources:`/`resources:` alongside `buildableFolders:` in the same
target's declaration.

## Decision Rules

- Never convert a target the user didn't name.
- Never sweep "the whole project" in one run — even if multiple targets
  are named, evaluate and report each one's checklist result
  independently; a mixed proceed/refuse outcome across named targets is
  valid and expected.
- Never silently drop an exclusion pattern, per-file flag, or any other
  expressive capability that array-based `sources:`/`resources:` had and
  `buildableFolders` cannot represent — refuse instead.
- Never move, rename, or edit the contents of any source or resource
  file — this skill only rewrites manifest declarations.
- Never bundle a Tuist version bump into this conversion, even if the
  project is below the 4.62.0 floor — refuse and point at
  `ios-tuist-migrate` as the separate, explicit next step if the user
  wants one.
- A refusal (version floor not met, checklist risk found, no target
  named, target already converted) is a valid, complete outcome of this
  skill, independently per named target.

## Validation

Required before declaring success: `tuist generate` succeeds; every
converted target builds; every converted target's existing tests run
and pass; the generated project for every **non-converted** target is
unchanged (spot-check: a target not named in the request produces
identical generated output before and after).

## Failure Handling

Evidence-Driven Debugging, same procedure as the other skills. First
hypothesis to consider here specifically: a file under the converted
target's directory that was previously excluded by an array pattern is
now silently included (or a file expected inside is missing from the
generated bundle), surfacing as an unexpected extra file in the build or
a missing-resource runtime failure — always diff the target's generated
file membership before and after, not just "did it build."

## Output Contract

```text
Version Context (Tuist version vs. the 4.62.0 buildableFolders floor)
Targets Requested
Checklist Results (one per target: item-by-item findings)
Targets Converted (manifest diff, per target)
Targets Refused (which checklist item(s) failed, per target)
Validation Performed (generate/build/test, per converted target)
Unverified Items
Risks / Follow-up
```

Example:

```text
Version Context: Tuist 4.206.0 (project-pinned) — above the 4.62.0
buildableFolders floor.

Targets Requested: FeatureA, SharedUI

Checklist Results:
- FeatureA: no exclude patterns; no cross-target file references found
  (checked all other targets' manifests); product is .staticFramework
  but declares no resources: (tuist/tuist#8547 doesn't apply); no
  directory overlap with any other target; no generated/derived sources.
  Clear.
- SharedUI: sources array uses an exclude pattern
  (`sources: [.glob("Sources/**", excluding: ["Sources/Preview/**"])]`)
  with no buildableFolders equivalent. Risk found — refused.

Targets Converted:
- FeatureA: Project.swift — `sources: ["FeatureA/Sources/**"],
  resources: ["FeatureA/Resources/**"]` replaced with
  `buildableFolders: ["FeatureA/Sources", "FeatureA/Resources"]`.

Targets Refused:
- SharedUI: exclude pattern `Sources/Preview/**` has no buildableFolders
  equivalent as of Tuist 4.206.0; converting would silently include
  Sources/Preview/** in the build. No changes made to SharedUI.

Validation:
- tuist generate succeeded
- FeatureA build succeeded
- FeatureA's existing tests passed
- SharedUI's generated output unchanged (not touched)

Risks / Follow-up:
- SharedUI could be converted later if its Preview sources are moved
  out of the excluded path first, or if Tuist adds a buildableFolders
  exclusion mechanism — not applied here since neither is true today.
```
