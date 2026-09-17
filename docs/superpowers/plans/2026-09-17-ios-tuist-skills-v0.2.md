# ios-tuist-skills v0.2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the v0.2 milestone of `ios-tuist-skills`: three new skills
(`ios-tuist-module`, `ios-tuist-architecture-review`, `ios-tuist-ci`), an
extension to the shared `modularization.md` reference both judgment-based
skills rely on, and three new real, buildable fixtures validated by CI.

**Architecture:** Same flat plugin repo shape as v0.1 — no new top-level
directories. Three self-contained `SKILL.md` files land in `skills/`; the
existing `references/modularization.md` gains one new section (not a new
file) so `ios-tuist-module` (acting) and `ios-tuist-architecture-review`
(diagnosing) share one judgment source, exactly like `ios-tuist-feature`
already shares `version-safety.md`/`source-of-truth.md` with the other
v0.1 skills. Three new fixtures extend the existing
`.github/workflows/validate-fixtures.yml` matrix job — no new workflow
file.

**Tech Stack:** Tuist 4.206.0 (matches this repo's other fixtures and the
locally installed version confirmed via `tuist version` at plan-authoring
time), Xcode 27 / Swift 6.4, GitHub Actions (macOS runner, existing
`jdx/mise-action` version-pin pattern), Claude Code plugin format.

**Spec:** `docs/superpowers/specs/2026-09-17-ios-tuist-skills-v0.2-design.md`

## Global Constraints

- Never hard-code a single Tuist version anywhere in `skills/` or
  `references/` content (spec §9; carried over from v0.1 spec §10).
- Every new skill links to shared references by relative path — never
  restates their procedures inline (spec §3–§6). All cross-file links use
  relative markdown links (e.g.
  `[modularization](../../references/modularization.md)`), never bare
  filenames or absolute paths.
- `references/modularization.md` is **extended in place** — no new shared
  reference file is created (spec §3, §9).
- Every `SKILL.md` follows the same section structure as the v0.1 skills:
  Purpose, Trigger Conditions, Non-Trigger Conditions, Preconditions,
  Version Safety, Workflow, Decision Rules, Validation, Failure Handling,
  Output Contract (spec §4–§6).
- `ios-tuist-module`'s modularization checklist is a gate: a refusal to
  extract (checklist not met) is a valid, complete outcome — never force
  an extraction to "finish the task" (spec §4).
- `ios-tuist-architecture-review` never edits code or manifests under any
  circumstance — its Output Contract is a findings report, not the v0.1
  build/test contract (spec §5).
- `ios-tuist-ci` never authors a net-new CI pipeline for a project with no
  existing CI, never changes CI provider, and never removes a validation
  step (build/test/lint) to make CI faster (spec §6).
- `ios-tuist-ci` never silently changes a Tuist version pin to resolve a
  mismatch — report it, same non-goal as v0.1's "never silently upgrade
  Tuist" (spec §6, carried from v0.1 spec §10).
- Fixtures under `tests/fixtures/` must be real, independently buildable
  Tuist projects — not structure-only stand-ins (spec §7).
- New fixtures join the existing `validate-fixtures.yml` matrix (one job,
  extended) — do not create a second CI workflow file (spec §7.4).
- MIT license header style is not required per-file; `LICENSE` at repo
  root already covers the whole repo.

---

### Task 1: Extend `references/modularization.md` with the "Applying this checklist" section

**Files:**
- Modify: `references/modularization.md`

**Interfaces:**
- Consumes: nothing (the file's existing content, read in full before
  editing).
- Produces: the extraction-gate/diagnostic-mode section that Tasks 2 and
  3's `SKILL.md` files link to as
  `[modularization](../../references/modularization.md)`.

- [ ] **Step 1: Read the current file**

Run: `cat references/modularization.md`

Confirm it still ends with the "Linkage is a graph decision, not a
default" section (the last section as of v0.1) before appending — if the
file has changed since this plan was written, adjust the insertion point
accordingly rather than assuming line numbers.

- [ ] **Step 2: Append the new section**

Add this section to the end of `references/modularization.md`:

```markdown

## Applying this checklist

This checklist is written once and used two ways, by two different
skills. Neither skill restates it — both link here.

### As an extraction gate (`ios-tuist-module`)

Every item in the pre-module checklist above must have a concrete,
stated answer before an extraction proceeds. An item answered "no
benefit," "hypothetical only," or "not yet, but maybe later" is a reason
to refuse the extraction and report why — it is not a box to check past.
A refusal is a complete, valid outcome of `ios-tuist-module`, not a
failure to work around.

### As a diagnostic score (`ios-tuist-architecture-review`)

Apply the same checklist per existing target to produce a finding, not a
code change. Example findings:

- "Target `X` has no distinct ownership boundary and no reuse beyond its
  single consumer — candidate to merge back into that consumer."
- "Target `Y` uses static linkage and shares a dependency already
  statically linked into `Z` — duplicate-symbol risk; investigate
  linkage."

Findings from this checklist are always reported, never acted on, by
`ios-tuist-architecture-review` itself. Acting on a finding is a separate,
explicit task for `ios-tuist-module`, `ios-tuist-feature`, or
`ios-tuist-dependency`.
```

- [ ] **Step 3: Verify the new section is present and the file still has no hard-coded Tuist version**

Run:

```bash
grep -n "## Applying this checklist" references/modularization.md
grep -nE 'Tuist [0-9]+\.[0-9]' references/modularization.md
```

