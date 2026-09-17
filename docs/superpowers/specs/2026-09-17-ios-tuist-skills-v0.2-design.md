# ios-tuist-skills v0.2 — Design Spec

- **Status:** Approved for planning
- **Date:** 2026-09-17
- **Source:** Defined in-conversation (no external PRD); scope selected from
  the v0.1 spec's stated later-milestone candidates
  (`docs/superpowers/specs/2026-09-17-ios-tuist-skills-v0.1-design.md` §1).
- **Scope:** Three new skills — `ios-tuist-module`,
  `ios-tuist-architecture-review`, `ios-tuist-ci` — plus the shared
  reference and fixture/CI work needed to prove them.
- **Planning/review owner:** Claude

## 1. Purpose

Extend the `ios-tuist-skills` plugin with three additional skills that
cover the next slice of iOS/Tuist engineering judgment not addressed by
v0.1's create/extend/dependency trio:

- Extracting existing code into a new module/target (`ios-tuist-module`).
- Diagnosing an existing project's architecture and dependency graph
  without changing it (`ios-tuist-architecture-review`).
- Auditing and improving an existing CI workflow for a Tuist project
  (`ios-tuist-ci`).

Explicitly out of scope for v0.2 (deferred to a later milestone or never):
`ios-tuist-migrate` (version/syntax migration) — not selected for this
pass. Net-new CI workflow authoring for a project with no CI at all is
also out of scope; `ios-tuist-ci` audits and improves what exists.

## 2. Repository layout additions

```text
ios-tuist-skills/
├── skills/
│   ├── ios-tuist-module/
│   │   ├── SKILL.md
│   │   └── references/            # skill-specific only
│   ├── ios-tuist-architecture-review/
│   │   ├── SKILL.md
│   │   └── references/
│   └── ios-tuist-ci/
│       ├── SKILL.md
│       └── references/
├── references/
│   └── modularization.md          # extended, not replaced
├── tests/fixtures/
│   ├── extract-candidate/         # ios-tuist-module
│   ├── architecture-smells/       # ios-tuist-architecture-review
│   └── ci-gaps/                   # ios-tuist-ci
```

No new top-level directories. `templates/` and `examples/` are unchanged
— none of the three v0.2 skills instantiate a new project from scratch,
so they don't need bootstrap-style scaffolds.

## 3. Shared reference — `references/modularization.md` extension

The existing pre-module checklist and linkage-is-a-graph-decision rule
(written for v0.1's "should I create a module" question inside
`ios-tuist-feature`) are generalized into a section usable by both a
change-making skill (`ios-tuist-module`, deciding whether to extract) and
a read-only skill (`ios-tuist-architecture-review`, scoring what already
exists). Concretely, add one new section:

### 3.1 "Applying this checklist" (new section)

- As an **extraction gate** (`ios-tuist-module`): every checklist item
  must have a concrete, stated answer before extraction proceeds. Any
  item answered "no benefit" / "hypothetical only" is a reason to refuse
  the extraction and report why, not a box to skip.
