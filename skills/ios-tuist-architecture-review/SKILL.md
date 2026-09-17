---
name: ios-tuist-architecture-review
description: >
  Diagnoses an existing Tuist project's target graph, dependency
  direction, and linkage choices against modularization principles and
  reports findings with concrete evidence — never edits code or
  manifests.
---

# Core Rule

This skill is read-only. It must never edit `Project.swift`,
`Tuist.swift`, or any source file under any circumstance. Its only output
is a findings report.

## Purpose

Diagnose an existing Tuist project's target graph and report concrete,
evidence-backed findings against
[modularization](../../references/modularization.md)'s checklist and
graph rules — without changing any code.

## Trigger Conditions

- "Review this project's architecture"
- "Is our module structure okay?"
- "Check the dependency graph for problems"

## Non-Trigger Conditions

- The request asks for an actual change to be made — delegate the
  specific change to `ios-tuist-module` (extraction),
  `ios-tuist-feature`, or `ios-tuist-dependency`. This skill only
  diagnoses.
- No existing Tuist project — there is nothing to review.

## Preconditions

An existing Tuist project must be present and readable with an
inspectable target graph (`tuist graph`, or manifest inspection if that
command is unavailable in the environment).

## Version Safety

Apply the detection portion of
[version-safety](../../references/version-safety.md) so manifests are
read and interpreted correctly for the version they were written
against. This skill never writes manifests, so there is no
pinned-vs-active mismatch to reconcile — if one exists, report it as a
finding, nothing more.

## Workflow

1. **Map the graph** — enumerate every target, its declared dependencies,
   and its linkage type. Use `tuist graph` output when available;
   otherwise read manifests directly.
2. **Score each target** against
   [modularization](../../references/modularization.md)'s pre-module
   checklist, applied in diagnostic mode: is this target's continued
   existence, boundary, and linkage still justified by the same bar a new
   extraction would need to clear?
3. **Detect graph-level issues**:
   - Cyclic dependencies, existing or latent.
   - Duplicate-symbol risk from static linkage fan-out (multiple
     statically-linked targets sharing a dependency).
   - Targets with no clear owner or reuse.
   - Dependency-direction violations (e.g. a shared/core target
     depending back on a feature target).
4. **Compose the report** — one finding per issue. Each finding states:
   the target(s) involved, which checklist item or graph rule it fails,
   concrete evidence from the actual graph/code (never speculation), and
   a recommended next step (e.g. "candidate for `ios-tuist-module`
   merge-back," "consider switching linkage — see modularization.md").

## Decision Rules

- Never edit `Project.swift`, `Tuist.swift`, or any source file — this
  skill has no Validation section in the v0.1 build/test sense because it
  makes no changes.
- Every finding must cite concrete evidence from the actual graph or code
  in this repository — never state a generic architecture opinion
  untethered to what was actually inspected.
- Never recommend a single "correct" architecture style. Findings are
  framed strictly as checklist or graph-rule violations, not style
  preferences.
- If the project has too few targets for graph-level findings to apply
  (e.g. a single-target minimal app), say so plainly instead of
  inventing findings to fill the report.

## Validation

No build/generate/test validation applies, since this skill makes no
code changes. Instead: every factual claim in the report (e.g. "Target X
has 3 dependents") must be verified against the actual `tuist graph`
output or manifest content before being stated — never assumed or
inferred from naming alone.

## Failure Handling

If `tuist graph` or manifest parsing fails, apply Evidence-Driven
Debugging to that failure specifically (record the exact command and
error) before falling back to manual manifest reading. The review must
not proceed on a guessed graph shape.

## Output Contract

```text
Version Context
Graph Summary (targets, dependency count, linkage types present)
Findings (one per issue: Target(s), Rule Violated, Evidence, Recommendation)
Not Flagged (graph areas checked and found sound)
Unverified Items
```

Example:

```text
Tuist: 4.x.y (project-pinned)

Graph Summary:
- 4 targets: App, CoreKit, FeatureA, FeatureB
- CoreKit: static framework, 0 dependencies, 2 dependents
- FeatureA: static framework, depends on CoreKit
- FeatureB: static framework, depends on CoreKit and FeatureA

Findings:
- Target: CoreKit
  Rule Violated: dependency-direction (modularization.md checklist —
  dependency direction)
  Evidence: CoreKit/Sources/Bridge.swift imports FeatureA's public type
  FeatureAConfig, creating a reverse dependency not declared in
  Project.swift but present in source.
  Recommendation: move FeatureAConfig out of FeatureA into CoreKit or a
  new shared target, or remove the import.

Not Flagged:
- Static linkage across CoreKit/FeatureA/FeatureB: no duplicate-symbol
  evidence found (each links a distinct dependency set).

Unverified Items:
- Resource ownership per target not inspected (no resources present in
  this project).
```