Expected: the first command prints one match (the new heading); the
second command prints nothing.

- [ ] **Step 4: Commit**

```bash
git add references/modularization.md
git commit -m "docs: extend modularization reference for extraction and review use"
```

---

### Task 2: `ios-tuist-module` skill

**Files:**
- Create: `skills/ios-tuist-module/SKILL.md`
- Create: `skills/ios-tuist-module/references/.gitkeep`

**Interfaces:**
- Consumes: `references/version-safety.md`, `references/source-of-truth.md`,
  `references/modularization.md` (extension-gate mode, from Task 1),
  `references/dependencies.md`.
- Produces: the extraction workflow referenced by
  `tests/fixtures/extract-candidate/EXPECTATIONS.md` (Task 5).

- [ ] **Step 1: Create the skill directory**

```bash
mkdir -p skills/ios-tuist-module/references
touch skills/ios-tuist-module/references/.gitkeep
```

- [ ] **Step 2: Write `skills/ios-tuist-module/SKILL.md`**

```markdown
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

- [ ] **Step 3: Verify frontmatter and required reference links**

Run:

```bash
python3 -c "
text = open('skills/ios-tuist-module/SKILL.md').read()
assert text.startswith('---\nname: ios-tuist-module\n'), 'frontmatter missing or malformed'
assert '../../references/version-safety.md' in text
assert '../../references/source-of-truth.md' in text
assert '../../references/modularization.md' in text
assert '../../references/dependencies.md' in text
print('OK')
"
```

Expected: `OK`.

- [ ] **Step 4: Commit**

```bash
git add skills/ios-tuist-module
git commit -m "docs: add ios-tuist-module skill"
```

---

### Task 3: `ios-tuist-architecture-review` skill

**Files:**
- Create: `skills/ios-tuist-architecture-review/SKILL.md`
- Create: `skills/ios-tuist-architecture-review/references/.gitkeep`

**Interfaces:**
- Consumes: `references/version-safety.md`,
  `references/modularization.md` (diagnostic mode, from Task 1).
- Produces: the diagnostic workflow referenced by
  `tests/fixtures/architecture-smells/EXPECTATIONS.md` (Task 6).

- [ ] **Step 1: Create the skill directory**

```bash
mkdir -p skills/ios-tuist-architecture-review/references
touch skills/ios-tuist-architecture-review/references/.gitkeep
```

- [ ] **Step 2: Write `skills/ios-tuist-architecture-review/SKILL.md`**

```markdown
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

- [ ] **Step 3: Verify frontmatter and required reference links, and confirm no build-validation language leaked in**

Run:

```bash
python3 -c "
text = open('skills/ios-tuist-architecture-review/SKILL.md').read()
assert text.startswith('---\nname: ios-tuist-architecture-review\n'), 'frontmatter missing or malformed'
assert '../../references/version-safety.md' in text
assert '../../references/modularization.md' in text
print('OK')
"
grep -n "tuist generate" skills/ios-tuist-architecture-review/SKILL.md
```

