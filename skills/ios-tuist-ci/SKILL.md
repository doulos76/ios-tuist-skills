---
name: ios-tuist-ci
description: >
  Audits an existing CI workflow for a Tuist-based iOS project —
  version-pin consistency, caching, unnecessary full-graph rebuilds,
  parallelization — and applies improvements the user approves. Does
  not author a net-new CI pipeline for a project with none.
---

# Core Rule

Propose changes to a CI workflow file before applying them. CI
configuration is a shared, high-blast-radius file — never edit it
without the user seeing the specific diff first, regardless of
auto-mode.

## Purpose

Audit an existing CI workflow that builds/tests a Tuist project, find
concrete, evidence-backed improvement opportunities, and apply the ones
the user approves — without reducing validation coverage.

## Trigger Conditions

- "Check our CI workflow"
- "Is our build pipeline efficient?"
- "Improve the GitHub Actions setup for this Tuist project"

## Non-Trigger Conditions

- The project has no existing CI workflow at all and the user wants one
  authored from scratch — out of scope for this skill. State this
  explicitly rather than silently building a new pipeline.
- The request is about fixture/test *content* rather than the CI
  mechanics that run them.

## Preconditions

An existing CI workflow file is present (e.g. `.github/workflows/*.yml`)
and references Tuist in some form (install, generate, build, or test
step).

## Version Safety

Apply [version-safety](../../references/version-safety.md) in full. The
project-pinned Tuist version is the source of truth the CI workflow's
installed version must match. A workflow pinning a different version
than the project is a finding to report, not something this skill
silently reconciles by picking one side.

## Workflow

1. **Inventory the workflow(s)** — jobs, triggers, runner OS, the
   Tuist install/version-pin step, resolve/generate/build/test steps,
   caching configuration (or its absence).
2. **Cross-check version consistency** — the workflow-installed Tuist
   version vs. the project-pinned version
   ([version-safety](../../references/version-safety.md)). Report any
   mismatch as a risk.
3. **Identify improvement candidates**, each backed by concrete evidence
   from the workflow file (never generic CI best-practice advice
   untethered to what's actually there):
   - Missing or ineffective dependency/build caching.
   - Full-repository rebuild/test where the job structure suggests only
     a subset is needed.
   - Missing parallelization opportunity across independent jobs or
     targets.
   - Redundant steps (e.g. resolving dependencies twice in one job).
4. **Propose changes** — present the specific diff to the user before
   applying. This is required, not optional, regardless of auto-mode,
   because a CI workflow is a shared, high-blast-radius file.
5. **Apply approved changes** to the workflow file(s).
6. **Validate** — lint the workflow YAML (use `actionlint` if available;
   otherwise validate YAML syntax at minimum) and, where a fixture is
   available, confirm the fixture's workflow still
   resolves/generates/builds/tests successfully with the change applied.

## Decision Rules

- Never silently change a Tuist version pin to "fix" a mismatch — report
  it. Changing a version pin is the user's decision.
- Never introduce a new CI provider or platform (e.g. moving GitHub
  Actions to CircleCI) — improve within the existing provider only,
  unless explicitly asked otherwise.
- Never remove a validation step (build, test, lint) to make CI faster.
  Speed improvements come from caching, scoping, or parallelization —
  never from validating less.

## Validation

Required before declaring success:

1. The workflow YAML is syntactically valid.
2. If a fixture exercises the change, its
   resolve/generate/build/test steps succeed under the modified
   workflow.

## Failure Handling

Evidence-Driven Debugging, same procedure as the other skills. First
hypothesis to consider here specifically: a caching key that doesn't
account for the Tuist version or lockfile, causing stale cache hits that
mask the real state of resolved dependencies.

## Output Contract

```text
Version Context
Workflow(s) Inspected
Findings (one per issue: Evidence, Risk/Cost, Recommendation)
Changes Made (only what the user approved)
Validation Performed
Unverified Items
Risks / Follow-up
```

Example:

```text
Tuist: 4.x.y (project-pinned, matches workflow's installed version)

Workflow(s) Inspected:
- .github/workflows/ci.yml (1 job: build-and-test)

Findings:
- Evidence: no `actions/cache` step wraps `tuist install`; every run
  re-resolves all dependencies from scratch.
  Risk/Cost: adds ~90s per run with no correctness benefit once
  dependencies are unchanged.
  Recommendation: cache Tuist's dependency directory keyed on the
  lockfile hash.

Changes Made:
- added actions/cache step keyed on Package.resolved hash, wrapping
  `tuist install` (user-approved)

Validation:
- YAML syntax: valid
- ci-gaps fixture workflow (same change applied): resolve/generate/build
  succeed

Risks / Follow-up:
- none
```
