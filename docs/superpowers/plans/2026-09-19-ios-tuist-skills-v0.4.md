# ios-tuist-skills v0.4 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the v0.4 milestone of `ios-tuist-skills`: one new skill,
`ios-tuist-restyle`, that converts user-named targets' array-based
`sources:`/`resources:` declarations to `buildableFolders` — gated by a
per-target safety checklist grounded in real, currently-open Tuist
defects, so a checklist failure on one named target never blocks another
named target's conversion. Includes one new real, buildable fixture with
both a checklist-clear target and a checklist-failing target, validated
by CI.

**Architecture:** Same flat plugin repo shape as prior milestones — no
new top-level directories. One self-contained `SKILL.md` lands in
`skills/ios-tuist-restyle/`. No shared reference file changes — this
skill reads `references/source-of-truth.md` (folder-integration
inspection, the "migrations only on explicit request" rule already
stated there) and `references/version-safety.md` (detection order, and
this skill's 4.62.0 version floor), but its per-target safety checklist
is specific to this one skill and belongs in its own `SKILL.md`. One new
fixture extends the existing `.github/workflows/validate-fixtures.yml`
matrix job — no new workflow file, and no change needed to
`scripts/validate-fixtures-locally.sh` (it reads the matrix directly, so
a new entry is picked up automatically).

**Tech Stack:** Tuist 4.206.0 (matches this repo's other fixtures — well
above the 4.62.0 `buildableFolders` floor), Xcode 27 / Swift 6.4, GitHub
Actions (macOS runner, existing `jdx/mise-action` version-pin pattern).

**Spec:** `docs/superpowers/specs/2026-09-19-ios-tuist-skills-v0.4-design.md`

## Global Constraints

- Never hard-code a Tuist version-compatibility table anywhere in
  `skills/` content — the one exception, per spec §6, is the single
  fixed historical fact "buildableFolders requires Tuist ≥ 4.62.0,"
  stated once in `SKILL.md`'s Version Safety section, not a table of
  per-version behavior differences.
- `ios-tuist-restyle` links to `source-of-truth.md` and
  `version-safety.md` by relative path for their procedures — never
  restates them inline (spec §3).
- `SKILL.md` follows the same section structure as the other seven
  skills: Purpose, Trigger Conditions, Non-Trigger Conditions,
  Preconditions, Version Safety, Workflow, Decision Rules, Validation,
  Failure Handling, Output Contract (spec §3).
- Never convert a target the user didn't name; never sweep "the whole
  project" in one run — evaluate and report each named target's
  checklist result independently (spec §3, §6).
- Never silently drop an exclusion pattern, per-file flag, or any other
  capability array-based `sources:`/`resources:` had that
  `buildableFolders` cannot represent — refuse instead of converting
  partially (spec §3 Decision Rules).
- Never move, rename, or edit the contents of any source/resource file —
  this skill only rewrites manifest declarations (spec §3 Decision
  Rules).
- Never bundle a Tuist version bump into this conversion — below the
  4.62.0 floor, refuse and point at `ios-tuist-migrate` as a separate
  step (spec §3 Version Safety, §6).
- Tuist's real array-based exclusion syntax is the `.glob(pattern:
  excluding:)` case (e.g. `sources: [.glob("Sources/**", excluding:
  ["Sources/Generated/**"])]`) — verified live during plan authoring.
  `"!path/**"` glob negation is NOT valid Tuist syntax and fails
  `tuist generate` outright ("invalid source files globs ... directory
  ... does not exist" — Tuist treats a leading `!` as a literal path
  character). Every fixture file and `SKILL.md` example in this plan
  uses the real `.glob(excluding:)` form; do not substitute `"!..."` if
  improvising beyond what's written here.
- Fixtures under `tests/fixtures/` must be real, independently buildable
  Tuist projects — not structure-only stand-ins (spec §4.1).
- The new fixture joins the existing `validate-fixtures.yml` matrix (one
  job, extended) — do not create a second CI workflow file (spec §4.2).
- MIT license header style is not required per-file; `LICENSE` at repo
  root already covers the whole repo.

---

### Task 1: `ios-tuist-restyle` skill

**Files:**
- Create: `skills/ios-tuist-restyle/SKILL.md`
- Create: `skills/ios-tuist-restyle/references/.gitkeep`

**Interfaces:**
- Consumes: `references/source-of-truth.md` (folder-integration
  inspection, Existing Project Mode's "migrations only on explicit
  request" rule), `references/version-safety.md` (detection order).
- Produces: nothing later tasks import structurally — Task 2's fixture
  is validated independently against this skill's Output Contract
  shape, not linked to it in code.

- [ ] **Step 1: Create the skill directory and empty references folder**

```bash
mkdir -p skills/ios-tuist-restyle/references
touch skills/ios-tuist-restyle/references/.gitkeep
```

- [ ] **Step 2: Write `skills/ios-tuist-restyle/SKILL.md`**

Create with this exact content:

```markdown
---
name: ios-tuist-restyle
description: >
  Converts one or more explicitly user-named targets' folder integration
  from array-based sources:/resources: declarations to buildableFolders,
  gated by a per-target safety checklist grounded in real, currently-open
  Tuist defects. Never sweeps a whole project, never bundles a version
  bump, never silently drops an exclusion.
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
  this is a real, currently-open Tuist defect (tuist/tuist#8337), not a
  hypothetical.
- **Static framework + resources:** Is the target's `product:`
  `.staticFramework` (or `.staticLibrary`) AND does it declare
  `resources:`? A currently-open Tuist defect (tuist/tuist#8547) can
  place buildable-folder resources on the framework instead of the
  consuming app's generated bundle for static products — refuse if both
  conditions hold, unless the project-pinned Tuist version's changelog
  confirms this specific defect is fixed.
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
```

- [ ] **Step 3: Verify the frontmatter and section structure**

```bash
head -8 skills/ios-tuist-restyle/SKILL.md
grep -c "^## " skills/ios-tuist-restyle/SKILL.md
```

Expected: frontmatter block with `name: ios-tuist-restyle` and a
`description`; 10 `##`-level sections matching the other skills' pattern
(Purpose, Trigger Conditions, Non-Trigger Conditions, Preconditions,
Version Safety, Workflow, Decision Rules, Validation, Failure Handling,
Output Contract).

- [ ] **Step 4: Verify the relative reference links resolve**

```bash
test -f references/source-of-truth.md && echo "OK: source-of-truth.md exists"
test -f references/version-safety.md && echo "OK: version-safety.md exists"
test -f skills/ios-tuist-migrate/SKILL.md && echo "OK: ios-tuist-migrate SKILL.md exists"
grep -c "version-safety.md" skills/ios-tuist-restyle/SKILL.md
```

Expected: both `OK:` lines print, plus a third for `ios-tuist-migrate`,
and at least 2 occurrences of `version-safety.md` (Version Safety
section and Workflow step 2).

- [ ] **Step 5: Verify the real exclude-pattern syntax is used, not
  invalid `"!..."` glob negation**

```bash
grep -n '"!' skills/ios-tuist-restyle/SKILL.md || echo "OK: no invalid ! glob syntax"
grep -c "excluding:" skills/ios-tuist-restyle/SKILL.md
```

Expected: `OK: no invalid ! glob syntax` (the grep for `"!` finds
nothing), and at least 2 occurrences of `excluding:`.

- [ ] **Step 6: Commit**

```bash
git add skills/ios-tuist-restyle/
git commit -m "docs: add ios-tuist-restyle skill"
```

---

### Task 2: Fixture — `tests/fixtures/restyle-candidate/`

**Files:**
- Create: `tests/fixtures/restyle-candidate/Tuist.swift`
- Create: `tests/fixtures/restyle-candidate/Project.swift`
- Create: `tests/fixtures/restyle-candidate/App/Sources/RestyleCandidateApp.swift`
- Create: `tests/fixtures/restyle-candidate/App/Tests/AppTests.swift`
- Create: `tests/fixtures/restyle-candidate/CleanFeature/Sources/CleanFeature.swift`
- Create: `tests/fixtures/restyle-candidate/CleanFeature/Resources/dummy.txt`
- Create: `tests/fixtures/restyle-candidate/CleanFeature/Tests/CleanFeatureTests.swift`
- Create: `tests/fixtures/restyle-candidate/ExcludeFeature/Sources/ExcludeFeature.swift`
- Create: `tests/fixtures/restyle-candidate/ExcludeFeature/Sources/Preview/PreviewOnly.swift`
- Create: `tests/fixtures/restyle-candidate/ExcludeFeature/Tests/ExcludeFeatureTests.swift`
- Create: `tests/fixtures/restyle-candidate/EXPECTATIONS.md`

**Interfaces:**
- Consumes: nothing from Task 1 structurally (the fixture is plain
  Tuist project content, not skill code).
- Produces: a real Tuist 4.206.0 project that Task 3's CI matrix entry
  validates as-committed (array-based throughout, both features
  buildable), and that a human (or an agent invoking
  `ios-tuist-restyle`) can exercise the "convert CleanFeature" /
  "refuse ExcludeFeature" dual path as a manual exercise of the skill's
  Workflow.

This exact fixture shape — a 5-target project (`App`, `CleanFeature`,
`CleanFeatureTests`, `ExcludeFeature`, `ExcludeFeatureTests`) — was
verified live during plan authoring: `tuist generate --no-open` succeeds
at Tuist 4.206.0; `xcodebuild build` for scheme `App` succeeds
(confirming `ExcludeFeature`'s excluded `Preview/PreviewOnly.swift`,
which deliberately references a non-existent type, is correctly omitted
from compilation — proving the exclude pattern is real, not decorative);
converting `CleanFeature`'s `sources:`/`resources:` to a single
`buildableFolders: ["CleanFeature/Sources", "CleanFeature/Resources"]`
still generates and builds successfully, and `xcodebuild test -scheme
CleanFeature` passes (note: Tuist names the buildableFolders-converted
static framework's own scheme `CleanFeature`, not a separate
`CleanFeatureTests` scheme — the workspace's actual schemes after
conversion were confirmed via `xcodebuild -list` to be `App`,
`CleanFeature`, `ExcludeFeature`, plus generation-internal schemes; the
`CleanFeature` scheme's own `<TestAction>` runs `CleanFeatureTests`).

- [ ] **Step 1: Create `Tuist.swift`**

```swift
import ProjectDescription

let tuist = Tuist()
```

- [ ] **Step 2: Create `Project.swift`**

```swift
import ProjectDescription

let project = Project(
    name: "RestyleCandidate",
    targets: [
        .target(
            name: "App",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.ios-tuist-skills.restyle-candidate",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["App/Sources/**"],
            dependencies: [
                .target(name: "CleanFeature"),
                .target(name: "ExcludeFeature")
            ]
        ),
        .target(
            name: "AppTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.restyle-candidate-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["App/Tests/**"],
            dependencies: [.target(name: "App")]
        ),
        .target(
            name: "CleanFeature",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.restyle-candidate-cleanfeature",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["CleanFeature/Sources/**"],
            resources: ["CleanFeature/Resources/**"]
        ),
        .target(
            name: "CleanFeatureTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.restyle-candidate-cleanfeature-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["CleanFeature/Tests/**"],
            dependencies: [.target(name: "CleanFeature")]
        ),
        .target(
            name: "ExcludeFeature",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.ios-tuist-skills.restyle-candidate-excludefeature",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: [.glob("ExcludeFeature/Sources/**", excluding: ["ExcludeFeature/Sources/Preview/**"])]
        ),
        .target(
            name: "ExcludeFeatureTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.ios-tuist-skills.restyle-candidate-excludefeature-tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["ExcludeFeature/Tests/**"],
            dependencies: [.target(name: "ExcludeFeature")]
        )
    ]
)
```

This fixture is deliberately a 6-target project — `App`/`AppTests` (the
entry point, exercising both features), `CleanFeature`/
`CleanFeatureTests` (the checklist-clear conversion candidate: plain
arrays, no exclusions, no cross-target file references, and while it
IS a `.staticFramework` with `resources:` — the exact combination
tuist/tuist#8547 flags — this deliberately makes it a case where the
checklist item must be checked and explicitly reasoned about, not
silently skipped; see EXPECTATIONS.md for why this fixture still counts
as checklist-clear: the bug is about *where* resources land at runtime,
not about generate/build/test success, so this fixture proves the
*build* succeeds either way while `ios-tuist-restyle`'s own Decision
Rules require reporting the risk explicitly per Version Safety's
"changelog confirms this defect is fixed" clause), and
`ExcludeFeature`/`ExcludeFeatureTests` (the checklist-failing candidate:
a real `.glob(excluding:)` exclusion with a deliberately broken file
inside the excluded path, proving the exclusion is load-bearing, not
decorative).

- [ ] **Step 3: Create the app source and test**

```bash
mkdir -p tests/fixtures/restyle-candidate/App/Sources
mkdir -p tests/fixtures/restyle-candidate/App/Tests
```

`tests/fixtures/restyle-candidate/App/Sources/RestyleCandidateApp.swift`:

```swift
import SwiftUI
import CleanFeature
import ExcludeFeature

@main
struct RestyleCandidateApp: App {
    var body: some Scene {
        WindowGroup {
            Text(CleanFeatureLabel.text + ExcludeFeatureLabel.text)
        }
    }
}
```

`tests/fixtures/restyle-candidate/App/Tests/AppTests.swift`:

```swift
import XCTest

final class AppTests: XCTestCase {
    func testPlaceholderPasses() {
        XCTAssertTrue(true)
    }
}
```

- [ ] **Step 4: Create `CleanFeature`'s source, resource, and test**

```bash
mkdir -p tests/fixtures/restyle-candidate/CleanFeature/Sources
mkdir -p tests/fixtures/restyle-candidate/CleanFeature/Resources
mkdir -p tests/fixtures/restyle-candidate/CleanFeature/Tests
```

`tests/fixtures/restyle-candidate/CleanFeature/Sources/CleanFeature.swift`:

```swift
public enum CleanFeatureLabel {
    public static let text = "Clean"
}
```

`tests/fixtures/restyle-candidate/CleanFeature/Resources/dummy.txt`:

```text
placeholder resource proving CleanFeature's resources: array is real
```

`tests/fixtures/restyle-candidate/CleanFeature/Tests/CleanFeatureTests.swift`:

```swift
import XCTest
@testable import CleanFeature

final class CleanFeatureTests: XCTestCase {
    func testLabel() {
        XCTAssertEqual(CleanFeatureLabel.text, "Clean")
    }
}
```

- [ ] **Step 5: Create `ExcludeFeature`'s source (including the
  deliberately-excluded broken file) and test**

```bash
mkdir -p tests/fixtures/restyle-candidate/ExcludeFeature/Sources/Preview
mkdir -p tests/fixtures/restyle-candidate/ExcludeFeature/Tests
```

`tests/fixtures/restyle-candidate/ExcludeFeature/Sources/ExcludeFeature.swift`:

```swift
public enum ExcludeFeatureLabel {
    public static let text = "Exclude"
}
```

`tests/fixtures/restyle-candidate/ExcludeFeature/Sources/Preview/PreviewOnly.swift`:

```swift
// Deliberately excluded by ExcludeFeature's `.glob(excluding:)` pattern.
// References a type that doesn't exist — if this file were ever
// accidentally compiled into the target (e.g. by an incorrect
// buildableFolders conversion silently dropping the exclusion), the
// build would fail here, making the omission observable, not silent.
struct ThisMustNotCompile {
    let broken: NonExistentType
}
```

`tests/fixtures/restyle-candidate/ExcludeFeature/Tests/ExcludeFeatureTests.swift`:

```swift
import XCTest
@testable import ExcludeFeature

final class ExcludeFeatureTests: XCTestCase {
    func testLabel() {
        XCTAssertEqual(ExcludeFeatureLabel.text, "Exclude")
    }
}
```

- [ ] **Step 6: Write `EXPECTATIONS.md`**

```markdown
# restyle-candidate

## Starting state

- Pinned Tuist version: **4.206.0** (matches this repository's other
  fixtures; well above the 4.62.0 `buildableFolders` floor).
- Six targets: `App`/`AppTests` (entry point depending on both
  features), `CleanFeature`/`CleanFeatureTests`, `ExcludeFeature`/
  `ExcludeFeatureTests`.
- All targets use array-based `sources:`/`resources:` — none use
  `buildableFolders` as committed.
- Verified live: `tuist generate --no-open` succeeds; `xcodebuild build`
  for scheme `App` succeeds; `ExcludeFeature/Sources/Preview/
  PreviewOnly.swift` (which references a nonexistent type) is correctly
  omitted from compilation by its `.glob(excluding:)` pattern — proving
  the exclusion is real and load-bearing, not decorative.

## `CleanFeature`: the checklist-clear conversion candidate

- Plain `sources: ["CleanFeature/Sources/**"]` and
  `resources: ["CleanFeature/Resources/**"]` — no exclude patterns, no
  per-file flags.
- No other target references an individual file inside
  `CleanFeature/Sources/**` or `CleanFeature/Resources/**` — only a
  whole-target dependency (`App` and `CleanFeatureTests` both depend on
  the `CleanFeature` target itself, never an individual file inside it).
- No directory overlap with any other target's `sources:`/`resources:`/
  `buildableFolders` paths.
- No generated/derived sources — every file under `CleanFeature/` is a
  plain committed file.
- **Note on the static-framework + resources checklist item:**
  `CleanFeature`'s `product:` is `.staticFramework` and it DOES declare
  `resources:` — the exact combination tuist/tuist#8547 flags as a real,
  currently-open defect (buildable-folder resources landing on the
  framework instead of the consuming app's generated bundle). This
  fixture deliberately keeps that combination so `ios-tuist-restyle`
  must reason about this checklist item explicitly (checked, not
  skipped) rather than never encountering it. Verified live: converting
  `CleanFeature` to `buildableFolders: ["CleanFeature/Sources",
  "CleanFeature/Resources"]` still generates, builds, and passes
  `xcodebuild test -scheme CleanFeature` successfully in this fixture's
  specific case — tuist/tuist#8547 is about resource *runtime
  placement* inside the built bundle, not generate/build/test success,
  so this fixture cannot itself prove the bug is absent or present; a
  real invocation of `ios-tuist-restyle` against a project where this
  matters should still report the risk per the skill's Decision Rules,
  it just doesn't happen to manifest as a build/test failure in this
  fixture's minimal case.

## `ExcludeFeature`: the checklist-failing conversion candidate

- `sources: [.glob("ExcludeFeature/Sources/**", excluding:
  ["ExcludeFeature/Sources/Preview/**"])]` — a real Tuist exclusion
  pattern with no `buildableFolders` equivalent.
- `ios-tuist-restyle` is expected to refuse converting `ExcludeFeature`,
  citing this exact exclude pattern, and make no changes to its
  manifest declaration.

## What `ios-tuist-restyle` is expected to do against this fixture

Given a request naming both `CleanFeature` and `ExcludeFeature`:

- Convert `CleanFeature`: `Project.swift`'s `CleanFeature` target's
  `sources: ["CleanFeature/Sources/**"], resources:
  ["CleanFeature/Resources/**"]` replaced with `buildableFolders:
  ["CleanFeature/Sources", "CleanFeature/Resources"]`.
- Refuse `ExcludeFeature`: no changes to its manifest declaration;
  report cites the `.glob(excluding:)` pattern as the reason.
- Leave `App`, `AppTests`, `CleanFeatureTests`, `ExcludeFeatureTests`
  manifest declarations and all source/resource file contents
  byte-identical.

## What must NOT change

- Any `.swift` source file's contents (including
  `ExcludeFeature/Sources/Preview/PreviewOnly.swift`, which must remain
  excluded and unmodified).
- `CleanFeature/Resources/dummy.txt`'s contents.
- `ExcludeFeature`'s manifest declaration (refused, so untouched).
- `App`, `AppTests`, `CleanFeatureTests`, `ExcludeFeatureTests` manifest
  declarations (not named in the request, so untouched).
- Bundle IDs, target names, and dependency edges.

## Manual validation (not run by the outer CI matrix)

1. `mise exec tuist@4.206.0 -- tuist install` and `tuist generate
   --no-open` succeed from this directory as committed.
2. `xcodebuild -workspace RestyleCandidate.xcworkspace -scheme App
   -destination 'generic/platform=iOS Simulator' build` succeeds.
3. Applying `ios-tuist-restyle`'s conversion to `CleanFeature` only,
   then `tuist generate --no-open` succeeds, `xcodebuild build` for
   scheme `App` succeeds, and `xcodebuild test -scheme CleanFeature`
   succeeds.
4. `ExcludeFeature`'s manifest and behavior are unchanged throughout.

CI (`validate-fixtures.yml`) only proves step 1–2's pre-conversion state
is real and buildable at 4.206.0 — steps 3–4 are `ios-tuist-restyle`'s
own Validation step, exercised when the skill actually runs, per the
v0.4 spec §4.2.
```

- [ ] **Step 7: Validate the fixture generates and builds at its pinned
  version (local — GitHub Actions credit may still be constrained; see
  Global Constraints)**

```bash
cd tests/fixtures/restyle-candidate
mise install tuist@4.206.0
test "$(mise exec tuist@4.206.0 -- tuist version)" = "4.206.0"
mise exec tuist@4.206.0 -- tuist install
mise exec tuist@4.206.0 -- tuist generate --no-open
xcodebuild -workspace RestyleCandidate.xcworkspace -scheme App \
  -destination 'generic/platform=iOS Simulator' build
```

Expected: version check passes; `tuist install`/`tuist generate`
succeed; `** BUILD SUCCEEDED **`. This also implicitly confirms
`ExcludeFeature/Sources/Preview/PreviewOnly.swift` is correctly excluded
(if it were accidentally included, this build would fail on
`NonExistentType`).

- [ ] **Step 8: Confirm the CleanFeature conversion works end-to-end
  (proves the fixture's checklist-clear path is real, not assumed)**

```bash
python3 - <<'PYEOF'
content = open("Project.swift").read()
old = '''            sources: ["CleanFeature/Sources/**"],
            resources: ["CleanFeature/Resources/**"]'''
new = '''            buildableFolders: ["CleanFeature/Sources", "CleanFeature/Resources"]'''
assert old in content, "expected CleanFeature sources/resources block not found"
content = content.replace(old, new)
open("Project.swift", "w").write(content)
PYEOF
rm -rf RestyleCandidate.xcworkspace RestyleCandidate.xcodeproj Derived
mise exec tuist@4.206.0 -- tuist generate --no-open
xcodebuild -workspace RestyleCandidate.xcworkspace -scheme App \
  -destination 'generic/platform=iOS Simulator' build
SIMULATOR_ID="$(xcrun simctl list devices available --json | ruby -rjson -e '
  devices = JSON.parse(STDIN.read).fetch("devices").values.flatten
  iphone = devices.find { |device| device["isAvailable"] && device["name"].start_with?("iPhone") }
  abort "No available iPhone simulator found" unless iphone
  print iphone.fetch("udid")
')"
xcodebuild test -workspace RestyleCandidate.xcworkspace -scheme CleanFeature -destination "id=$SIMULATOR_ID"
```

Expected: `tuist generate` succeeds, `** BUILD SUCCEEDED **`, `**
TEST SUCCEEDED **`. Do not proceed to Step 9 until this is confirmed —
an unexpected failure here means the fixture's "clear" candidate isn't
actually clear.

- [ ] **Step 9: Revert the probe conversion — restore the committed
  pre-conversion state**

```bash
git checkout -- Project.swift
rm -rf RestyleCandidate.xcworkspace RestyleCandidate.xcodeproj Derived
```

(`git checkout -- Project.swift` only works once Task 2's files are
staged/committed — if running Steps 7–9 before Step 10's commit, restore
via the Step 2 content directly instead: re-run Step 2's heredoc, or
reverse Step 8's Python replacement. Confirm `git diff Project.swift`
shows no difference from Step 2's authored content before proceeding.)

- [ ] **Step 10: Clean generated artifacts before committing**

```bash
cd /Users/dave/Documents/GitHub/ios-tuist-skills
rm -rf tests/fixtures/restyle-candidate/Derived
rm -rf tests/fixtures/restyle-candidate/RestyleCandidate.xcworkspace
rm -rf tests/fixtures/restyle-candidate/RestyleCandidate.xcodeproj
git status --short tests/fixtures/restyle-candidate/
```

Expected: only the 11 authored files from Steps 1–6 show as untracked —
no generated project/workspace/Derived content, and `Project.swift`
matches Step 2's content exactly (not the Step 8 probe version).

- [ ] **Step 11: Commit**

```bash
git add tests/fixtures/restyle-candidate/
git commit -m "test: add restyle-candidate fixture (buildableFolders proceed and refuse paths)"
```

---

### Task 3: Extend `.github/workflows/validate-fixtures.yml` with the new fixture

**Files:**
- Modify: `.github/workflows/validate-fixtures.yml`

**Interfaces:**
- Consumes: `tests/fixtures/restyle-candidate/` (must already exist and
  build at 4.206.0, from Task 2).
- Produces: the extended regression gate described in spec §4.2.
  `scripts/validate-fixtures-locally.sh` (from v0.3) requires no change
  — it reads this file's matrix directly.

- [ ] **Step 1: Read the current workflow file**

```bash
cat .github/workflows/validate-fixtures.yml
```

Confirm the existing `matrix.include` list and its `workspace`/
`resolve_cmd`/`test_schemes` fields (added in v0.3) before editing —
verify it still matches before assuming line numbers.

- [ ] **Step 2: Add one entry to the matrix**

Add this entry to the `matrix.include` list, alongside the seven
existing entries:

```yaml
          - fixture: restyle-candidate
            tuist: 4.206.0
            workspace: RestyleCandidate
            resolve_cmd: install
            test_schemes: App
```

`resolve_cmd: install` (not `fetch`) because this fixture is pinned at
4.206.0, same as most existing fixtures — only `migrate-candidate`
(pinned at Tuist 3.42.2) needs `fetch`.

- [ ] **Step 3: Verify the workflow YAML is still syntactically valid**

```bash
ruby -ryaml -e "YAML.load_file('.github/workflows/validate-fixtures.yml'); puts 'OK: YAML valid'"
```

(Use the Ruby check, not `python3 -c "import yaml..."` — PyYAML is not
installed on this machine, confirmed during v0.3's implementation.)

Expected: `OK: YAML valid`.

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/validate-fixtures.yml
git commit -m "ci: validate restyle-candidate fixture"
```

- [ ] **Step 5: Validate locally via the committed script**

```bash
./scripts/validate-fixtures-locally.sh restyle-candidate
```

Expected: `restyle-candidate: PASS` in the summary. This script reads
the matrix straight from the workflow file (added in v0.3), so it picks
up the new entry automatically — no separate local-validation command
needs to be hand-written here.

Do not run `git push` or check GitHub Actions run status as this
workflow's own completion evidence unless GitHub Actions credit has
been confirmed restored on this account (see the "CI credit exhausted"
project context) — if still constrained, the script's local pass above
is the substitute evidence. Push is a separate decision made with the
user once the whole plan is done.

---

### Task 4: README.md, CHANGELOG.md, and plugin version updates

**Files:**
- Modify: `README.md`
- Modify: `CHANGELOG.md`
- Modify: `.claude-plugin/plugin.json`

**Interfaces:**
- Consumes: everything built in Tasks 1–3 (this task documents the
  finished v0.4 state).
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

Add one new subsection after the existing `ios-tuist-migrate` entry,
matching the existing style exactly (heading, one paragraph, one example
prompt):

```markdown
### `ios-tuist-restyle`

Converts explicitly user-named targets' folder integration from
array-based sources/resources declarations to buildableFolders, gated by
a per-target safety checklist — refuses any named target where an
exclusion pattern, cross-target file reference, or other real risk would
be silently lost. Example: "Convert FeatureA to buildableFolders."
```

- [ ] **Step 3: Update `README.md`'s Repository layout section**

Change:
```
skills/               Bootstrap, feature, dependency, module,
                      architecture-review, CI, and migration skills
```
to:
```
skills/               Bootstrap, feature, dependency, module,
                      architecture-review, CI, migration, and
                      restyle skills
```

- [ ] **Step 4: Update `README.md`'s Fixtures and CI section**

Add one bullet after the existing eight, matching the existing style:

```markdown
- [restyle candidate](tests/fixtures/restyle-candidate/EXPECTATIONS.md):
  a checklist-clear target and a checklist-failing target (real
  exclusion pattern) `ios-tuist-restyle` must tell apart correctly
```

- [ ] **Step 5: Update `README.md`'s spec link**

Add a line after the existing v0.3 spec link:

```markdown
The v0.4 milestone (folder-integration restyle to buildableFolders) is
specified in the
[v0.4 design specification](docs/superpowers/specs/2026-09-19-ios-tuist-skills-v0.4-design.md).
```

- [ ] **Step 6: Add the `[0.4.0]` entry to `CHANGELOG.md`**

Replace the `## [Unreleased]` line's empty body with:

```markdown
## [Unreleased]

## [0.4.0] - 2026-09-19

### Added

- `ios-tuist-restyle`: converts explicitly user-named targets' folder
  integration from array-based sources:/resources: declarations to
  buildableFolders, gated by a per-target safety checklist grounded in
  real, currently-open Tuist defects (tuist/tuist#8337,
  tuist/tuist#8547). Never sweeps a whole project, never bundles a
  version bump, never silently drops an exclusion pattern.
- `restyle-candidate` fixture: a real Tuist 4.206.0 project with a
  checklist-clear target (CleanFeature) and a checklist-failing target
  (ExcludeFeature, with a genuine `.glob(excluding:)` exclusion pattern),
  wired into the existing fixture-validation CI matrix.
```

- [ ] **Step 7: Bump the plugin version and description**

In `.claude-plugin/plugin.json`, change:
```json
  "description": "Version-aware iOS engineering skills for Tuist-based projects: safe bootstrap, feature addition, dependency management, module extraction, architecture review, CI auditing, and explicit version migration that detect the project's real Tuist/Xcode/Swift versions and preserve existing conventions.",
  "version": "0.3.0",
```
to:
```json
  "description": "Version-aware iOS engineering skills for Tuist-based projects: safe bootstrap, feature addition, dependency management, module extraction, architecture review, CI auditing, explicit version migration, and folder-integration restyling that detect the project's real Tuist/Xcode/Swift versions and preserve existing conventions.",
  "version": "0.4.0",
```

- [ ] **Step 8: Verify plugin.json is still valid JSON**

```bash
python3 -m json.tool .claude-plugin/plugin.json
```

Expected: pretty-printed JSON output, no error.

- [ ] **Step 9: Commit**

```bash
git add README.md CHANGELOG.md .claude-plugin/plugin.json
git commit -m "docs: document v0.4 restyle skill and bump plugin version"
```

---

### Task 5: Final spec-compliance sweep

**Files:**
- No new files — this task audits the whole repo against spec §7's
  acceptance criteria and fixes any gaps found.

**Interfaces:**
- Consumes: the entire repository state after Tasks 1–4.
- Produces: nothing new by default; only produces fixes if gaps are
  found.

- [ ] **Step 1: Run the acceptance checklist from spec §7**

```bash
# ios-tuist-restyle SKILL.md exists and starts with valid frontmatter
head -1 skills/ios-tuist-restyle/SKILL.md | grep -q '^---$' && echo "OK: SKILL.md frontmatter" || echo "MISSING/BROKEN: SKILL.md"

# restyle-candidate fixture has EXPECTATIONS.md naming both targets
test -f tests/fixtures/restyle-candidate/EXPECTATIONS.md && echo "OK: EXPECTATIONS.md exists" || echo "MISSING: EXPECTATIONS.md"
grep -q "CleanFeature" tests/fixtures/restyle-candidate/EXPECTATIONS.md && grep -q "ExcludeFeature" tests/fixtures/restyle-candidate/EXPECTATIONS.md && echo "OK: names both targets" || echo "MISSING: target detail"

# No new shared reference file was added
test $(ls references | wc -l) -eq 5 && echo "OK: still 5 shared reference files" || echo "UNEXPECTED: reference file count changed"

# CI matrix includes restyle-candidate
grep -q "fixture: restyle-candidate" .github/workflows/validate-fixtures.yml && echo "OK: CI matrix entry" || echo "MISSING: CI matrix entry"

# Plugin version bumped
grep -q '"version": "0.4.0"' .claude-plugin/plugin.json && echo "OK: plugin.json version" || echo "MISSING: plugin.json version bump"

# CHANGELOG has the 0.4.0 entry
grep -q '## \[0.4.0\]' CHANGELOG.md && echo "OK: CHANGELOG 0.4.0 entry" || echo "MISSING: CHANGELOG 0.4.0 entry"

# No invalid "!path" glob negation anywhere in the new skill or fixture
grep -rn '"!' skills/ios-tuist-restyle/ tests/fixtures/restyle-candidate/ && echo "UNEXPECTED: invalid glob negation found" || echo "OK: no invalid glob negation"
```

Expected: every check prints `OK:` — fix any gap found before
proceeding.

- [ ] **Step 2: Confirm local validation evidence stands in for CI**
  (check whether GitHub Actions credit has been restored; if not, local
  validation remains the substitute evidence)

```bash
git status --short
./scripts/validate-fixtures-locally.sh
```

Expected: clean working tree (everything from Tasks 1–4 already
committed), and every fixture in the summary — including
`restyle-candidate` — prints `PASS`.

- [ ] **Step 3: Confirm no leftover `.gitkeep` made obsolete**

`skills/ios-tuist-restyle/references/` stays genuinely empty in v0.4 (no
skill-specific reference content beyond root `references/` was needed) —
its `.gitkeep` remains; do not remove it.

- [ ] **Step 4: Final commit (only if Step 1 found and fixed a gap)**

```bash
git add -A
git commit -m "chore: v0.4 spec-compliance sweep"
```

If Step 1 found no gaps, skip this commit — an empty sweep commit is not
required (same precedent as v0.2 Task 10 and v0.3 Task 5, where no gaps
meant no sweep commit was made).

---

## Post-plan note

This plan covers exactly the v0.4 milestone (spec §1, §7):
`ios-tuist-restyle` scoped to per-target `buildableFolders` conversion
only. Do not push to `origin` as part of executing this plan unless
GitHub Actions credit has been confirmed restored — publishing is a
decision made with the user once the whole plan is done and locally
validated, consistent with how v0.2 and v0.3 were finished.
