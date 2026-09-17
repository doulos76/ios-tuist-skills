# ios-tuist-skills v0.3 — Design Spec

- **Status:** Approved for planning
- **Date:** 2026-09-18
- **Source:** Defined in-conversation (no external PRD); scope is the
  `ios-tuist-migrate` candidate the v0.2 spec explicitly deferred
  (`docs/superpowers/specs/2026-09-17-ios-tuist-skills-v0.2-design.md`
  §1, §9).
- **Scope:** One new skill — `ios-tuist-migrate` — scoped to **Tuist
  version upgrades only** (not general architectural/structural
  migration), plus the shared reference and fixture/CI work needed to
  prove it.
- **Planning/review owner:** Claude

## 1. Purpose

Every other skill in this repository treats the project-pinned Tuist
version as authoritative and refuses to change it
([version-safety](../../references/version-safety.md)'s core rule: never
assume, never silently upgrade). That rule has always carried one named
exception: "an explicit, user-requested Tuist migration workflow" — but
no skill implements that workflow. v0.3 closes that gap with
`ios-tuist-migrate`: the *only* skill in this repository allowed to
change a project's pinned Tuist version, and only when the user
explicitly asks for it.

Explicitly out of scope for v0.3 (deferred or never): structural/
architectural migration (`sources`/`resources` arrays → `buildableFolders`,
`Config.swift` → `Tuist.swift` naming, linkage-strategy changes, or any
other convention change not forced by the target Tuist version itself).
`ios-tuist-migrate` upgrades the version pin and the manifest syntax that
version requires — it does not modernize style choices that still
compile under the new version. That remains each project's own decision,
made explicitly, not a side effect of a version bump.

## 2. Repository layout additions

```text
ios-tuist-skills/
├── skills/
│   └── ios-tuist-migrate/
│       ├── SKILL.md
│       └── references/            # skill-specific only
├── tests/fixtures/
│   └── migrate-candidate/         # ios-tuist-migrate
```

No new shared reference file. No new top-level directories.
`templates/` and `examples/` are unchanged — this skill acts on an
existing project only, never scaffolds one.

## 3. `ios-tuist-migrate`

**Purpose:** Move a project's pinned Tuist version forward to a
user-specified target version, updating the version-pin sources
([version-safety](../../references/version-safety.md) detection order)
and the minimum set of manifest syntax changes the target version
actually requires — nothing else.

**Trigger conditions:** "Upgrade Tuist to 4.x", "Migrate this project
from Tuist 3 to Tuist 4", "Bump our pinned Tuist version." The request
must name or clearly imply a specific target version; "should we
upgrade Tuist?" without a target is a question for
`ios-tuist-architecture-review`-style discussion, not a trigger for this
skill to act.

**Non-trigger conditions:**

- No target version is named or impliable from the request — ask for one
  rather than choosing a version to migrate to.