- As a **diagnostic score** (`ios-tuist-architecture-review`): apply the
  same checklist per existing target to produce a finding (e.g. "Target X
  has no distinct ownership boundary and no reuse — candidate to merge
  back" or "Target Y's static linkage duplicates symbols already present
  in Target Z — investigate"). Findings are reported, never acted on, by
  this skill.

No other content in `modularization.md` changes. No new shared reference
file is created — both new skills that need modularization judgment link
to this one file, same as `ios-tuist-feature` already does.

## 4. `ios-tuist-module`

**Purpose:** Extract existing code from a target into a new
module/target, applying the modularization justification bar before
acting — refusing the extraction (and saying why) when the bar isn't
met.

**Trigger conditions:** "Split X out into its own module", "Extract Y
into SharedKit", "Pull the networking code out of the app target."

**Non-trigger conditions:** No existing Tuist project (→ `bootstrap`);
request is to create wholly new feature code with no existing code to
extract (→ `ios-tuist-feature`); request is only a read-only opinion on
whether something *should* be split (→
`ios-tuist-architecture-review`).

**Preconditions:** An existing Tuist project is present and readable;
the code/region to extract is identifiable (explicit from the request or
inferable from a clear, singular concern in the source target).

**Version safety:** Full
[version-safety](../../references/version-safety.md) procedure,
Existing Project Mode — project-pinned version is authoritative, same
rule as `ios-tuist-feature`.

**Workflow:**

1. **Identify the extraction candidate** — the code, files, or region the
   request names, and its current target.
2. **Apply the modularization checklist**
   ([modularization](../../references/modularization.md) §"Applying this
   checklist" — extraction-gate mode). Answer every item concretely
   using the actual codebase (real usage, real graph, real resource
   ownership) — never hypothetically.
3. **Decision gate:**
   ```text
   Checklist bar met (concrete benefit on ≥ the decisive items)?
           |
          Yes -> proceed to extraction
           |
          No  -> refuse extraction; report which items failed and why,
                 in the Output Contract's Risks/Follow-up section;
                 make no code changes
   ```
4. **If proceeding: choose linkage** per
   [modularization](../../references/modularization.md)'s
   linkage-is-a-graph-decision rule — inspect existing convention,
   transitive graph, resources, extensions, binaries before choosing;
   never default.
5. **Extract:**
   - Create the new target (naming convention matching the repo's
     existing pattern).
   - Move the identified code; update imports in the source target and
     any other consumers.
   - Wire the source target (and other consumers) to depend on the new
     target.
   - Move/relocate the code's existing tests with it; do not leave
     orphaned tests in the old target and do not invent new tests beyond
     what already existed.
6. **Validate** — generate; build the new target, the original target,
   and any other now-dependent consumers; run the moved tests.

**Decision rules:**

- The checklist is a gate, not a formality — a refusal to extract is a
  valid, complete outcome of this skill.
- Never widen the new target's dependencies beyond what the extracted
  code actually uses (same narrowest-target spirit as
  [dependencies](../../references/dependencies.md)).
- Never change the extracted code's public behavior while moving it —
  this is a structural move, not a refactor of logic.
- Never migrate the surrounding project's unrelated conventions as a
  side effect (same rule as `ios-tuist-feature`).

**Validation (required before declaring success):** `tuist generate`
succeeds; the new target builds; the original (now-slimmer) target and
any other consumers build; the extracted code's tests run and pass in
their new location.

**Failure handling:** Evidence-Driven Debugging, same procedure as
v0.1's skills. First hypothesis to consider here specifically: a
circular dependency introduced between the new target and its former
host (extraction moved code that still depends on something left
behind).

**Output contract:** Same PRD-style structure as v0.1 skills (Version
Context, Changes Made, Files Changed, Dependency Changes, Validation
Performed, Build Result, Test Result, Unverified Items, Risks/
Follow-up). When extraction is refused, "Changes Made" states "none —
extraction refused" and "Risks/Follow-up" carries the checklist findings.

## 5. `ios-tuist-architecture-review`

**Purpose:** Diagnose an existing Tuist project's target graph,
dependency direction, and linkage choices against established
modularization principles, and report findings — without changing any
code.

**Trigger conditions:** "Review this project's architecture", "Is our
module structure okay?", "Check the dependency graph for problems."

**Non-trigger conditions:** Request asks for an actual change to be made
(→ delegate the specific change to `ios-tuist-module`,
`ios-tuist-feature`, or `ios-tuist-dependency` — this skill only
diagnoses); no existing Tuist project (nothing to review).

**Preconditions:** An existing Tuist project is present and readable
with an inspectable target graph (`tuist graph` or manifest inspection).

**Version safety:** Full
[version-safety](../../references/version-safety.md) procedure applies
to reading/interpreting manifests correctly, but this skill never writes
manifests, so there is no pinned-vs-active mismatch to reconcile beyond
reporting it if found.

**Workflow:**

1. **Map the graph** — enumerate targets, their declared dependencies,
   and linkage types (`tuist graph` output or manifest inspection if the
   command is unavailable).
2. **Score each target** against
   [modularization](../../references/modularization.md)'s pre-module
   checklist, applied in diagnostic mode (§3.1 above) — is this target's
   existence, boundary, and linkage still justified by the same bar a
   new extraction would need to clear?
3. **Detect graph-level issues**: cyclic dependencies (existing or
   latent), duplicate-symbol risk from static linkage fan-out, targets
   with no clear owner or reuse, dependency-direction violations
   (e.g. a shared/core target depending back on a feature target).
4. **Compose the report** — one finding per issue, each with: the
   target(s) involved, which checklist item(s) or graph rule it fails,
   concrete evidence (not speculation), and a recommended next step
   (e.g. "candidate for `ios-tuist-module` merge-back", "consider
   switching linkage — see modularization.md").

**Decision rules:**

- Read-only: this skill must not edit `Project.swift`, `Tuist.swift`, or
  any source file under any circumstance.
- Every finding must cite concrete evidence from the actual graph/code,
  never a generic architecture opinion untied to this codebase.
- Do not recommend a single "correct" architecture style — findings are
  framed as graph-rule or checklist violations, not style preferences
  (same non-goal as v0.1: never force a single architecture).
- If the project has too few targets for graph-level findings to apply
  (e.g. a single-target minimal app), say so plainly rather than
  inventing findings.

**Validation:** No build/generate/test validation applies in the
v0.1 sense, since no code changes — but every factual claim in the
report (e.g. "Target X has 3 dependents") must be verified against the
actual `tuist graph` output or manifest content before being stated, not
assumed.

**Failure handling:** If `tuist graph` or manifest parsing fails,
Evidence-Driven Debugging applies to *that* failure (record the exact
command/error) before falling back to manual manifest reading — the
review must not proceed on a guessed graph shape.

**Output contract:** A findings report, not the v0.1 Output Contract
(there is no build/test result to report). Structure:

```text
Version Context
Graph Summary (targets, dependency count, linkage types present)
Findings (one per issue: Target(s), Rule Violated, Evidence, Recommendation)
Not Flagged (explicitly note graph areas checked and found sound)
Unverified Items
```

## 6. `ios-tuist-ci`

**Purpose:** Audit an existing CI workflow for a Tuist-based project —
version-pin consistency, caching, unnecessary full-graph rebuilds,
parallelization — and apply improvements the user approves. Does not
author a net-new CI pipeline for a project with none.

**Trigger conditions:** "Check our CI workflow", "Is our build pipeline
efficient?", "Improve the GitHub Actions setup for this Tuist project."

**Non-trigger conditions:** Project has no existing CI workflow at all
and the user wants one authored from scratch (out of scope for this
skill in v0.2 — state this explicitly rather than silently building a
new pipeline); request is about fixture/test content rather than the CI
mechanics running them.

**Preconditions:** An existing CI workflow file is present (e.g.
`.github/workflows/*.yml`) and references Tuist in some form (install,
generate, build, or test step).

**Version safety:** Full
[version-safety](../../references/version-safety.md) procedure — the
project-pinned Tuist version is the source of truth the CI workflow's
installed version must match; a workflow pinning a different version
than the project is a finding, not something this skill silently
reconciles by picking one.

**Workflow:**

1. **Inventory the workflow(s)** — jobs, triggers, runner OS, Tuist
   install/version-pin step, resolve/generate/build/test steps, caching
   configuration (or absence).
2. **Cross-check version consistency** — workflow-installed Tuist
   version vs. project-pinned version
   ([version-safety](../../references/version-safety.md)); report any
   mismatch as a risk.
3. **Identify improvement candidates**, each with concrete evidence from
   the workflow file (not generic CI best-practice advice):
   - Missing or ineffective dependency/build caching.
   - Full-repository rebuild/test where the change scope (per recent
     history or job structure) suggests only a subset is needed.
   - Missing parallelization opportunity across independent
     jobs/targets.
   - Redundant steps (e.g. resolving dependencies twice).
4. **Propose changes** — present the specific diff to the user before
   applying (this skill edits CI config, a shared/high-blast-radius file
   per the top-level "Executing actions with care" guidance, so proposal
   before edit is required, not optional, regardless of auto-mode).
5. **Apply approved changes** to the workflow file(s).
6. **Validate** — lint the workflow YAML (use `actionlint` if available
   in the environment; otherwise validate YAML syntax at minimum) and,
   where a fixture is available, confirm the fixture's workflow still
   resolves/generates/builds/tests successfully with the change applied.

**Decision rules:**

- Never silently change the Tuist version pin to "fix" a mismatch —
  report it; changing a version pin is a decision for the user, same
  non-goal as v0.1 (§10: never silently upgrade Tuist).
- Never introduce a new CI provider/platform (e.g. moving GitHub Actions
  to CircleCI) — improve within the existing provider only, unless
  explicitly asked otherwise.
- Never remove a validation step (build, test, lint) to make CI faster;
  speed improvements must come from caching, scoping, or
  parallelization, not from validating less.

**Validation (required before declaring success):** Workflow YAML is
syntactically valid; if a fixture exercises the change, its
resolve/generate/build/test steps succeed under the modified workflow.

**Failure handling:** Same Evidence-Driven Debugging procedure. First
hypothesis to consider here specifically: a caching key that doesn't
account for the Tuist version or lockfile, causing stale cache hits.

**Output contract:**

```text
Version Context
Workflow(s) Inspected
Findings (one per issue: Evidence, Risk/Cost, Recommendation)
Changes Made (only what the user approved)
Validation Performed
Unverified Items
Risks / Follow-up
```

## 7. Fixtures and CI validation

Each new skill gets exactly one real, independently buildable fixture
(same bar as v0.1 — no structure-only stand-ins), with an
`EXPECTATIONS.md`.

### 7.1 `tests/fixtures/extract-candidate/`

A real, buildable Tuist project with a single app target containing one
clearly-bounded, reusable, well-tested chunk of code (e.g. a networking
layer) that meets the modularization checklist bar, plus at least one
other chunk that does not (e.g. a one-off view with no reuse or clear
ownership) — so the fixture can prove both the "proceed" and "refuse"
paths of `ios-tuist-module`.

### 7.2 `tests/fixtures/architecture-smells/`

A real, buildable multi-target Tuist project deliberately containing at
least one detectable issue from §5's workflow (e.g. a shared/core target
depending back on a feature target, or a target with static linkage
duplicating a dependency already linked elsewhere) — so
`ios-tuist-architecture-review` has concrete, checkable findings to
surface, and CI can assert the fixture itself still builds despite the
smell (the smell is a design issue, not a build break).

### 7.3 `tests/fixtures/ci-gaps/`

A real, buildable Tuist project with its own minimal CI workflow file
that deliberately omits caching and re-resolves dependencies redundantly
— so `ios-tuist-ci` has concrete gaps to find and fix, and CI can assert
both the original and improved workflow versions still succeed.

### 7.4 CI (`.github/workflows/validate-fixtures.yml`)

Extend the existing fixture-validation workflow to include the three
new fixtures, following the same pattern as v0.1 (install pinned Tuist
version, resolve, generate, build, test per fixture). No new workflow
file — one job matrix, extended. `ci-gaps`' own embedded workflow file
is fixture content, not the repo's validation CI, and is not itself
executed by the outer validate-fixtures job (parsing/lint only, per
§6's validation step).

## 8. CHANGELOG.md and plugin version

- `.claude-plugin/plugin.json` `version` bumps to `0.2.0`.
- `CHANGELOG.md` gets a `[0.2.0]` entry listing the three new skills, the
  `modularization.md` extension, and the three new fixtures, following
  the same Keep-a-Changelog style as `[0.1.0]`.

## 9. Explicit non-goals (v0.2)

- `ios-tuist-migrate` (Tuist version/syntax migration) is not part of
  this pass.
- `ios-tuist-ci` does not author a net-new CI pipeline for a project
  with none, and does not change CI provider.
- `ios-tuist-architecture-review` never edits code — a project needing
  changes gets a report pointing at the skill that would make them.
- No new shared reference file is introduced;
  `references/modularization.md` is extended in place, not duplicated.
- Same restated non-goals as v0.1 §10 continue to apply repo-wide (no
  hard-coded version compatibility table, no silent Tuist upgrade, no
  forced architecture/linkage/modularization strategy, no side-effect
  modernization).

## 10. Acceptance criteria for this v0.2 implementation pass

- All three skills (`ios-tuist-module`, `ios-tuist-architecture-review`,
  `ios-tuist-ci`) exist with complete `SKILL.md` files following the
  same section structure as v0.1's skills (Purpose, Trigger Conditions,
  Non-Trigger Conditions, Preconditions, Version Safety, Workflow,
  Decision Rules, Validation, Failure Handling, Output Contract).
- `references/modularization.md` contains the new "Applying this
  checklist" section; no other shared reference file is added or
  duplicated.
- The three new fixtures exist as real, independently buildable Tuist
  projects, each with an `EXPECTATIONS.md`, each deliberately containing
  the condition its skill needs to detect.
- `.github/workflows/validate-fixtures.yml` is extended to build/
  generate/test all three new fixtures alongside the existing four.
- `.claude-plugin/plugin.json` version is `0.2.0`.
- `README.md` lists the three new skills alongside the existing three.
- `CHANGELOG.md` has a `[0.2.0]` entry.