Expected: `OK` printed; the `grep` for `tuist generate` prints nothing
(this skill never generates/builds — its absence confirms the read-only
contract wasn't accidentally copied from the v0.1 skills).

- [ ] **Step 4: Commit**

```bash
git add skills/ios-tuist-architecture-review
git commit -m "docs: add ios-tuist-architecture-review skill"
```

---

### Task 4: `ios-tuist-ci` skill

**Files:**
- Create: `skills/ios-tuist-ci/SKILL.md`
- Create: `skills/ios-tuist-ci/references/.gitkeep`

**Interfaces:**
- Consumes: `references/version-safety.md`.
- Produces: the CI-audit workflow referenced by
  `tests/fixtures/ci-gaps/EXPECTATIONS.md` (Task 7).

- [ ] **Step 1: Create the skill directory**

```bash
mkdir -p skills/ios-tuist-ci/references
touch skills/ios-tuist-ci/references/.gitkeep
```

- [ ] **Step 2: Write `skills/ios-tuist-ci/SKILL.md`**

```markdown
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

- [ ] **Step 3: Verify frontmatter and required reference link**

Run:

```bash
python3 -c "
text = open('skills/ios-tuist-ci/SKILL.md').read()
assert text.startswith('---\nname: ios-tuist-ci\n'), 'frontmatter missing or malformed'
assert '../../references/version-safety.md' in text
print('OK')
"
```

Expected: `OK`.

- [ ] **Step 4: Commit**

```bash
git add skills/ios-tuist-ci
git commit -m "docs: add ios-tuist-ci skill"
```

---

### Task 5: Fixture — `tests/fixtures/extract-candidate/`

**Files:**
- Create: `tests/fixtures/extract-candidate/Tuist.swift`
- Create: `tests/fixtures/extract-candidate/Project.swift`
- Create: `tests/fixtures/extract-candidate/App/Sources/ExtractCandidateApp.swift`
- Create: `tests/fixtures/extract-candidate/App/Sources/Networking.swift`
- Create: `tests/fixtures/extract-candidate/App/Sources/SettingsRow.swift`
- Create: `tests/fixtures/extract-candidate/App/Tests/AppTests.swift`
- Create: `tests/fixtures/extract-candidate/EXPECTATIONS.md`

**Interfaces:**
- Consumes: nothing (leaf fixture).
- Produces: the fixture Task 2's `ios-tuist-module` is exercised against;
  the extraction-refusal and extraction-proceeds paths both need
  something to point at in this one project.

- [ ] **Step 1: Write `tests/fixtures/extract-candidate/Tuist.swift`**

```swift
import ProjectDescription

let tuist = Tuist()
```

- [ ] **Step 2: Write `tests/fixtures/extract-candidate/Project.swift`**

```swift
import ProjectDescription

let project = Project(
    name: "App",
    targets: [
        .target(
            name: "App",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.ios-tuist-skills.extract-candidate",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: ["UILaunchScreen": [:]]),
            buildableFolders: ["App/Sources"],
            dependencies: []
        ),
        .target(
            name: "AppTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.extract-candidate-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["App/Tests"],
            dependencies: [.target(name: "App")]
        ),
    ]
)
```

- [ ] **Step 3: Write the app entry point**

`tests/fixtures/extract-candidate/App/Sources/ExtractCandidateApp.swift`:

```swift
import SwiftUI

@main
struct ExtractCandidateApp: App {
    var body: some Scene {
        WindowGroup {
            SettingsRow(title: "Notifications", isOn: true)
        }
    }
}
```

- [ ] **Step 4: Write the extraction-worthy code**

`tests/fixtures/extract-candidate/App/Sources/Networking.swift` — a
well-bounded, independently testable networking layer with a small
public surface, no dependency on `SwiftUI`, and no reuse-blocking ties to
the app target. This is the piece that should clear the modularization
checklist:

```swift
import Foundation

public enum APIEndpoint {
    case profile(id: String)

    public var path: String {
        switch self {
        case .profile(let id):
            return "/profiles/\(id)"
        }
    }
}

public struct APIRequestBuilder {
    public let baseURL: URL

    public init(baseURL: URL) {
        self.baseURL = baseURL
    }

    public func request(for endpoint: APIEndpoint) -> URLRequest {
        URLRequest(url: baseURL.appendingPathComponent(endpoint.path))
    }
}
```

- [ ] **Step 5: Write the non-extraction-worthy code**

`tests/fixtures/extract-candidate/App/Sources/SettingsRow.swift` — a
single, one-off SwiftUI view used exactly once, with no reuse, no
distinct ownership boundary, and no test-isolation benefit. This is the
piece that should fail the modularization checklist:

```swift
import SwiftUI

struct SettingsRow: View {
    let title: String
    let isOn: Bool

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
        }
        .padding()
    }
}
```

- [ ] **Step 6: Write one real test covering the extraction-worthy code**

`tests/fixtures/extract-candidate/App/Tests/AppTests.swift`:

```swift
import Testing
@testable import App

@Test func requestBuilderComposesProfilePath() {
    let builder = APIRequestBuilder(baseURL: URL(string: "https://example.com")!)
    let request = builder.request(for: .profile(id: "42"))
    #expect(request.url?.path == "/profiles/42")
}
```

- [ ] **Step 7: Validate the fixture builds and tests as-is**

```bash
cd tests/fixtures/extract-candidate
tuist install
tuist generate --no-open
xcodebuild -workspace App.xcworkspace -scheme App -destination 'generic/platform=iOS Simulator' build
xcodebuild test -workspace App.xcworkspace -scheme App -destination 'platform=iOS Simulator,name=iPhone 16'
rm -rf App.xcworkspace *.xcodeproj .build
cd -
```

Expected: build and test both succeed before any skill touches it. If
`iPhone 16` isn't an available simulator name in the environment running
this step, list available devices with `xcrun simctl list devices
available` and substitute a real one — this is a one-off local
verification, not something baked into a committed file.

- [ ] **Step 8: Write `tests/fixtures/extract-candidate/EXPECTATIONS.md`**

```markdown
# Fixture: extract-candidate

**Exercises:** `ios-tuist-module`

## Starting state

A real, buildable single-target Tuist project (`App`) containing two
distinct pieces of code:

- `Networking.swift` — a small, dependency-free, independently testable
  networking layer with a clear public surface. This should clear the
  modularization checklist.
- `SettingsRow.swift` — a single, one-off SwiftUI view used exactly once
  in the app's entry point, with no reuse and no distinct ownership
  boundary. This should fail the checklist.

## Prompts to exercise this fixture

> Extract the networking code into its own module called NetworkingKit.

and, separately (reset the fixture between the two):

> Extract SettingsRow into its own module.

## Expected behavior

**For the networking extraction:**
- The checklist in `references/modularization.md` is applied concretely
  (not hypothetically) before any file is touched.
- A new `NetworkingKit` target is created; `App` depends on it instead of
  owning the code.
- The moved test (`requestBuilderComposesProfilePath`) travels with the
  code into `NetworkingKit`'s own test target.
- `tuist generate` succeeds; `NetworkingKit` and `App` both build; the
  moved test passes.

**For the `SettingsRow` extraction:**
- The skill refuses the extraction.
- The Output Contract states "Changes Made: none — extraction refused"
  and names the specific checklist items that failed (no reuse, no
  ownership boundary, no test-isolation benefit).
- No file is created or modified.

## What must NOT happen

- `SettingsRow` extracted into its own target anyway "because it was
  asked for."
- The extracted networking code's public behavior changed while moving.
- Any change to `SettingsRow.swift` when the networking extraction is the
  one being exercised (the two prompts are independent — only the
  targeted code should move).

## How to check

1. For the networking prompt: `git diff` should show a new
   `NetworkingKit/` directory, `Project.swift` gaining a `NetworkingKit`
   target and `App` depending on it, and `Networking.swift` +
   `AppTests.swift`'s networking test relocated — nothing else touched.
