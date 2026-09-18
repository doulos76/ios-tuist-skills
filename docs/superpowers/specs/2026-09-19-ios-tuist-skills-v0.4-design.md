# ios-tuist-skills v0.4 — Design Spec

- **Status:** Approved for planning
- **Date:** 2026-09-19
- **Source:** Defined in-conversation (no external PRD); scope is the
  structural/style migration candidate the v0.3 spec explicitly deferred
  (`docs/superpowers/specs/2026-09-18-ios-tuist-skills-v0.3-design.md`
  §1: "structural/architectural migration ... is out of scope for
  v0.3"), narrowed to one concrete conversion.
- **Scope:** One new skill — `ios-tuist-restyle` — scoped to **converting
  array-based `sources:`/`resources:` target declarations to
  `buildableFolders` on user-specified targets only** (not a
  project-wide sweep, not any other structural/style convention), plus
  the shared reference and fixture/CI work needed to prove it.
- **Planning/review owner:** Claude

## 1. Purpose

`references/source-of-truth.md` already names this exact conversion as
an explicit non-default: "if the project uses `sources: ["Sources/**"]`
throughout, do not introduce `buildableFolders` into one new feature.
That is a migration, and migrations are only performed when explicitly
requested." Every other skill in this repository (`ios-tuist-feature`,
`ios-tuist-module`, etc.) correctly refuses to perform this conversion
as a side effect — but nothing in the repository performs it even when
a user *does* explicitly request it. v0.4 closes that gap:
`ios-tuist-restyle` converts one or more user-named targets' folder
integration from `sources:`/`resources:` arrays to `buildableFolders`,
and only on explicit, target-scoped request.

This is a different axis from v0.3's `ios-tuist-migrate` (which changes
a project's *Tuist version pin*): `ios-tuist-restyle` never changes a
version pin, and `ios-tuist-migrate` never changes folder-integration
style as a side effect of a version bump (already a stated non-goal in
the v0.3 spec, §1 and §3 Decision Rules). The two skills are
complementary, not overlapping — a real project could need both a
version migration and a later, separate, explicitly-requested restyle,
run independently.

Explicitly out of scope for v0.4 (deferred or never): any other
structural/style convention (linkage strategy changes, `Config.swift`/
`Tuist.swift` naming — already covered as a forced-by-version-change
inside `ios-tuist-migrate`, not a standalone style choice — dependency
integration method, architecture pattern). Project-wide "convert
everything" requests are also out of scope for this pass — see §3's
Non-Trigger Conditions; the skill acts only on targets the user names.

## 2. Repository layout additions

```text
ios-tuist-skills/
├── skills/
│   └── ios-tuist-restyle/
│       ├── SKILL.md
│       └── references/            # skill-specific only
├── tests/fixtures/
│   └── restyle-candidate/         # ios-tuist-restyle
```

No new shared reference file — `ios-tuist-restyle` reads
`references/source-of-truth.md` (folder-integration inspection,
Existing Project Mode's "existing conventions win unless migration is
explicitly requested" rule) and `references/version-safety.md`
(`buildableFolders` requires Tuist ≥ 4.62.0 — see §3's Version Safety),
but doesn't need a new shared procedure of its own. No new top-level
directories.

## 3. `ios-tuist-restyle`

**Purpose:** Convert one or more explicitly user-named targets' folder
integration from array-based `sources:`/`resources:` declarations to
`buildableFolders`, applying a safety checklist before acting — refusing
the conversion (and saying why) for any named target where the
checklist finds a real risk, per target, independently.

**Trigger conditions:** "Convert FeatureA to buildableFolders", "Migrate
the App target's sources/resources arrays to buildable folders",
"Switch NetworkingKit away from sources arrays." The request must name
one or more specific targets.

**Non-trigger conditions:**

- The request asks to convert "the whole project" or names no specific
  target(s) — out of scope for this pass; ask which target(s) to
  convert rather than sweeping every target in one run. (A future
  milestone could add a project-wide mode; this skill's v0.4 scope is
  deliberately per-target.)
- The named target(s) already use `buildableFolders` — report there is
  nothing to convert and stop.
- The request is about a different structural/style convention (linkage
  strategy, dependency integration method, architecture pattern) — out
  of scope; state this explicitly rather than bundling an unrelated
  convention change into a folder-integration request.
- The request is really a version migration ("upgrade Tuist and modernize
  the folder structure") — the version part belongs to
  [`ios-tuist-migrate`](../ios-tuist-migrate/SKILL.md); if the user wants
  both, they are two separate, sequential requests, not one combined
  operation.
- No existing Tuist project, or the named target doesn't exist in the
  project's manifests.

**Preconditions:** An existing Tuist project is present and readable;
one or more specific existing target names are given; each named
target's current manifest declares `sources:` and/or `resources:` as
literal arrays (not already `buildableFolders`).

**Version safety:** Full
[version-safety](../../references/version-safety.md) procedure, Existing
Project Mode. `buildableFolders` requires **Tuist 4.62.0 or later**
(introduced in that release, mapping to Xcode 16's synchronized-groups
feature). If the project-pinned Tuist version is older than 4.62.0,
refuse every named target and say so — do not proceed, and do not
silently suggest a version bump (that decision belongs to
`ios-tuist-migrate`, on a separate explicit request per the Non-Trigger
Conditions above).

**Workflow:**

1. **Resolve the target list** — the specific target name(s) named in
   the request. For each, confirm it exists in the project's manifests
   and currently declares `sources:`/`resources:` arrays (not already
   `buildableFolders`).
2. **Confirm the Tuist version floor** — project-pinned version ≥
   4.62.0 ([version-safety](../../references/version-safety.md)). Below
   the floor: refuse all named targets, report why, stop.
3. **Apply the per-target safety checklist** (§3.1 below) to each named
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
   `buildableFolders:` array covering the same directories (per the
   verified conversion shape in §3.2). Do not move, rename, or alter any
   source or resource file on disk — this is a manifest-only structural
   change, never a file-content or file-layout change.
6. **Validate** — `tuist generate` succeeds for the affected target(s)
   and any dependent target(s); the affected target(s) build; the
   affected target(s)' existing tests run and pass; no other target's
   manifest or generated output changes.

### 3.1 Per-target safety checklist (refusal gate)

Every item must have a concrete, stated answer, checked against the
actual target's manifest and file tree — never assumed. Any item
answered "yes, this risk is present" is a reason to refuse that target's
conversion and report why; it is not a box to check past. A refusal is a
valid, complete outcome for that target.

- **Exclude patterns:** Does the target's current `sources:`/
  `resources:` arrays use Tuist's real exclusion mechanism — the
  `.glob(pattern:excluding:)` case (e.g. `sources: [.glob("Sources/**",
  excluding: ["Sources/Generated/**"])]`, verified live: this compiles
  and `tuist generate` correctly omits the excluded path from the
  built target) — or any per-file compiler flag/setting?
  `buildableFolders` has no supported equivalent for excluding specific
  files or paths within an included folder as of the project-pinned
  version — a target relying on exclusion cannot be safely converted
  without silently losing that exclusion.
- **Cross-target file references:** Does any *other* target's manifest
  reference an individual file that lives inside this target's
  source/resource directories (rather than depending on the target as a
  whole)? Tuist's buildable-folders implementation can fail to add such
  a file to the right build phase once the owning target is converted —
  this is a real, currently-open Tuist defect
  (tuist/tuist#8337), not a hypothetical.
- **Static framework + resources:** Is the target's `product:`
  `.staticFramework` (or `.staticLibrary`) AND does it declare
  `resources:`? A currently-open Tuist defect
  (tuist/tuist#8547) can place buildable-folder resources on the
  framework instead of the consuming app's generated bundle for static
  products — refuse if both conditions hold, unless the project-pinned
  Tuist version's changelog confirms this specific defect is fixed.
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

### 3.2 Verified conversion shape

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

**Decision Rules:**

- Never convert a target the user didn't name.
- Never sweep "the whole project" in one run — even if multiple targets
  are named, evaluate and report each one's checklist result
  independently; a mixed proceed/refuse outcome across named targets is
  valid and expected.
- Never silently drop an exclusion pattern, per-file flag, or any other
  expressive capability that array-based `sources:`/`resources:` had and
  `buildableFolders` cannot represent — refuse instead (§3.1).
- Never move, rename, or edit the contents of any source or resource
  file — this skill only rewrites manifest declarations.
- Never bundle a Tuist version bump into this conversion, even if the
  project is below the 4.62.0 floor — refuse and point at
  `ios-tuist-migrate` as the separate, explicit next step if the user
  wants one.
- A refusal (version floor not met, checklist risk found, no target
  named, target already converted) is a valid, complete outcome of this
  skill, independently per named target.

**Validation (required before declaring success):** `tuist generate`
succeeds; every converted target builds; every converted target's
existing tests run and pass; the generated project for every
**non-converted** target is unchanged (spot-check: a target not named in
the request produces identical generated output before and after).

**Failure handling:** Evidence-Driven Debugging, same procedure as the
other skills. First hypothesis to consider here specifically: a file
under the converted target's directory that was previously excluded by
an array pattern is now silently included (or a file expected inside is
missing from the generated bundle), surfacing as an unexpected extra
file in the build or a missing-resource runtime failure — always
diff the target's generated file membership before and after, not just
"did it build."

**Output contract:**

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
- SharedUI: exclude pattern `!Sources/Preview/**` has no buildableFolders
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

## 4. Fixtures and CI validation

### 4.1 `tests/fixtures/restyle-candidate/`

A real, buildable Tuist project, pinned at Tuist 4.206.0 (above the
4.62.0 floor), with at least two targets: one that is a clean,
checklist-clear candidate for conversion (plain `sources:`/`resources:`
arrays, no exclusions, no cross-target file references, no static
framework + resources combination), and one that deliberately fails the
checklist (e.g. an exclude pattern in its `sources:` array) — so the
fixture can prove both the "proceed" and "refuse" paths of
`ios-tuist-restyle` in one project, the same dual-path pattern v0.2's
`extract-candidate` fixture already established for `ios-tuist-module`.

### 4.2 CI (`.github/workflows/validate-fixtures.yml`)

Extend the existing fixture-validation matrix with one more entry:
`restyle-candidate`, pinned at its Tuist version (4.206.0), validated
the same way as every other fixture (per the matrix's now-established
`workspace`/`resolve_cmd`/`test_schemes` fields — see v0.3's amendment
to this workflow) — CI validates the fixture's pre-conversion state (it
must be real and buildable as committed, with array-based
`sources:`/`resources:` throughout), not the conversion itself. As with
`ios-tuist-migrate`'s `migrate-candidate` fixture, the actual
convert-and-revalidate cycle is this skill's own Validation step,
exercised when the skill runs, not something CI re-derives on every
push.

Use `scripts/validate-fixtures-locally.sh` (added in v0.3) for local
validation while GitHub Actions credit remains constrained — it reads
the matrix directly from the workflow file, so a `restyle-candidate`
matrix entry is automatically picked up with no separate script change.

## 5. CHANGELOG.md and plugin version

- `.claude-plugin/plugin.json` `version` bumps to `0.4.0`; `description`
  gains a mention of folder-integration/style conversion alongside the
  existing six capabilities.
- `CHANGELOG.md` gets a `[0.4.0]` entry listing `ios-tuist-restyle` and
  the `restyle-candidate` fixture, following the same Keep-a-Changelog
  style as prior entries.
- `README.md`'s skills list gains an `ios-tuist-restyle` entry alongside
  the existing seven.

## 6. Explicit non-goals (v0.4)

- No project-wide "convert everything" mode — targets must be named
  explicitly, one request's outcome is per-named-target, independently
  evaluated.
- No other structural/style convention (linkage strategy, dependency
  integration method, architecture pattern, naming conventions beyond
  what `ios-tuist-migrate` already forces on version bumps).
- No bundled Tuist version bump — if the project is below the 4.62.0
  floor, refuse and point at `ios-tuist-migrate` as a separate step.
- No workaround or partial conversion for a checklist-failed target
  (e.g. "convert everything except the excluded files") — a refusal is
  complete and clean, not a best-effort partial migration.
- No hard-coded version-compatibility table beyond the single 4.62.0
  floor fact stated in this spec (which is a fixed historical release
  fact, not a moving compatibility matrix) — this does not conflict with
  the repo-wide "never hard-code a Tuist version inside skills/" rule in
  the same way a compatibility table would, since it's one fixed
  introduction-version fact load-bearing to this skill's core safety
  gate, stated once in its Version Safety section, not a table of
  per-version behavior differences.
- Same restated non-goals as prior milestones continue to apply
  repo-wide (no silent version changes by any *other* skill, no forced
  architecture, no side-effect modernization, no file content/layout
  changes disguised as a manifest restyle).

## 7. Acceptance criteria for this v0.4 implementation pass

- `ios-tuist-restyle` exists with a complete `SKILL.md` following the
  same section structure as the other seven skills (Purpose, Trigger
  Conditions, Non-Trigger Conditions, Preconditions, Version Safety,
  Workflow, Decision Rules, Validation, Failure Handling, Output
  Contract).
- `tests/fixtures/restyle-candidate/` exists as a real, independently
  buildable Tuist project pinned at Tuist 4.206.0, with at least one
  checklist-clear target and one checklist-failing target, and an
  `EXPECTATIONS.md` naming which target is which and why.
- `.github/workflows/validate-fixtures.yml` is extended to
  resolve/generate/build/test the new fixture at its pinned version
  alongside the existing seven.
- `.claude-plugin/plugin.json` version is `0.4.0` and its description
  mentions folder-integration/style conversion.
- `README.md` lists `ios-tuist-restyle` alongside the existing seven
  skills.
- `CHANGELOG.md` has a `[0.4.0]` entry.
