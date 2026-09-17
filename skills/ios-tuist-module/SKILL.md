---
name: ios-tuist-module
description: >
  Extracts existing code from a target into a new Tuist module/target,
  applying the modularization justification checklist before acting —
  refusing the extraction and reporting why when the checklist isn't
  concretely met, rather than splitting code on request alone.
---

# Core Rule

Do not extract code into a new target before applying the full
modularization checklist in
[modularization](../../references/modularization.md). A refusal to
extract, with the failed checklist items stated, is a valid and complete
outcome of this skill.

## Purpose

Split existing code out of its current target into a new module/target
when — and only when — the concrete benefit of doing so clears the same
bar a reviewer would demand of any modularization decision.

## Trigger Conditions

- "Split [X] out into its own module"
- "Extract [Y] into [NewTargetName]"
- "Pull the [networking/analytics/etc.] code out of the app target"

## Non-Trigger Conditions

- No existing Tuist project — that's `ios-tuist-bootstrap`.
- The request is to create wholly new feature code with nothing existing
  to extract — that's `ios-tuist-feature`.
- The request is only a read-only opinion on whether something *should*
  be split, with no actual extraction wanted — that's
  `ios-tuist-architecture-review`.

## Preconditions

An existing Tuist project must be present and readable. The code or
region to extract must be identifiable — either named explicitly in the
request, or inferable from a clear, singular concern already isolated in
the source target (e.g. one file, one folder, one well-bounded type
family).

## Version Safety

Apply [version-safety](../../references/version-safety.md) in full. This
is **Existing Project Mode**
(see [source-of-truth](../../references/source-of-truth.md)): the
project-pinned version is authoritative. If the active version differs
from the pinned version, report the mismatch as a risk and generate
manifest syntax for the pinned version, not the active one.

## Workflow

1. **Identify the extraction candidate** — the code, files, or region
   the request names, and its current target.
2. **Apply the modularization checklist**
   ([modularization](../../references/modularization.md), "Applying this
   checklist" — extraction-gate mode). Answer every item concretely using
   the actual codebase: real usage sites, the real dependency graph, real
   resource ownership. Never answer an item hypothetically.
3. **Decision gate:**
   ```text
   Checklist bar met (concrete benefit on the decisive items —
   ownership boundary, reusability, and at least one of
   compile-isolation/test-boundary/resource-ownership)?
           |
          Yes -> proceed to extraction
           |
          No  -> refuse extraction; report which items failed and why in
                 the Output Contract's Risks/Follow-up section; make no
                 code changes
   ```
4. **If proceeding, choose linkage** per
   [modularization](../../references/modularization.md)'s
   linkage-is-a-graph-decision rule — inspect existing convention,
   transitive graph, resources, extensions, binaries before choosing;
   never default to a single linkage type across the project.
5. **Extract:**
   - Create the new target, naming it to match the repo's existing
     target-naming convention.
   - Move the identified code; update imports in the source target and
     any other consumers that referenced it.
   - Wire the source target (and other consumers) to depend on the new
     target.
   - Move the extracted code's existing tests with it. Do not leave
     orphaned tests behind in the old target, and do not invent new tests
     beyond what already existed for that code.
6. **Validate** — generate; build the new target, the original
   (now-slimmer) target, and any other now-dependent consumers; run the
   moved tests.

## Decision Rules

- The checklist is a gate, not a formality. Refusing to extract is a
  complete outcome — never split code just because it was asked for if
  the checklist doesn't concretely support it.
- Never widen the new target's dependencies beyond what the extracted
  code actually uses, per
  [dependencies](../../references/dependencies.md)'s narrowest-target
  spirit.
- Never change the extracted code's public behavior while moving it —
  this is a structural move, not a logic refactor.
- Never migrate the surrounding project's unrelated conventions (folder
  integration style, test framework, etc.) as a side effect of the
  extraction.

## Validation

Required before declaring success (only applies when the checklist gate
passed and extraction proceeded):

1. `tuist generate` — must succeed.
2. The new target builds.
3. The original (now-slimmer) target and any other now-dependent
   consumers build.
4. The extracted code's tests run and pass in their new location.

When extraction is refused, no build/test validation applies — the
Output Contract states "Changes Made: none — extraction refused" instead.

## Failure Handling

Evidence-Driven Debugging, same procedure as the v0.1 skills (Observed
Facts -> Hypotheses -> Contradiction Search -> Minimal Change). First
hypothesis to consider here specifically: a circular dependency
introduced between the new target and its former host (the extracted
code still depends on something left behind in the original target).

## Output Contract

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

Example (extraction proceeds):

```text
Tuist: 4.x.y (project-pinned, matches active)
Xcode: 2x.x
Swift: 6.x

Changed:
- created NetworkingKit target (extracted from App/Sources/Networking)
- App now depends on NetworkingKit instead of owning the code directly
- moved NetworkingKitTests with the extracted code

Validation:
- tuist generate: success
- NetworkingKit build: success
- App build: success
- NetworkingKitTests: success

Risks / Follow-up:
- none
```

Example (extraction refused):

```text
Tuist: 4.x.y (project-pinned, matches active)

Changed:
- none — extraction refused

Risks / Follow-up:
- Checklist not met for "SettingsRow": no reuse beyond its single call
  site in SettingsScreen, no distinct ownership boundary, no test
  isolation benefit. Recommend keeping this code in its current target.
```