- The request is really about a structural/style convention (e.g. "move
  us to buildableFolders") with no version driver — out of scope; state
  this explicitly rather than bundling a style change into a version
  bump.
- No existing Tuist project (nothing to migrate; → `ios-tuist-bootstrap`
  for a new one).
- The active installed Tuist version simply differs from the
  project-pinned version with no user request to change the pin — that's
  a mismatch to *report* via the normal
  [version-safety](../../references/version-safety.md) procedure in
  whichever skill surfaced it, not an implicit invitation for this skill
  to run.

**Preconditions:** An existing Tuist project is present and readable; a
target Tuist version is specified; the current project-pinned version is
determinable via [version-safety](../../references/version-safety.md)'s
detection order (a migration needs a known starting point, not just a
known destination).

**Version safety:** This is the one skill in the repository permitted to
change the outcome of [version-safety](../../references/version-safety.md)'s
detection order — every other skill treats the project-pinned version as
fixed; this skill's entire job is changing it, deliberately and visibly.
Still apply the full detection procedure first: an accurate starting
point is required to know what actually needs to change between the two
versions.

**Workflow:**

1. **Establish current and target versions** — run
   [version-safety](../../references/version-safety.md)'s detection order
   for the current project-pinned version; take the target version from
   the user's request. If the request doesn't name one plainly (e.g. "the
   latest" without a resolved number), resolve it to an exact version via
   `tuist version` output, Tuist's own release channel, or ask — never
   migrate to an ambiguous target.
2. **Check the delta is forward and non-trivial** — if current equals
   target, report there is nothing to migrate and stop. Downgrades are
   out of scope for this skill (a genuinely separate, riskier operation);
   refuse and say so if the target is older than the current pin.
3. **Research the actual breaking changes** between current and target
   versions — Tuist's own migration/release notes for every version in
   the range (not just the endpoints; multi-version jumps can carry
   changes from intermediate releases). Never assume a delta from
   memory of "what changed in Tuist N" — verify against the actual
   release notes/changelog for the versions in play.
4. **Inventory affected manifest surface** — scan every `Project.swift`,
   `Tuist.swift`, `Workspace.swift`, `Package.swift` (Tuist-native), and
   `ProjectDescriptionHelpers` file in the project for syntax the
   researched breaking changes actually affect. Anything not touched by
   an identified breaking change is left untouched, even if it "could
   look more modern" under the new version.
5. **Propose the migration plan** — present, before editing anything: the
   version-pin sources that will change (e.g. `.mise.toml`,
   `.tool-versions`, CI workflow install steps, any documented version
   reference) and, file by file, exactly which manifest syntax will
   change and why (which breaking change forces it). This is a shared,
   high-blast-radius, hard-to-reverse change — proposal before edit is
   required, not optional, regardless of auto-mode.
6. **Apply approved changes**:
   - Update every version-pin source identified in step 5 to the target
     version.
   - Apply only the manifest syntax changes the target version actually
     requires, file by file.
   - Do not touch unrelated manifest content, formatting, or convention
     choices that remain valid under the target version.
7. **Validate** — `tuist install` (if applicable) and `tuist generate`
   succeed under the new pinned version; the full project builds; the
   full existing test suite runs and passes. A version migration is
   whole-project by nature (unlike a single-feature or single-module
   change) — validate the whole graph, not just the files touched.

**Decision rules:**

- Never migrate to a version the user didn't specify or confirm.
- Never bundle a structural/style migration into a version migration —
  if a breaking change *forces* a syntax change, make exactly that
  change; if a style choice merely *becomes possible* under the new
  version (e.g. a new folder-integration mode), leave it alone and, if
  worth mentioning, note it as a separate future option in
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

**Validation (required before declaring success):** Every previously
passing validation still passes after migration — `tuist install`
(where applicable) and `tuist generate` succeed under the target
version; the full project builds; the full existing test suite runs and
passes. Compare against a pre-migration baseline run of the same
commands so a regression is attributable to the migration, not
pre-existing project state.

**Failure handling:** Evidence-Driven Debugging, same procedure as the
other skills. First hypothesis to consider here specifically: a breaking
change from an intermediate version in a multi-version jump was missed
because only the endpoint versions' release notes were checked.

**Output contract:**

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
Version Context: Tuist 3.2.1 (project-pinned, before) -> Tuist 4.6.0 (after)

Breaking Changes Applied:
- Source: Tuist 4.0 migration notes — `Config.swift` renamed to
  `Tuist.swift`; `TuistGraph`/`TuistCore` APIs consolidated into
  `ProjectDescription`.
  Evidence: project has `Tuist/Config.swift` using the removed API.
  Files affected: Tuist/Config.swift -> Tuist.swift (renamed, API updated)

Version-Pin Sources Updated:
- .mise.toml: tuist 3.2.1 -> 4.6.0
- .github/workflows/ci.yml: mise tool_versions pin updated

Manifest Changes Made:
- Tuist/Config.swift renamed to Tuist.swift, `TuistGraph.Config` call
  updated to `ProjectDescription`'s `Config` per 4.0 migration notes.
  No other manifest content changed.

Validation:
- Before: tuist generate (3.2.1) succeeded, build succeeded, 42 tests passed
- After: tuist generate (4.6.0) succeeded, build succeeded, 42 tests passed

Risks / Follow-up:
- Tuist 4.6.0 makes Buildable Folders available for this project; not
  applied here since it's a style choice, not a required change — a
  future `ios-tuist-module`/manual change could adopt it if desired.
```

## 4. Fixtures and CI validation

### 4.1 `tests/fixtures/migrate-candidate/`

A real, buildable Tuist project pinned to an older Tuist version than
the repository's other fixtures, using at least one manifest construct
that the jump to the newer pinned version actually breaks (e.g. an
API renamed or removed in a real intervening release) — so the fixture
can prove `ios-tuist-migrate` detects the breaking change, applies
exactly the required fix, and leaves everything else untouched. Include
an `EXPECTATIONS.md` stating: starting version, target version, the
specific breaking change embedded, and the exact file(s) expected to
change (and, as importantly, which files must remain byte-identical).

### 4.2 CI (`.github/workflows/validate-fixtures.yml`)

Extend the existing fixture-validation matrix with one more entry:
`migrate-candidate` pinned at its **starting** (pre-migration) version,
validated the same way as every other fixture (install pinned Tuist,
resolve, generate, build, test) to prove the fixture itself is a real,
buildable starting point — CI validates the fixture's pre-migration
state, not the migration itself (a full before/after migration run is
this skill's own Validation step, exercised when the skill is actually
invoked against the fixture, not something the CI matrix re-derives on
every push).

## 5. CHANGELOG.md and plugin version

- `.claude-plugin/plugin.json` `version` bumps to `0.3.0`; `description`
  gains a mention of version migration alongside the existing five
  capabilities.
- `CHANGELOG.md` gets a `[0.3.0]` entry listing `ios-tuist-migrate` and
  the `migrate-candidate` fixture, following the same Keep-a-Changelog
  style as `[0.1.0]`/`[0.2.0]`.
- `README.md`'s skills list gains a `ios-tuist-migrate` entry alongside
  the existing six.

## 6. Explicit non-goals (v0.3)

- No structural/style migration (folder-integration mode, linkage
  strategy, naming conventions) — only changes the target Tuist version
  actually forces.
- No downgrade support — forward migration only.
- No multi-target-version "migration matrix" testing (e.g. validating
  every intermediate version along the way) — the fixture proves one
  concrete start-to-target jump with a real breaking change; the skill's
  own research step (§3, Workflow step 3) is what covers intermediate
  release notes for whatever real jump a user requests.
- No hard-coded version-compatibility table maintained in this
  repository — breaking changes are researched live against Tuist's own
  release notes each time the skill runs, per Decision Rules.
- Same restated non-goals as v0.1 §10 / v0.2 §9 continue to apply
  repo-wide (no silent version changes by any *other* skill, no forced
  architecture, no side-effect modernization).

## 7. Acceptance criteria for this v0.3 implementation pass

- `ios-tuist-migrate` exists with a complete `SKILL.md` following the
  same section structure as the other six skills (Purpose, Trigger
  Conditions, Non-Trigger Conditions, Preconditions, Version Safety,
  Workflow, Decision Rules, Validation, Failure Handling, Output
  Contract).
- `tests/fixtures/migrate-candidate/` exists as a real, independently
  buildable Tuist project pinned at an older version, with an
  `EXPECTATIONS.md` naming the specific embedded breaking change and the
  exact files expected to change under migration.
- `.github/workflows/validate-fixtures.yml` is extended to
  resolve/generate/build/test the new fixture at its starting version
  alongside the existing six.
- `.claude-plugin/plugin.json` version is `0.3.0` and its description
  mentions version migration.
- `README.md` lists `ios-tuist-migrate` alongside the existing six
  skills.
- `CHANGELOG.md` has a `[0.3.0]` entry.