2. For the `SettingsRow` prompt: `git diff` should be empty (or contain
   only the skill's own reported output, not tracked in this directory);
   confirm via `git status --short tests/fixtures/extract-candidate`.
3. Independently run `tuist install && tuist generate --no-open &&
   xcodebuild build` (and `xcodebuild test` for the relevant scheme)
   after the networking extraction to confirm the skill's own report
   wasn't taken on faith.
4. Reset with `git checkout -- tests/fixtures/extract-candidate && git
   clean -fdx tests/fixtures/extract-candidate` between exercising either
   prompt and before committing any further changes to this fixture.
```

- [ ] **Step 9: Commit**

```bash
git add tests/fixtures/extract-candidate
git commit -m "test: add extract-candidate fixture (proceed and refuse paths)"
```

---

### Task 6: Fixture — `tests/fixtures/architecture-smells/`

**Files:**
- Create: `tests/fixtures/architecture-smells/Tuist.swift`
- Create: `tests/fixtures/architecture-smells/Project.swift`
- Create: `tests/fixtures/architecture-smells/App/Sources/ArchitectureSmellsApp.swift`
- Create: `tests/fixtures/architecture-smells/App/Tests/AppTests.swift`
- Create: `tests/fixtures/architecture-smells/CoreKit/Sources/CoreKit.swift`
- Create: `tests/fixtures/architecture-smells/CoreKit/Tests/CoreKitTests.swift`
- Create: `tests/fixtures/architecture-smells/FeatureA/Sources/FeatureA.swift`
- Create: `tests/fixtures/architecture-smells/FeatureA/Tests/FeatureATests.swift`
- Create: `tests/fixtures/architecture-smells/EXPECTATIONS.md`

**Interfaces:**
- Consumes: nothing (leaf fixture).
- Produces: the fixture Task 3's `ios-tuist-architecture-review` is
  exercised against.

- [ ] **Step 1: Write `tests/fixtures/architecture-smells/Tuist.swift`**

```swift
import ProjectDescription

let tuist = Tuist()
```

- [ ] **Step 2: Write `tests/fixtures/architecture-smells/Project.swift`**

Three targets: `App` (depends on `FeatureA`), `FeatureA` (depends on
`CoreKit`), `CoreKit` (declared with no dependencies in the manifest —
the smell lives in the *source*, not the manifest, per Step 4 below).

```swift
import ProjectDescription

let project = Project(
    name: "App",
    targets: [
        .target(
            name: "App",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.ios-tuist-skills.architecture-smells",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: ["UILaunchScreen": [:]]),
            buildableFolders: ["App/Sources"],
            dependencies: [.target(name: "FeatureA")]
        ),
        .target(
            name: "AppTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.architecture-smells-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["App/Tests"],
            dependencies: [.target(name: "App")]
        ),
        .target(
            name: "FeatureA",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.architecture-smells-feature-a",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["FeatureA/Sources"],
            dependencies: [.target(name: "CoreKit")]
        ),
        .target(
            name: "FeatureATests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.architecture-smells-feature-a-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["FeatureA/Tests"],
            dependencies: [.target(name: "FeatureA")]
        ),
        .target(
            name: "CoreKit",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.architecture-smells-core-kit",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["CoreKit/Sources"],
            dependencies: []
        ),
        .target(
            name: "CoreKitTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.architecture-smells-core-kit-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["CoreKit/Tests"],
            dependencies: [.target(name: "CoreKit")]
        ),
    ]
)
```

Note: `CoreKit` declares **zero** dependencies in the manifest — a real
manifest-declared cycle (`CoreKit` depending on `FeatureA` while
`FeatureA` depends on `CoreKit`) would fail at `tuist generate` and this
fixture must remain buildable. The smell
`ios-tuist-architecture-review` should find is **source-level**, not
manifest-level: `FeatureA` already has a legitimate manifest dependency
on `CoreKit`, but (per Step 4/5 below) neither target's source actually
uses the other's public API — instead both independently duplicate the
same formatting logic, evidence that `FeatureA`'s dependency on
`CoreKit` isn't being leveraged and the boundary between them is
unclear.

- [ ] **Step 3: Write the app entry point and its test**

`tests/fixtures/architecture-smells/App/Sources/ArchitectureSmellsApp.swift`:

```swift
import FeatureA
import SwiftUI

@main
struct ArchitectureSmellsApp: App {
    var body: some Scene {
        WindowGroup {
            FeatureAView()
        }
    }
}
```

`tests/fixtures/architecture-smells/App/Tests/AppTests.swift`:

```swift
import Testing
@testable import App

@Test func appLaunchesWithoutCrashing() {
    #expect(true)
}
```

(This one placeholder-style test is acceptable here only because the app
target's own entry point has no independent logic to test beyond
composing `FeatureAView` — the meaningful, non-placeholder tests live in
`FeatureA` and `CoreKit`, per `references/testing.md`'s scope guidance.)

- [ ] **Step 4: Write `CoreKit` with the duplicated-logic smell**

`tests/fixtures/architecture-smells/CoreKit/Sources/CoreKit.swift` —
`CoreKit` has no manifest dependency on `FeatureA`, but its source
duplicates a formatting rule that `FeatureA` also defines independently,
evidence that the two targets' boundary is not actually clean (a
dependency-direction/ownership smell `ios-tuist-architecture-review`
should be able to name from source inspection):

```swift
import Foundation

public enum CoreDisplayFormatter {
    public static func title(for rawValue: String) -> String {
        rawValue.uppercased()
    }
}
```

`tests/fixtures/architecture-smells/CoreKit/Tests/CoreKitTests.swift`:

```swift
import Testing
@testable import CoreKit

@Test func titleUppercasesRawValue() {
    #expect(CoreDisplayFormatter.title(for: "profile") == "PROFILE")
}
```

- [ ] **Step 5: Write `FeatureA` with the duplicated logic and the actual smell**

`tests/fixtures/architecture-smells/FeatureA/Sources/FeatureA.swift` —
`FeatureA` re-implements the same uppercasing rule instead of depending
on `CoreKit`'s `CoreDisplayFormatter`, even though `FeatureA` already
depends on `CoreKit` in the manifest and could reuse it. This is the
concrete, source-visible evidence
`ios-tuist-architecture-review` should surface: a declared dependency
that isn't actually being used to avoid duplication, suggesting either
the dependency is unnecessary or the duplication is an oversight:

```swift
import SwiftUI

public struct FeatureAView: View {
    public init() {}

    public var body: some View {
        Text(FeatureATitleFormatter.title(for: "profile"))
            .padding()
    }
}

public enum FeatureATitleFormatter {
    public static func title(for rawValue: String) -> String {
        rawValue.uppercased()
    }
}
```

`tests/fixtures/architecture-smells/FeatureA/Tests/FeatureATests.swift`:

```swift
import Testing
@testable import FeatureA

@Test func titleUppercasesRawValue() {
    #expect(FeatureATitleFormatter.title(for: "profile") == "PROFILE")
}
```

- [ ] **Step 6: Validate the fixture builds and tests as-is**

```bash
cd tests/fixtures/architecture-smells
tuist install
tuist generate --no-open
xcodebuild -workspace App.xcworkspace -scheme App -destination 'generic/platform=iOS Simulator' build
xcodebuild test -workspace App.xcworkspace -scheme App -destination 'platform=iOS Simulator,name=iPhone 16'
xcodebuild test -workspace App.xcworkspace -scheme FeatureA -destination 'platform=iOS Simulator,name=iPhone 16'
xcodebuild test -workspace App.xcworkspace -scheme CoreKitTests -destination 'platform=iOS Simulator,name=iPhone 16'
rm -rf App.xcworkspace *.xcodeproj .build
cd -
```

Expected: build and every test scheme succeed — the smell is a design
issue, not a build break. Adjust the exact scheme names to whatever
`tuist generate` actually produces (confirm with `tuist generate
--no-open` then inspecting `App.xcworkspace`'s schemes) before finalizing
this step; the `modular` fixture's precedent is that a target ending in
a name Tuist treats specially (like `SharedUI`/`SharedUITests`) gets its
own standalone test scheme — check whether `FeatureA`/`FeatureATests` and
`CoreKit`/`CoreKitTests` generate combined or standalone schemes here and
use the real names.

- [ ] **Step 7: Write `tests/fixtures/architecture-smells/EXPECTATIONS.md`**

```markdown
# Fixture: architecture-smells

**Exercises:** `ios-tuist-architecture-review`

## Starting state

A real, buildable three-target Tuist project: `App -> FeatureA ->
CoreKit`. `CoreKit` has no manifest dependency on `FeatureA`. The smell is
source-level, not manifest-level (a real manifest-declared cycle would
fail to generate, so this fixture encodes the smell as evidence a
diagnostic review can find by reading source, not just the graph):

- `CoreKit` and `FeatureA` each independently define the same
  uppercasing formatter (`CoreDisplayFormatter.title` and
  `FeatureATitleFormatter.title`), despite `FeatureA` already declaring a
  manifest dependency on `CoreKit`.

## Prompt to exercise this fixture

> Review this project's architecture.

## Expected behavior

- The skill maps the graph (`App -> FeatureA -> CoreKit`) before making
  any claim.
- The skill's findings name the duplicated formatting logic as evidence
  that `FeatureA`'s dependency on `CoreKit` isn't being fully leveraged,
  or that the boundary between the two targets is unclear — citing the
  actual files (`CoreKit/Sources/CoreKit.swift`,
  `FeatureA/Sources/FeatureA.swift`) as evidence.
- No file in the fixture is modified.
- The report includes a "Not Flagged" section noting graph areas
  checked and found sound (e.g. `App`'s single outbound dependency on
  `FeatureA` is unremarkable).

## What must NOT happen

- Any edit to `Project.swift` or any source file in this fixture.
- A finding that isn't traceable to something actually present in this
  fixture's graph or source.
- A recommendation that forces one specific architecture style rather
  than naming the checklist/graph rule violated.

## How to check

1. `git status --short tests/fixtures/architecture-smells` after running
   the skill — must show no changes.
2. Read the skill's findings report — confirm it names `CoreKit` and/or
   `FeatureA` and cites the duplicated formatter as evidence, not a
   generic "consider consolidating shared code" comment untethered to
   this fixture.
3. Independently run `tuist install && tuist generate --no-open &&
   xcodebuild build` plus the three test schemes to confirm the fixture
   itself remains buildable and passing throughout (the smell doesn't
   break the build — that's the point).
```

- [ ] **Step 8: Commit**

```bash
git add tests/fixtures/architecture-smells
git commit -m "test: add architecture-smells fixture (source-level coupling smell)"
```

---

### Task 7: Fixture — `tests/fixtures/ci-gaps/`

**Files:**
- Create: `tests/fixtures/ci-gaps/Tuist.swift`
- Create: `tests/fixtures/ci-gaps/Project.swift`
- Create: `tests/fixtures/ci-gaps/App/Sources/CIGapsApp.swift`
- Create: `tests/fixtures/ci-gaps/App/Tests/AppTests.swift`
- Create: `tests/fixtures/ci-gaps/.github/workflows/ci.yml`
- Create: `tests/fixtures/ci-gaps/EXPECTATIONS.md`

**Interfaces:**
- Consumes: nothing (leaf fixture). Its embedded `.github/workflows/ci.yml`
  is fixture *content*, never executed by GitHub Actions directly (a
  workflow file only runs from a repo's real `.github/workflows/`, not
  from a nested fixture path) — it exists purely for `ios-tuist-ci` to
  read, critique, and (in a manual exercise) rewrite.
- Produces: the fixture Task 4's `ios-tuist-ci` is exercised against.

- [ ] **Step 1: Write `tests/fixtures/ci-gaps/Tuist.swift`**

```swift
import ProjectDescription

let tuist = Tuist()
```

- [ ] **Step 2: Write `tests/fixtures/ci-gaps/Project.swift`**

```swift
import ProjectDescription

let project = Project(
    name: "App",
    targets: [
        .target(
            name: "App",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.ios-tuist-skills.ci-gaps",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: ["UILaunchScreen": [:]]),
            buildableFolders: ["App/Sources"],
            dependencies: []
        ),
        .target(
            name: "AppTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.ci-gaps-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: ["App/Tests"],
            dependencies: [.target(name: "App")]
        ),
    ]
)
```

- [ ] **Step 3: Write the app source and one real test**

`tests/fixtures/ci-gaps/App/Sources/CIGapsApp.swift`:

```swift
import SwiftUI

@main
struct CIGapsApp: App {
    var body: some Scene {
        WindowGroup {
            Text(Greeting.text)
        }
    }
}

enum Greeting {
    static let text = "Hello, CI"
}
```

`tests/fixtures/ci-gaps/App/Tests/AppTests.swift`:

```swift
import Testing
@testable import App

@Test func greetingTextIsStable() {
    #expect(Greeting.text == "Hello, CI")
}
```

- [ ] **Step 4: Write the deliberately-gapped embedded workflow**

`tests/fixtures/ci-gaps/.github/workflows/ci.yml` — a minimal, real CI
workflow shape for this fixture that deliberately omits caching and
resolves dependencies twice (once implicitly via `tuist generate`'s own
resolution and once via an explicit, redundant `tuist install` right
before it), so `ios-tuist-ci` has concrete, nameable gaps:

```yaml
name: CI

on:
  push:
  pull_request:
    branches: [main]

jobs:
  build-and-test:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v6

      - name: Install Tuist
        uses: jdx/mise-action@v4
        with:
          tool_versions: |
            tuist 4.206.0

      - name: Resolve dependencies
        run: tuist install

      - name: Resolve dependencies again
        run: tuist install

      - name: Generate project
        run: tuist generate --no-open

      - name: Build
        run: >-
          xcodebuild -workspace App.xcworkspace -scheme App
          -destination 'generic/platform=iOS Simulator' build

      - name: Test
        run: >-
          xcodebuild test -workspace App.xcworkspace -scheme App
          -destination 'platform=iOS Simulator,name=iPhone 16'
```

- [ ] **Step 5: Validate the fixture project builds and tests as-is**

```bash
cd tests/fixtures/ci-gaps
tuist install
tuist generate --no-open
xcodebuild -workspace App.xcworkspace -scheme App -destination 'generic/platform=iOS Simulator' build
xcodebuild test -workspace App.xcworkspace -scheme App -destination 'platform=iOS Simulator,name=iPhone 16'
rm -rf App.xcworkspace *.xcodeproj .build
cd -
```

Expected: build and test both succeed. This validates the *project*, not
the embedded workflow file (the embedded workflow is fixture content for
`ios-tuist-ci` to critique, not something this step executes).

- [ ] **Step 6: Verify the embedded workflow YAML is syntactically valid**

Run:

```bash
python3 -c "import yaml; yaml.safe_load(open('tests/fixtures/ci-gaps/.github/workflows/ci.yml'))"
```

Expected: no error.

- [ ] **Step 7: Write `tests/fixtures/ci-gaps/EXPECTATIONS.md`**

```markdown
# Fixture: ci-gaps

**Exercises:** `ios-tuist-ci`

## Starting state

A real, buildable single-target Tuist project with its own embedded CI
workflow at `.github/workflows/ci.yml` (fixture content — this workflow
is never executed by GitHub Actions directly, since it lives under a
nested fixture path rather than the repo's real `.github/workflows/`).
The embedded workflow deliberately:

- Resolves dependencies twice (`tuist install` runs in two separate,
  redundant steps).
- Has no caching for Tuist's resolved dependencies.
- Pins Tuist 4.206.0, matching this fixture's project (no version
  mismatch to find here — that's not this fixture's smell).

## Prompt to exercise this fixture

> Check the CI workflow for tests/fixtures/ci-gaps.

## Expected behavior

- The skill inventories the workflow's jobs and steps before proposing
  anything.
- Findings name the redundant `tuist install` step and the missing
  caching, each with the exact step name/line as evidence.
- The skill proposes the specific diff (e.g. removing the redundant
  step, adding an `actions/cache` step) before applying it.
- After an approved change, the embedded workflow YAML remains
  syntactically valid, and the fixture's Tuist project still resolves,
  generates, builds, and tests successfully.

## What must NOT happen

- The Tuist version pin (`4.206.0`) changed.
- A validation step (build or test) removed to "speed things up."
- A new CI provider introduced.
- The change applied without first presenting the diff for approval.

## How to check

1. Read the skill's findings — confirm both the redundant-install and
   missing-caching issues are named with concrete evidence (step names),
   not generic advice.
2. Confirm the skill presented the diff before editing
   `tests/fixtures/ci-gaps/.github/workflows/ci.yml`.
3. `python3 -c "import yaml; yaml.safe_load(open('tests/fixtures/ci-gaps/.github/workflows/ci.yml'))"`
   after the change — must still succeed.
4. Independently run `tuist install && tuist generate --no-open &&
   xcodebuild build` (and the test step) against the fixture project
   after the workflow change, to confirm the project itself is
   unaffected by an edit scoped to CI config only.
5. Reset with `git checkout -- tests/fixtures/ci-gaps` before reusing
   this fixture.
```

- [ ] **Step 8: Commit**

```bash
git add tests/fixtures/ci-gaps
git commit -m "test: add ci-gaps fixture (redundant install, no caching)"
```

---

### Task 8: Extend `.github/workflows/validate-fixtures.yml` with the three new fixtures

**Files:**
- Modify: `.github/workflows/validate-fixtures.yml`

**Interfaces:**
- Consumes: `tests/fixtures/extract-candidate/`,
  `tests/fixtures/architecture-smells/`, `tests/fixtures/ci-gaps/` (all
  three must already exist and build, from Tasks 5–7).
- Produces: the extended regression gate described in spec §7.4.

- [ ] **Step 1: Read the current workflow file**

Run: `cat .github/workflows/validate-fixtures.yml`

Confirm the existing `matrix.include` list and per-fixture `test_schemes`
shape before editing (this plan was written against the version quoted
in Task 8's design context — verify it still matches before assuming
line numbers).

- [ ] **Step 2: Add three entries to the matrix**

Add these three entries to the `matrix.include` list, alongside the
existing `legacy-tuist`, `modular`, and `version-mismatch` entries
(confirm the real generated scheme names for `architecture-smells` from
Task 6 Step 6 before finalizing `test_schemes` here — substitute if they
differ from what's shown):

```yaml
          - fixture: extract-candidate
            tuist: 4.206.0
            test_schemes: App
          - fixture: architecture-smells
            tuist: 4.206.0
            test_schemes: App FeatureA CoreKitTests
          - fixture: ci-gaps
            tuist: 4.206.0
            test_schemes: App
```

Do not add a fourth entry for the embedded `ci-gaps` workflow file
itself — per spec §7.4, that file is fixture content validated only by
YAML parsing (Task 7 Step 6), not executed as a real workflow job.

- [ ] **Step 3: Verify the workflow YAML is still syntactically valid**

Run: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/validate-fixtures.yml'))"`

Expected: no error.

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/validate-fixtures.yml
git commit -m "ci: validate extract-candidate, architecture-smells, and ci-gaps fixtures"
```

- [ ] **Step 5: Push and confirm the workflow runs**

```bash
git push
```

Then check the Actions tab (or `gh run watch`) to confirm all six jobs
(three existing plus three new) pass. If any fail, apply Evidence-Driven
Debugging before proceeding — do not mark this task done until CI is
green.

---

### Task 9: README.md and CHANGELOG.md updates, plugin version bump

**Files:**
- Modify: `README.md`
- Modify: `CHANGELOG.md`
- Modify: `.claude-plugin/plugin.json`

**Interfaces:**
- Consumes: everything built in Tasks 1–8 (this task documents the
  finished v0.2 state).
- Produces: the installation/usage doc and version marker a human reads
  first.

- [ ] **Step 1: Read the current README.md, CHANGELOG.md, and plugin.json**

```bash
cat README.md
cat CHANGELOG.md
cat .claude-plugin/plugin.json
```

(Confirm current content before editing so nothing existing is silently
dropped.)

- [ ] **Step 2: Update `README.md`'s Skills section**

Add three new subsections after the existing `ios-tuist-dependency`
entry, matching the existing style exactly (heading, one paragraph, one
example prompt):

```markdown
### `ios-tuist-module`

Extracts existing code from a target into a new module, applying the
modularization justification checklist before acting — refusing the
extraction and reporting why when the checklist isn't concretely met.
Example: "Extract the networking code into its own module called
NetworkingKit."

### `ios-tuist-architecture-review`

Diagnoses an existing project's target graph, dependency direction, and
linkage choices, and reports findings with concrete evidence — makes no
code changes. Example: "Review this project's architecture."

### `ios-tuist-ci`

Audits an existing CI workflow for a Tuist project — version-pin
consistency, caching, redundant steps, parallelization — and applies
improvements the user approves. Example: "Check our CI workflow for
efficiency."
```

- [ ] **Step 3: Update `README.md`'s Repository layout section**

Confirm the existing tree still matches reality (no new top-level
directories were added — `skills/` gained three subdirectories, which the
existing prose "Bootstrap, feature, and dependency skills" line should be
updated to reflect):

Change:
```
skills/               Bootstrap, feature, and dependency skills
```
to:
```
skills/               Bootstrap, feature, dependency, module,
                       architecture-review, and CI skills
```

- [ ] **Step 4: Update `README.md`'s Fixtures and CI section**

Add three bullets after the existing four, matching the existing style:

```markdown
- [extract candidate](tests/fixtures/extract-candidate/EXPECTATIONS.md):
  proving both the extraction-proceeds and extraction-refused paths of
  `ios-tuist-module`
- [architecture smells](tests/fixtures/architecture-smells/EXPECTATIONS.md):
  a source-level coupling smell `ios-tuist-architecture-review` must
  name with concrete evidence, without editing anything
- [CI gaps](tests/fixtures/ci-gaps/EXPECTATIONS.md): a redundant,
  uncached embedded workflow `ios-tuist-ci` must find and improve
```

- [ ] **Step 5: Update `README.md`'s spec link**

Add a line after the existing v0.1 spec link:

```markdown
The v0.2 milestone (module extraction, architecture review, and CI
auditing) is specified in the
[v0.2 design specification](docs/superpowers/specs/2026-09-17-ios-tuist-skills-v0.2-design.md).
```

- [ ] **Step 6: Add the `[0.2.0]` entry to `CHANGELOG.md`**

Replace the `## [Unreleased]` line's empty body with:

```markdown
## [Unreleased]

## [0.2.0] - 2026-09-17

### Added

- `ios-tuist-module`: extracts existing code into a new module/target,
  gated by the modularization justification checklist — refuses
  extraction and reports why when the checklist isn't concretely met.
- `ios-tuist-architecture-review`: diagnoses an existing project's
  target graph and dependency direction against modularization
  principles; read-only, reports findings only.
- `ios-tuist-ci`: audits an existing CI workflow for version-pin
  consistency, caching, and redundant steps; applies user-approved
  improvements without reducing validation coverage.
- Extended `references/modularization.md` with an "Applying this
  checklist" section shared by the extraction-gate and diagnostic-review
  use cases.
- `extract-candidate`, `architecture-smells`, and `ci-gaps` fixtures with
  scenario expectations, wired into the existing fixture-validation CI
  matrix.
```

- [ ] **Step 7: Bump the plugin version**

In `.claude-plugin/plugin.json`, change:
```json
  "version": "0.1.0",
```
to:
```json
  "version": "0.2.0",
```

- [ ] **Step 8: Verify plugin.json is still valid JSON**

Run: `python3 -m json.tool .claude-plugin/plugin.json`
Expected: pretty-printed JSON output, no error.

- [ ] **Step 9: Commit**

```bash
git add README.md CHANGELOG.md .claude-plugin/plugin.json
git commit -m "docs: document v0.2 skills and bump plugin version"
```

---

### Task 10: Final spec-compliance sweep

**Files:**
- No new files — this task audits the whole repo against spec §10's
  acceptance criteria and fixes any gaps found.

**Interfaces:**
- Consumes: the entire repository state after Tasks 1–9.
- Produces: nothing new by default; only produces fixes if gaps are
  found.

- [ ] **Step 1: Run the acceptance checklist from spec §10**

```bash
# All three new SKILL.md files exist and start with valid frontmatter
for f in skills/ios-tuist-module/SKILL.md skills/ios-tuist-architecture-review/SKILL.md skills/ios-tuist-ci/SKILL.md; do
  head -1 "$f" | grep -q '^---$' && echo "OK: $f" || echo "MISSING/BROKEN: $f"
done

# modularization.md contains the new section
grep -q "## Applying this checklist" references/modularization.md && echo "OK: modularization.md extended" || echo "MISSING: modularization.md extension"

# No new shared reference file was added
test $(ls references | wc -l) -eq 5 && echo "OK: still 5 shared reference files" || echo "UNEXPECTED: reference file count changed"

# All three new fixtures have EXPECTATIONS.md
for d in tests/fixtures/extract-candidate tests/fixtures/architecture-smells tests/fixtures/ci-gaps; do
  test -f "$d/EXPECTATIONS.md" && echo "OK: $d" || echo "MISSING: $d/EXPECTATIONS.md"
done

# Plugin version bumped
grep -q '"version": "0.2.0"' .claude-plugin/plugin.json && echo "OK: plugin.json version" || echo "MISSING: plugin.json version bump"

# CHANGELOG has the 0.2.0 entry
grep -q '## \[0.2.0\]' CHANGELOG.md && echo "OK: CHANGELOG 0.2.0 entry" || echo "MISSING: CHANGELOG 0.2.0 entry"

# ios-tuist-architecture-review never mentions build/generate validation
grep -n "tuist generate" skills/ios-tuist-architecture-review/SKILL.md
```

The last command must print nothing. Everything else must print `OK:`
for each line — fix any gap found before proceeding.

- [ ] **Step 2: Confirm CI is green**

Run: `gh run list --branch develop --limit 5`

Expected: the most recent `validate-fixtures.yml` run shows `success`
with six fixture jobs.

- [ ] **Step 3: Remove any leftover `.gitkeep` files made obsolete by real content**

```bash
git status --short
```

Each new skill's `references/` subfolder stays genuinely empty in v0.2
(none of the three new skills needed skill-specific reference content
beyond root `references/`), so their `.gitkeep` files remain — do not
remove them.

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "chore: v0.2 spec-compliance sweep"
git push
```

---

## Post-plan note

This plan covers exactly the v0.2 milestone (spec §1, §10):
`ios-tuist-module`, `ios-tuist-architecture-review`, `ios-tuist-ci`.
`ios-tuist-migrate` (Tuist version/syntax migration) remains a separate,
future spec — do not fold it into this implementation pass.
