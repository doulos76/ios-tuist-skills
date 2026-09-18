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
