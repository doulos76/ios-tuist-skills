# ios-tuist-skills v0.1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the PRD v0.1 milestone of `ios-tuist-skills`: a Claude Code
plugin containing three version-aware iOS/Tuist skills
(`ios-tuist-bootstrap`, `ios-tuist-feature`, `ios-tuist-dependency`), the
shared version-safety/source-of-truth reference layer they all depend on,
and real buildable fixtures validated by CI.

**Architecture:** A flat plugin repo (`skills/`, `references/`,
`templates/`, `examples/`, `tests/fixtures/`) with no application code of
its own — the "product" is markdown (`SKILL.md` + `references/*.md`) plus
real Tuist project fixtures that prove the skills' rules are checkable.
Each skill is self-contained (its own `SKILL.md`); shared judgment
(version safety, source-of-truth precedence, testing/dependency/
modularization policy) lives once in root `references/` and is linked from
every skill, never copy-pasted.

**Tech Stack:** Tuist (version detected per-fixture, not pinned globally),
Xcode, Swift, GitHub Actions (macOS runner), Claude Code plugin format.

**Spec:** `docs/superpowers/specs/2026-09-17-ios-tuist-skills-v0.1-design.md`

## Global Constraints

- Never hard-code a single Tuist version anywhere in `skills/` or
  `references/` content (spec §10 non-goals; PRD §36).
- Every Tuist-modifying skill (`bootstrap`, `feature`, `dependency`) must
  reference `references/version-safety.md` and `references/source-of-truth.md`
  by relative link — never restate their procedures inline (spec §4).
  All non-trivial cross-file references in `SKILL.md` and reference docs
  use relative markdown links (e.g. `[version-safety](../../references/version-safety.md)`),
  never bare filenames or absolute paths.
- Never generate `Config.swift`; use `Tuist.swift` for project-wide config
  (spec §4.2, §10).
- Never create `Workspace.swift` unless explicitly justified per the
  decision rule in `references/source-of-truth.md` (spec §4.2, §10).
- Dependencies always attach to the narrowest target, never app-wide by
  default (spec §4.4, §7).
- Reference files contain principles/decision procedures only — no
  version-pinned Tuist API syntax examples (spec §4, PRD §37).
- Every `SKILL.md` follows the PRD §28 section structure exactly: Purpose,
  Trigger Conditions, Non-Trigger Conditions, Preconditions, Version
  Safety, Workflow, Decision Rules, Validation, Failure Handling, Output
  Contract.
- Fixtures under `tests/fixtures/` must be real, independently buildable
  Tuist projects — not structure-only stand-ins (spec §8).
- MIT license header style is not required per-file; `LICENSE` at repo
  root (already present) covers the whole repo.

---

### Task 1: Plugin manifest and directory skeleton

**Files:**
- Create: `.claude-plugin/plugin.json`
- Create: `skills/ios-tuist-bootstrap/references/.gitkeep`
- Create: `skills/ios-tuist-feature/references/.gitkeep`
- Create: `skills/ios-tuist-dependency/references/.gitkeep`
- Create: `references/.gitkeep` (removed once Tasks 2–4 populate the directory)
- Create: `templates/.gitkeep` (removed once Tasks 8–9 populate the directory)
- Create: `examples/.gitkeep` (removed once Task 15 populates the directory)
- Create: `tests/fixtures/.gitkeep` (removed once Tasks 10–13 populate the directory)

**Interfaces:**
- Consumes: nothing (first task).
- Produces: the directory skeleton every later task writes into. No code
  interfaces — this task only establishes paths.

- [ ] **Step 1: Create the plugin manifest**

Create `.claude-plugin/plugin.json`:

```json
{
  "name": "ios-tuist-skills",
  "description": "Version-aware iOS engineering skills for Tuist-based projects: safe bootstrap, feature addition, and dependency management that detect the project's real Tuist/Xcode/Swift versions and preserve existing conventions.",
  "version": "0.1.0",
  "skills": "./skills"
}
```

- [ ] **Step 2: Create directory skeleton with placeholders**

Run:

```bash
mkdir -p skills/ios-tuist-bootstrap/references
mkdir -p skills/ios-tuist-feature/references
mkdir -p skills/ios-tuist-dependency/references
mkdir -p references
mkdir -p templates
mkdir -p examples
mkdir -p tests/fixtures
touch skills/ios-tuist-bootstrap/references/.gitkeep
touch skills/ios-tuist-feature/references/.gitkeep
touch skills/ios-tuist-dependency/references/.gitkeep
touch references/.gitkeep
touch templates/.gitkeep
touch examples/.gitkeep
touch tests/fixtures/.gitkeep
```

- [ ] **Step 3: Verify the manifest is valid JSON**

Run: `python3 -m json.tool .claude-plugin/plugin.json`
Expected: pretty-printed JSON output, no error.

- [ ] **Step 4: Commit**

```bash
git add .claude-plugin/plugin.json skills references templates examples tests
git commit -m "chore: scaffold plugin manifest and directory skeleton"
```

---

### Task 2: Shared reference — `references/version-safety.md`

**Files:**
- Create: `references/version-safety.md`

**Interfaces:**
- Consumes: nothing.
- Produces: the canonical version-detection procedure and "Tuist Context"
  block format that Tasks 4, 5, 6 (`SKILL.md` files) link to by relative
  path `../../references/version-safety.md`.

- [ ] **Step 1: Write `references/version-safety.md`**

```markdown
# Version Safety

Every skill that reads, generates, or modifies Tuist manifests MUST run
this procedure before writing any Tuist code, and MUST NOT assume the
latest Tuist version.

## Core rule

> Never assume the Tuist version. Establish a version context before
> touching Tuist manifests.

## Detection order

Inspect these sources, in this order, stopping as soon as a pinned
project version is found. Earlier sources win.

1. `mise.toml` / `.mise.toml`
2. `.tool-versions`
3. `Tuist.swift` (its `Tuist` configuration may declare a compatible
   version range)
4. `Tuist/Package.swift`
5. `Package.swift`
6. CI workflow files (e.g. `.github/workflows/*.yml`) that pin or install
   a specific Tuist version
7. Repository scripts (`Scripts/`, `Makefile`, `Brewfile`, bootstrap
   scripts) that install or reference a specific Tuist version
8. Existing manifest syntax (if the syntax used is only valid for a
   version range, that range is evidence)

If none of the above yields a pinned version, there is no project-pinned
version — record that explicitly rather than silently defaulting to
"latest."

Then, always, run the live commands to determine what's actually
available:

- `tuist version`
- `xcodebuild -version`
- `swift --version`

## Authority rule

The **project-pinned** version (found via steps 1–8 above) is
authoritative. The **active** version (from the live commands) is
compared against it — never substituted for it, and never treated as a
reason to change the project's pin.

If no project-pinned version exists (new project, nothing found), the
active version becomes the working version for this session, and the
skill must say so explicitly in its output rather than silently treating
"whatever is installed" as "the correct version."

## Mismatch handling

If the active version differs from the project-pinned version:

- Treat this as a **risk to report**, not a problem to silently fix.
- Do NOT upgrade the pinned version.
- Do NOT downgrade the active toolchain.
- Do NOT adapt generated manifest syntax to the active version instead of
  the pinned version — always generate for the **pinned** version.
- Surface the mismatch clearly in the skill's output (see each skill's
  Output Contract) so the human can decide what to do.
- The only exception: an explicit, user-requested Tuist migration
  workflow (out of scope for `bootstrap`/`feature`/`dependency` — see PRD
  §26). No skill in this repository silently upgrades Tuist.

## The Tuist Context block

Before generating or modifying any manifest, establish and state this
context:

```text
Tuist Context
-------------
Project Tuist:        <pinned version, or "none detected">
Active Tuist:         <version from `tuist version`>
Xcode:                <version from `xcodebuild -version`>
Swift:                <version from `swift --version`>
Platform:              <iOS / macOS / multiplatform, from manifests>
Deployment Target:     <from existing manifests, or user-specified for new projects>
Manifest Style:        <e.g. Target.target(...), sources/resources arrays, buildableFolders>
Folder Integration:    <sources/resources | buildableFolders>
Dependency Integration:<Tuist Package.swift | Xcode-native SwiftPM>
Architecture:          <minimal | feature-modular | clean | tca | custom>
```

Every field must come from actual inspection (file contents, command
output), never assumed. If a field cannot be determined, write
"unknown" — do not guess.

## Why this matters

Tuist's `ProjectDescription` API, manifest syntax, dependency
integration, and generated-project behavior all change across releases.
Generating code for the wrong version produces manifests that fail to
evaluate or produce a broken project graph. This procedure exists so
every skill in this repository fails safe (reports risk) instead of
failing silent (guesses and moves on).
```

- [ ] **Step 2: Verify no version numbers are hard-coded**

Run: `grep -nE 'Tuist [0-9]+\.[0-9]' references/version-safety.md`
Expected: no output (the file must not pin a specific Tuist release).

- [ ] **Step 3: Commit**

```bash
git add references/version-safety.md
git commit -m "docs: add shared version-safety reference"
```

---

### Task 3: Shared reference — `references/source-of-truth.md`

**Files:**
- Create: `references/source-of-truth.md`

**Interfaces:**
- Consumes: nothing.
- Produces: the 10-level precedence order and New/Existing Project Mode
  decision procedure that Tasks 4, 5, 6 link to.

- [ ] **Step 1: Write `references/source-of-truth.md`**

```markdown
# Source of Truth Precedence

When two sources of guidance conflict, resolve using this order. A
lower-priority source must never override a higher-priority source
without explicit, stated justification in the skill's output.

1. Project-pinned Tuist version
2. Existing repository manifests and conventions
3. Version-compatible Tuist documentation / `ProjectDescription` reference
4. Tuist migration and release notes relevant to the detected version
5. Active Xcode and Swift versions
6. Project deployment target and platform constraints
7. Existing project architecture
8. Apple platform guidance
9. Swift / Swift Package Manager guidance
10. This skill repository's reference material (`references/*.md`,
    `templates/`)

`references/*.md` in this repository is deliberately last: it encodes
stable principles, not authoritative facts about any specific project.
When this repository's guidance and the actual project disagree, the
project wins.

## New Project Mode vs Existing Project Mode

Determine which mode applies before making any structural decision.

```text
Does a Tuist project already exist at the target path?
    |
    +-- Yes -> Existing Project Mode
    |
    +-- No  -> New Project Mode
```

### Existing Project Mode

> Existing conventions are more authoritative than generic best practices
> unless the user explicitly requests a migration or architectural change.

Before generating anything:

1. Inspect neighboring manifests.
2. Inspect module/folder layout.
3. Inspect test layout and framework (XCTest vs Swift Testing).
4. Inspect dependency conventions (Tuist-native `Package.swift` vs
   Xcode-native SwiftPM integration).
5. Inspect folder integration strategy (`sources`/`resources` arrays vs
   `buildableFolders`).
6. Reuse existing `ProjectDescriptionHelpers` where they already cover the
   need.
7. Minimize graph changes — the smallest change that accomplishes the
   task wins over a "more correct" larger change.

Example: if the project uses `sources: ["Sources/**"]` throughout, do not
introduce `buildableFolders` into one new feature. That is a migration,
and migrations are only performed when explicitly requested.

### New Project Mode

For a genuinely new repository (no existing Tuist project), current
supported practice may be preferred as the default, subject to the
version actually detected in `version-safety.md`:

- Minimal `Project.swift`.
- `Tuist.swift` only where global configuration is actually needed.
- No `Workspace.swift` unless justified (see below).
- Buildable Folders on toolchains that support them; `sources`/
  `resources` arrays when compatibility requires it.
- Swift Testing for new unit/integration tests when compatible with the
  detected Swift version; XCTest for UI tests.
- Explicit dependencies, scoped to the narrowest target.

## Workspace.swift decision rule

```text
Need custom workspace behavior (custom composition, custom schemes,
explicit multi-project organization not handled by default generation)?
    |
    +-- No  -> omit Workspace.swift
    |
    +-- Yes -> create Workspace.swift, and state the justification
```

## Configuration file rule

Never generate `Config.swift` as a default. Use `Tuist.swift` for
project-wide Tuist configuration. Do not create either file based solely
on an old example found in documentation or training data — verify
against the detected project version first.
```

- [ ] **Step 2: Verify the precedence list matches the spec exactly**

Run: `grep -c '^[0-9]\+\.' references/source-of-truth.md`
Expected: at least `10` (the 10-level list; the file may contain other
numbered lists too, so treat this as a sanity floor, not an exact match).

- [ ] **Step 3: Commit**

```bash
git add references/source-of-truth.md
git commit -m "docs: add shared source-of-truth reference"
```

---

### Task 4: Shared references — testing, dependencies, modularization

**Files:**
- Create: `references/testing.md`
- Create: `references/dependencies.md`
- Create: `references/modularization.md`

**Interfaces:**
- Consumes: nothing.
- Produces: policy documents linked from `ios-tuist-feature/SKILL.md`
  (testing, dependencies) and `ios-tuist-dependency/SKILL.md`
  (dependencies, modularization referenced for linkage decisions).

- [ ] **Step 1: Write `references/testing.md`**

```markdown
# Testing Policy

## Framework choice

- Prefer **Swift Testing** for new unit and integration tests when the
  detected Swift/Xcode version supports it (check
  `version-safety.md`'s Tuist Context first).
- If the repository already standardizes on **XCTest**, preserve XCTest
  for new tests in that area. Do not introduce Swift Testing into an
  XCTest-only codebase as a side effect of an unrelated task.
- Use XCTest / XCUIAutomation for UI tests regardless of the unit-test
  framework choice — Swift Testing does not replace XCUI for UI
  automation.
- Never migrate existing test infrastructure (XCTest -> Swift Testing or
  vice versa) as a side effect of another task. A test-framework
  migration is only performed when explicitly requested.

## What to generate

Generate tests only when they verify meaningful behavior introduced by
the current change. Do not generate placeholder tests such as:

```swift
@Test func example() {
    #expect(true)
}
```

The one exception: an explicitly-labeled minimal smoke test inside a
*template* (see `templates/`), whose purpose is to prove the generated
project builds and runs at least one test — label it clearly as a
template smoke test in a comment so it is never mistaken for real
coverage.

## Scope

When adding a feature, test the feature's own new behavior. Do not
expand test scope to unrelated existing code as part of the same change.
```

- [ ] **Step 2: Write `references/dependencies.md`**

```markdown
# Dependency Policy

## Classification

Before integrating any dependency, classify it as one of:

- Swift package library
- Swift package macro
- Build tool plugin
- Binary framework
- XCFramework
- Local package
- Local Tuist project
- System framework

The integration strategy may differ by category — a macro or build tool
plugin has different Tuist wiring than a plain library, and a binary
framework/XCFramework has different wiring than a Swift package. Confirm
the category from the dependency's own documentation/manifest, not by
assumption.

## Narrowest-target rule

A dependency must be attached to the narrowest target that actually
requires it — never the app target by default, and never every target in
a workspace "to be safe."

Bad:

```text
App
 └── Kingfisher
```

when only `ProfileFeature` imports Kingfisher.

Correct:

```text
ProfileFeature
 └── Kingfisher
```

If a dependency request is ambiguous about which target it belongs to,
resolve it from actual or clearly-intended `import` usage, preferring the
narrowest valid target — do not default to the app target to avoid the
question.

## Integration mechanism preservation

Do not assume every dependency should use exactly one Tuist integration
mechanism. Before adding a dependency, inspect:

- The repository's current convention (Tuist-native `Tuist/Package.swift`
  vs Xcode-native SwiftPM integration via `.external`/direct
  `.package(url:)` references, depending on what the project already
  uses).
- The dependency's type (from the classification above) and any
  plugin/macro/build-tool-plugin constraints it imposes.
- Package resolution and CI behavior already in place.

Do not convert an existing project from one integration mechanism to
another as a side effect of adding a dependency. That conversion is only
performed when explicitly requested.

## Version constraints

Preserve existing version constraint style (exact, range, branch, commit)
unless the task explicitly requires changing it. When adding a new
dependency with no existing convention to match, prefer the narrowest
constraint that satisfies the stated requirement.
```

- [ ] **Step 3: Write `references/modularization.md`**

```markdown
# Modularization Policy

## Core rule

Do not create a module simply because a feature exists. Modularization
has real costs (build graph complexity, boilerplate, indirection) and
must be justified by a concrete benefit.

## Pre-module checklist

Before creating, splitting, or merging a module, inspect all of:

- Ownership boundary — does this code have a clear, distinct owner/team
  or responsibility?
- Dependency direction — would the module introduce or resolve a
  direction problem in the graph?
- Reusability — is this code actually reused, or reusable in a concrete,
  near-term sense (not hypothetically)?
- Compile-time isolation benefit — does isolating this code meaningfully
  reduce incremental build time for other targets?
- Test boundary — does this code have tests that benefit from being
  isolated?
- Resource ownership — does this code own resources (assets, strings,
  storyboards) that are cleanly separable?
- Public API surface — is there a small, stable public surface this
  module would expose?
- Cyclic-dependency risk — would this split introduce a cycle, or resolve
  one?
- Build cost — does the split's ongoing build/maintenance cost outweigh
  its benefit?

Reject modularization proposed only because "this feels like it should
be its own module" with no concrete answer to the above.

## Linkage is a graph decision, not a default

Never make `.staticFramework`, `.framework`, `.staticLibrary`, or
`.dynamicLibrary` a universal default across a project. Before choosing
linkage for a target, inspect:

- The existing project's linkage convention.
- The transitive dependency graph (duplicate-symbol risk grows with
  static linkage across many targets that share dependencies).
- Resources owned by the target.
- App extension / widget extension constraints, if any.
- External binary requirements.
- Build iteration impact (incremental build time).
- App startup behavior.
- Xcode Previews / debug-build behavior.

Document which of these drove the linkage choice in the skill's output
when linkage is set explicitly.
```

- [ ] **Step 4: Verify no placeholder tests appear as real examples**

Run: `grep -n '#expect(true)' references/testing.md`
Expected: exactly one match, inside the explicitly-labeled template smoke
test example — confirms the placeholder pattern is documented as an
exception, not left dangling as unexplained.

- [ ] **Step 5: Commit**

```bash
git add references/testing.md references/dependencies.md references/modularization.md
git commit -m "docs: add testing, dependency, and modularization references"
```

---

### Task 5: `ios-tuist-bootstrap` skill

**Files:**
- Create: `skills/ios-tuist-bootstrap/SKILL.md`

**Interfaces:**
- Consumes: `references/version-safety.md`, `references/source-of-truth.md`
  (relative links), `templates/minimal/`, `templates/feature-modular/`,
  `templates/clean/` (created in Tasks 8–9 — this task may reference their
  paths even though Tasks 8–9 run after; the plan's dependency order is
  reference-docs-and-skills-first, then templates, so note the forward
  reference explicitly in the file as "see `templates/<profile>/`").
- Produces: the bootstrap workflow other tasks (fixtures, README) point to
  by name `ios-tuist-bootstrap`.

- [ ] **Step 1: Write `skills/ios-tuist-bootstrap/SKILL.md`**

```markdown
---
name: ios-tuist-bootstrap
description: >
  Creates a new iOS project using Tuist, selecting an architecture
  profile, detecting the actual local Tuist/Xcode/Swift versions,
  generating only the minimum required manifests, and validating the
  result through tuist generate, build, and test before reporting
  completion.
---

# Core Rule

Do not generate a single manifest before establishing a Tuist Context
(see [version-safety](../../references/version-safety.md)) and confirming
this is genuinely a new project (no existing `Project.swift`,
`Tuist.swift`, or `Workspace.swift` at the target path).

## Purpose

Bootstrap a new Tuist-based iOS project: minimal structure, a chosen
architecture profile, and a validated (generate/build/test) result — not
just a pile of generated files.

## Trigger Conditions

- "Create a new iOS app using Tuist"
- "Bootstrap a Tuist project for [app]"
- "Start a new SwiftUI/UIKit project with Tuist, [architecture] structure"

## Non-Trigger Conditions

- The target directory already contains a Tuist project
  (`Project.swift`/`Tuist.swift`/`Workspace.swift` present) — that is
  `ios-tuist-feature`'s job, not this skill's.
- The request is only to add a dependency to an existing project — that
  is `ios-tuist-dependency`.

## Preconditions

1. Confirm no `Project.swift`, `Tuist.swift`, or `Workspace.swift` exists
   at the target path. If one does, stop and hand off to
   `ios-tuist-feature` reasoning instead.
2. Environment inspection: run the live-command portion of
   [version-safety](../../references/version-safety.md) (`tuist version`,
   `xcodebuild -version`, `swift --version`) to know what's actually
   available to generate/build/test with.

## Version Safety

Apply [version-safety](../../references/version-safety.md) in full.
Because no project-pinned version exists yet (this is a new project), the
active local Tuist version becomes the working version for this session —
state that explicitly in the Output Contract rather than silently
treating "whatever is installed" as correct. If the active version seems
unusually old or new for the user's stated needs, surface that as a note,
not a blocker.

Also apply [source-of-truth](../../references/source-of-truth.md)'s
**New Project Mode** procedure — current supported practice is the
default here, not existing-convention preservation (there is no existing
convention yet).

## Workflow

1. **Environment** — establish the Tuist Context block (from
   version-safety.md). Note deployment-target defaults and package
   manager availability.
2. **Requirements** — determine: app name, bundle identifier, platform,
   deployment target, SwiftUI vs UIKit, architecture profile, testing
   strategy, dependencies, localization/resource needs. Only ask the user
   about fields not already answered by their request. Do not ask
   questions whose answers are obvious from context (e.g. don't ask
   platform if the user said "iOS app").
3. **Structure** — generate the minimum required structure:
   - `Tuist.swift` for project-wide configuration, only if project-wide
     configuration is actually needed.
   - Never `Config.swift` (see source-of-truth.md's configuration rule).
   - `Workspace.swift` only if justified per source-of-truth.md's decision
     rule — state the justification if created.
4. **Architecture** — select one profile based on the user's request, or
   `minimal` if unspecified:
   - `minimal` — `templates/minimal/`
   - `feature-modular` — `templates/feature-modular/`
   - `clean` — `templates/clean/`
   - `tca` / `custom` — no dedicated template in v0.1; use `minimal` as
     the structural base and apply the user's explicit direction on top.
     Never invent a TCA-specific structure without the user having
     described what they want — ask if unclear.
5. **Generation** — write manifests using APIs verified compatible with
   the Tuist Context established in step 1. When in doubt about current
   `ProjectDescription` syntax for the detected version, consult Tuist's
   own official docs/MCP tooling if available rather than trusting a
   possibly-stale remembered example.
6. **Validation** — see Validation below. Run it for real; do not skip
   because "the files look right."

## Decision Rules

- Prefer Buildable Folders over `sources`/`resources` arrays only when
  the detected Xcode/Tuist combination supports them (this is New Project
  Mode, so this preference applies by default — see source-of-truth.md).
- Create `ProjectDescriptionHelpers` only when behavior is repeated,
  naming conventions must be enforced, target creation must be
  standardized, settings are shared, or bundle identifiers follow a
  project convention. Do not create a helper solely because one
  expression is long.
- Never force SwiftUI, UIKit, or any specific architecture beyond what
  the user requested or the chosen profile implies.

## Validation

Required before declaring the task complete:

1. `tuist install` (or equivalent dependency resolution) if the project
   has any dependencies.
2. `tuist generate` — must succeed.
3. Build the generated app target — must succeed.
4. Run the generated test target(s) — must pass.

Report the actual command output/exit status for each step. "Files were
created" is never sufficient evidence of success on its own.

## Failure Handling

Apply Evidence-Driven Debugging:

1. **Observed facts** — record: Tuist version (project + active), Xcode
   version, Swift version, the exact failing command, the exact error
   text, the affected manifest file.
2. **Hypotheses** — when the cause isn't immediately obvious from the
   error, generate at least two plausible hypotheses (e.g. "H1: active
   Tuist version doesn't support this ProjectDescription API"; "H2: the
   deployment target is incompatible with a dependency's minimum OS
   version").
3. **Contradiction search** — try to disprove the leading hypothesis
   before changing code (e.g. check the Tuist changelog/docs for the
   active version before assuming an API is unsupported).
4. **Minimal change** — apply the smallest change that explains the
   observed failure. Do not make speculative unrelated changes.

## Output Contract

Report, in this order:

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

Example:

```text
Tuist: 4.x.y (active; no project pin existed before this run)
Xcode: 16.x
Swift: 6.x

Changed:
- created MyApp/ (minimal architecture profile)
- created App target (SwiftUI)
- created MyAppTests target (Swift Testing)

Validation:
- tuist generate: success
- app build: success
- MyAppTests: success

Not changed:
- N/A (new project)

Risks / Follow-up:
- No Workspace.swift created (not justified for a single-app project)
```
```

- [ ] **Step 2: Verify frontmatter is valid and links resolve to files that will exist**

Run:

```bash
python3 -c "
import re
text = open('skills/ios-tuist-bootstrap/SKILL.md').read()
assert text.startswith('---\nname: ios-tuist-bootstrap\n'), 'frontmatter missing or malformed'
assert '../../references/version-safety.md' in text
assert '../../references/source-of-truth.md' in text
print('OK')
"
```

Expected: `OK`.

- [ ] **Step 3: Commit**

```bash
git add skills/ios-tuist-bootstrap/SKILL.md
git commit -m "docs: add ios-tuist-bootstrap skill"
```

---

### Task 6: `ios-tuist-feature` skill

**Files:**
- Create: `skills/ios-tuist-feature/SKILL.md`

**Interfaces:**
- Consumes: `references/version-safety.md`, `references/source-of-truth.md`,
  `references/testing.md`, `references/dependencies.md`.
- Produces: the feature-addition workflow referenced by
  `tests/fixtures/legacy-tuist/EXPECTATIONS.md` (Task 11).

- [ ] **Step 1: Write `skills/ios-tuist-feature/SKILL.md`**

```markdown
---
name: ios-tuist-feature
description: >
  Adds or modifies features in an existing Tuist-based iOS project
  while preserving project architecture, dependency conventions,
  Tuist version compatibility, and validation requirements.
---

# Core Rule

Do not create a feature before inspecting the project's Tuist version,
neighboring feature structure, target graph, and test conventions. See
[version-safety](../../references/version-safety.md) and
[source-of-truth](../../references/source-of-truth.md).

## Purpose

Add a feature to an existing Tuist project while preserving its existing
architecture, folder layout, dependency conventions, and test style —
never introducing a new pattern inside a single feature.

## Trigger Conditions

- "Add [Feature] to this project" (e.g. "Add LoginFeature")
- "Create a new screen/module for [X]" in a repository that already has a
  Tuist project.

## Non-Trigger Conditions

- No existing Tuist project at the target path — that's
  `ios-tuist-bootstrap`.
- The request is purely about adding/removing/moving a dependency with no
  new feature code — that's `ios-tuist-dependency` (though this skill may
  hand off to that one's reasoning for the dependency-wiring step of a
  larger feature request).

## Preconditions

An existing Tuist project must be present and readable at the target
path (`Project.swift`/`Tuist.swift` present).

## Version Safety

Apply [version-safety](../../references/version-safety.md) in full. This
is **Existing Project Mode**
(see [source-of-truth](../../references/source-of-truth.md)): the
project-pinned version is authoritative. If the active version differs
from the pinned version, report the mismatch as a risk in the Output
Contract and generate manifest syntax for the **pinned** version, not the
active one.

## Workflow

1. **Inspect neighboring features** before writing anything:
   - Target definitions (naming, structure) of at least one existing
     feature.
   - Dependency declarations on those targets.
   - File/folder organization convention.
   - Test style in use (XCTest vs Swift Testing — see
     [testing](../../references/testing.md)).
   - Whether a Tuist scaffold/template already exists for features in
     this repo (check for a `Tuist/Templates/` or similar directory).
   - Target naming convention (e.g. `XFeature`, `XKit`, `Feature.X`).
   - Resource organization (where assets/strings live per feature).
2. **Decide: scaffold or minimal files.**
   ```text
   Existing scaffold found for this repo's feature pattern?
           |
          Yes -> reuse the scaffold as-is
           |
           No
           |
           Is this the Nth time a near-identical structure would be
           hand-written (i.e. is repetition already established, not
           merely anticipated)?
                   |
                  Yes -> creating a new scaffold may be justified;
                         state the justification explicitly
                  No  -> create only the minimum files needed for this
                         one feature
   ```
3. **Connect dependencies minimally** — attach only what the new feature
   actually needs, to the new feature's own target, following
   [dependencies](../../references/dependencies.md)'s narrowest-target
   rule. Do not add dependencies the feature doesn't use "for
   consistency."
4. **Validate** — generate, then build/test only the affected target(s),
   not the whole repository, unless the change is graph-wide (e.g. it
   touches a shared module every target depends on).

## Decision Rules

- Never introduce a new architecture style inside one feature (e.g. don't
  bring MVVM into a repo that is consistently VIPER, even if MVVM is "the
  skill's opinion" — it has none).
- Never migrate an unrelated existing convention as a side effect. If the
  repo uses `sources: ["Sources/**"]` everywhere, the new feature also
  uses `sources: ["Sources/**"]` — do not switch that one feature to
  `buildableFolders`.
- If the user explicitly asks for an architectural change alongside the
  feature, treat that as two things: the architectural change is a
  separate, explicit decision to confirm before proceeding, not something
  to fold in silently.

## Validation

Required before declaring the task complete:

1. `tuist generate` — must succeed.
2. The new feature target and its immediate consumer(s) (e.g. the app
   target that will use it) build successfully.
3. The feature's own tests run and pass, using the repo's existing test
   framework convention.

## Failure Handling

Same Evidence-Driven Debugging procedure as `ios-tuist-bootstrap`
(Observed Facts -> Hypotheses -> Contradiction Search -> Minimal Change).
First hypothesis to consider here specifically: a version mismatch
between the project pin and the active toolchain causing a
`ProjectDescription` API used by neighboring features to fail when
touched.

## Output Contract

Same structure as `ios-tuist-bootstrap`:

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

Example:

```text
Tuist: 4.x.y (project-pinned via Tuist.swift)
Active Tuist: 4.x.y (matches)
Xcode: 16.x
Swift: 6.x

Changed:
- added LoginFeature target (matches existing feature-module pattern)
- added dependency on SharedUI (existing shared target)
- added LoginFeatureTests (Swift Testing, matching repo convention)

Validation:
- tuist generate: success
- App build (consumer of LoginFeature): success
- LoginFeatureTests: success

Not changed:
- existing folder integration strategy (sources arrays, unchanged)
- no other feature targets touched
```
```

- [ ] **Step 2: Verify all four shared reference links are present**

Run:

```bash
grep -c '\.\./\.\./references/' skills/ios-tuist-feature/SKILL.md
```

Expected: `4` or more (version-safety, source-of-truth, testing,
dependencies each linked at least once).

- [ ] **Step 3: Commit**

```bash
git add skills/ios-tuist-feature/SKILL.md
git commit -m "docs: add ios-tuist-feature skill"
```

---

### Task 7: `ios-tuist-dependency` skill

**Files:**
- Create: `skills/ios-tuist-dependency/SKILL.md`

**Interfaces:**
- Consumes: `references/version-safety.md`, `references/source-of-truth.md`,
  `references/dependencies.md`.
- Produces: the dependency-wiring workflow referenced by
  `tests/fixtures/modular/EXPECTATIONS.md` (Task 13).

- [ ] **Step 1: Write `skills/ios-tuist-dependency/SKILL.md`**

```markdown
---
name: ios-tuist-dependency
description: >
  Adds, removes, or relocates Swift Package, binary, or local
  dependencies in a Tuist-based iOS project using the correct
  Tuist integration approach, scoped to the narrowest target that
  actually requires the dependency.
---

# Core Rule

Never attach a dependency to a wider target than necessary. Identify the
actual consumer target before writing any manifest change. See
[dependencies](../../references/dependencies.md).

## Purpose

Add, remove, or relocate a dependency using the Tuist integration
approach already established in the project (or the correct one for a
new dependency type), attached only to the target(s) that need it.

## Trigger Conditions

- "Add [Package] to [Target]"
- "Remove [Package] from [Target]"
- "Move [Package] from [Target A] to [Target B]"
- "Add [Package] only to [Target]" (narrowest-target framing is often
  explicit — always honor it)

## Non-Trigger Conditions

- The request requires creating new feature scaffolding beyond wiring the
  dependency in — the feature-creation part belongs to
  `ios-tuist-feature`; this skill handles the dependency-attachment
  portion once the target exists.
- No existing Tuist project — `ios-tuist-bootstrap` territory (a brand
  new project's initial dependencies are chosen during bootstrap, not
  here).

## Preconditions

The consumer target must be identifiable — either stated explicitly in
the request, or inferable from actual/clearly-intended `import` usage in
the codebase. If genuinely ambiguous, ask rather than guessing widely.

## Version Safety

Apply [version-safety](../../references/version-safety.md) in full. The
project's pinned Tuist version determines which dependency-declaration
syntax is valid (Tuist-native `Tuist/Package.swift` integration vs
Xcode-native SwiftPM integration). Generate for the pinned version.

## Workflow

1. **Identify the consumer target.** Use the explicit target from the
   request if given. If ambiguous, search actual/intended `import`
   statements and prefer the narrowest valid target — never default to
   the app target to sidestep the question.
2. **Check the current dependency integration mechanism** already used in
   this repository (inspect existing `Tuist/Package.swift` or Xcode
   project SwiftPM references).
3. **Classify the dependency** using
   [dependencies](../../references/dependencies.md)'s taxonomy (Swift
   package library, macro, build tool plugin, binary framework,
   XCFramework, local package, local Tuist project, system framework).
4. **Determine the compatible declaration approach** for the detected
   Tuist version and the existing integration mechanism. Do not convert
   the project from one integration mechanism to another unless the task
   explicitly requires it.
5. **Attach to the identified target only.** Never widen to the app
   target or to unrelated targets "to be safe."
6. **Resolve/install** the dependency (e.g. `tuist install`).
7. **Generate** (`tuist generate`).
8. **Build** the affected target(s) and the app.

## Decision Rules

- The narrowest-target rule is non-negotiable: a dependency only used by
  `ProfileFeature` is attached to `ProfileFeature`, never to `App`, even
  if `App` transitively depends on `ProfileFeature` and "it would still
  work."
- Do not convert an existing SPM integration mechanism unless the task
  explicitly requires it.
- Preserve existing version-constraint style unless the task requires
  changing it (see dependencies.md).

## Validation

Required before declaring the task complete:

1. The dependency resolves successfully (`tuist install` or equivalent).
2. `tuist generate` — must succeed.
3. The consumer target and the app build successfully.

## Failure Handling

Same Evidence-Driven Debugging procedure as the other two skills.
Additional first hypothesis to consider here specifically: a version
constraint conflict between the newly added dependency and an existing
one in the graph.

## Output Contract

Same structure as the other two skills, with "Dependency Changes"
populated with specifics:

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

Example:

```text
Tuist: 4.x.y (project-pinned)
Active Tuist: 4.x.y (matches)

Changed:
- attached Kingfisher (Swift package library) to ProfileFeature target only

Dependency Changes:
- Package: Kingfisher
- Version constraint: from: "7.0.0" (matches repo's existing constraint style)
- Attached to: ProfileFeature (only)
- Integration mechanism: Tuist/Package.swift (existing repo convention, unchanged)

Validation:
- tuist install: success
- tuist generate: success
- ProfileFeature build: success
- App build: success

Not changed:
- App target's own dependency list
- Any other feature target
```
```

- [ ] **Step 2: Verify narrowest-target rule text is present**

Run: `grep -n 'narrowest' skills/ios-tuist-dependency/SKILL.md`
Expected: at least 2 matches.

- [ ] **Step 3: Commit**

```bash
git add skills/ios-tuist-dependency/SKILL.md
git commit -m "docs: add ios-tuist-dependency skill"
```

---

### Task 8: `templates/minimal/` — working Tuist scaffold

**Files:**
- Create: `templates/minimal/Tuist.swift`
- Create: `templates/minimal/Project.swift`
- Create: `templates/minimal/App/Sources/AppDelegate.swift` (or
  `App.swift` for a SwiftUI `@main` entry point — see Step 1)
- Create: `templates/minimal/App/Tests/AppTests.swift`
- Create: `templates/minimal/README.md`

**Interfaces:**
- Consumes: nothing (this is the leaf artifact `ios-tuist-bootstrap`
  points to).
- Produces: a copyable scaffold. No code interfaces — the "interface" is
  the directory shape itself, documented in `templates/minimal/README.md`
  for whoever (Codex, a future skill run) copies from it.

**Note on tooling:** This task requires an actual Tuist installation to
verify. If Tuist is not installed in the environment executing this plan,
install it first (e.g. `curl -Ls https://install.tuist.io | bash`, or
via `mise install tuist` if `mise` is already the repo's toolchain
manager — check what Task 2's detection order would find; if nothing is
pinned yet, installing the latest stable Tuist for authoring this
template is acceptable since the template is deliberately kept
version-agnostic in its prose but must be written against *some* real,
working syntax).

- [ ] **Step 1: Scaffold the template with Tuist itself**

Run, from `templates/minimal/`:

```bash
mkdir -p templates/minimal
cd templates/minimal
tuist version > TUIST_VERSION_USED_TO_AUTHOR.txt
```

Record the output — this file documents which Tuist version the template
was authored/verified against (not a pin for consumers, just provenance
for maintainers).

- [ ] **Step 2: Write `templates/minimal/Tuist.swift`**

Author this using the current Tuist Context established in Step 1 —
consult `tuist --help` / official Tuist documentation for the exact
`Tuist.swift` shape valid for the installed version rather than guessing.
At minimum it must declare the project as using Tuist with no
unnecessary global configuration (only add config that's actually
needed — none, for a minimal single-app project).

- [ ] **Step 3: Write `templates/minimal/Project.swift`**

Define a single app target named `App` (a SwiftUI app,
`@main`-based entry point) and a single test target `AppTests`
(Swift Testing), targeting the latest-supported-by-installed-Xcode iOS
deployment target. Use whichever folder-integration mechanism
(`sources` arrays vs `buildableFolders`) the installed Tuist/Xcode
combination supports and prefers for new projects, per
`references/source-of-truth.md`'s New Project Mode guidance. Do not
create a `Workspace.swift` — a single-app minimal project does not
justify one.

- [ ] **Step 4: Write the app source and one real test**

`App/Sources/` gets a minimal SwiftUI `App` struct and a trivial
`ContentView` (e.g. displaying "Hello, Tuist"). `App/Tests/AppTests.swift`
gets one real Swift Testing test that verifies something meaningful about
the app target compiling and a basic piece of logic — not a placeholder
`#expect(true)`. If there's no app logic yet to test meaningfully, test
that `ContentView`'s body can be constructed without crashing, which is
the smallest non-vacuous smoke check available for a brand-new SwiftUI
app; label it in a one-line comment as `// template smoke test` per
`references/testing.md`'s exception clause.

- [ ] **Step 5: Validate the template actually builds**

Run, from `templates/minimal/`:

```bash
tuist install
tuist generate --no-open
xcodebuild -workspace App.xcworkspace -scheme App -destination 'generic/platform=iOS Simulator' build
xcodebuild test -workspace App.xcworkspace -scheme App -destination 'platform=iOS Simulator,name=iPhone 16'
```

(Adjust `-scheme`/workspace name to whatever `tuist generate` actually
produced if it differs — record the real generated names in
`templates/minimal/README.md`.)

Expected: all four commands exit 0.

- [ ] **Step 6: Write `templates/minimal/README.md`**

Document: what this template contains, the exact Tuist version it was
authored/verified against (from Step 1's recorded output), and that
`ios-tuist-bootstrap` copies from this structure rather than generating
it from scratch every time — keeping bootstrap output deterministic.

- [ ] **Step 7: Clean generated artifacts before committing**

Run: `cd templates/minimal && rm -rf *.xcworkspace *.xcodeproj .build`

(These are regenerated by `tuist generate`/`tuist install` and are
already covered by the repo's `.gitignore`; confirm with
`git status --short templates/minimal` that none remain staged.)

- [ ] **Step 8: Commit**

```bash
git add templates/minimal
git commit -m "feat: add minimal architecture template"
```

---

### Task 9: `templates/feature-modular/` and `templates/clean/` — working Tuist scaffolds

**Files:**
- Create: `templates/feature-modular/Tuist.swift`
- Create: `templates/feature-modular/Project.swift`
- Create: `templates/feature-modular/App/Sources/*`, `App/Tests/*`
- Create: `templates/feature-modular/ExampleFeature/Sources/*`,
  `ExampleFeature/Tests/*`
- Create: `templates/feature-modular/README.md`
- Create: `templates/clean/Tuist.swift`
- Create: `templates/clean/Project.swift`
- Create: `templates/clean/App/Sources/*` (Presentation/Domain/Data split)
- Create: `templates/clean/App/Tests/*`
- Create: `templates/clean/README.md`

**Interfaces:**
- Consumes: same Tuist Context provenance approach as Task 8.
- Produces: two more copyable scaffolds referenced by
  `ios-tuist-bootstrap/SKILL.md`'s Architecture step.

- [ ] **Step 1: Scaffold `templates/feature-modular/`**

Two targets minimum beyond the app: `App` (thin, depends on
`ExampleFeature`) and `ExampleFeature` (a self-contained feature module
with its own `Sources`/`Tests`), demonstrating the dependency-direction
convention (`App -> ExampleFeature`, never the reverse). Follow the same
steps as Task 8 (author `Tuist.swift`/`Project.swift` against the
installed Tuist version, write real source + one real test per target, no
`Workspace.swift` unless justified — a two-target single-app project
still doesn't justify one).

Validate:

```bash
cd templates/feature-modular
tuist install
tuist generate --no-open
xcodebuild -workspace App.xcworkspace -scheme App -destination 'generic/platform=iOS Simulator' build
xcodebuild test -workspace App.xcworkspace -scheme App -destination 'platform=iOS Simulator,name=iPhone 16'
```

Expected: all commands exit 0.

- [ ] **Step 2: Scaffold `templates/clean/`**

Same app-level shape as feature-modular, but organize `App/Sources/` into
`Presentation/`, `Domain/`, `Data/` subfolders (folder-level separation is
sufficient for a v0.1 minimal Clean Architecture template — do not
over-build this into separate Tuist targets per layer unless that's
already how `feature-modular` works, since PRD §17 treats architecture as
a template profile, not a mandate to maximize target count). Include one
real test per layer that has testable logic (at minimum, the Domain
layer).

Validate the same way as Step 1, adjusted for `templates/clean/`.

- [ ] **Step 3: Write both README.md files**

Same content shape as `templates/minimal/README.md` — what's included,
Tuist version verified against, what `ios-tuist-bootstrap` uses this for.

- [ ] **Step 4: Clean generated artifacts and verify gitignore coverage**

```bash
cd templates/feature-modular && rm -rf *.xcworkspace *.xcodeproj .build && cd ../..
cd templates/clean && rm -rf *.xcworkspace *.xcodeproj .build && cd ../..
git status --short templates/feature-modular templates/clean
```

Expected: no `.xcworkspace`/`.xcodeproj`/`.build` entries listed.

- [ ] **Step 5: Commit**

```bash
git add templates/feature-modular templates/clean
git commit -m "feat: add feature-modular and clean architecture templates"
```

---

### Task 10: Fixture — `tests/fixtures/new-project/`

**Files:**
- Create: `tests/fixtures/new-project/EXPECTATIONS.md`
- Create: `tests/fixtures/new-project/.gitkeep` (the fixture directory
  itself starts empty on disk — `ios-tuist-bootstrap` writes into it
  when exercised; only the expectations doc is committed content)

**Interfaces:**
- Consumes: nothing directly (documents expected behavior of
  `ios-tuist-bootstrap`, already written in Task 5).
- Produces: the Scenario A check described in spec §8.1/§11.

- [ ] **Step 1: Write `tests/fixtures/new-project/EXPECTATIONS.md`**

```markdown
# Fixture: new-project

**Exercises:** `ios-tuist-bootstrap` (PRD §40 Scenario A)

## Starting state

This directory is empty (aside from this file and `.gitkeep`). No
`Project.swift`, `Tuist.swift`, or `Workspace.swift` exists here.

## Prompt to exercise this fixture

> Create a new SwiftUI iOS app using Tuist with a feature-modular
> structure.

## Expected behavior

- The environment is inspected (Tuist Context established) before any
  file is written.
- The generated structure uses the `feature-modular` profile from
  `templates/feature-modular/`.
- No `Workspace.swift` is created unless a real justification is stated
  (a single new app with one or two feature modules does not need one).
- No `Config.swift` is created anywhere.
- `tuist generate` succeeds.
- The app builds.
- Tests run and pass.
- The Output Contract report includes a populated Version Context and
  Validation Performed section with real command results, not assertions
  without evidence.

## What must NOT happen

- The skill must not assume a specific Tuist version without running the
  detection procedure in `references/version-safety.md`.
- The skill must not silently install/upgrade Tuist to a different
  version.
- The skill must not skip validation and still report success.

## How to check

After running the skill against this fixture:

1. Read the skill's Output Contract report against the checklist above.
2. `cd tests/fixtures/new-project && tuist generate --no-open && xcodebuild -workspace *.xcworkspace -scheme * build` —
   confirm this independently succeeds (don't just trust the skill's own
   report).
3. Reset the fixture to its empty starting state afterward (`git clean
   -fdx tests/fixtures/new-project` from the repo root) so the fixture
   stays reusable for future runs and CI.
```

- [ ] **Step 2: Create the empty starting-state marker**

```bash
mkdir -p tests/fixtures/new-project
touch tests/fixtures/new-project/.gitkeep
```

- [ ] **Step 3: Commit**

```bash
git add tests/fixtures/new-project
git commit -m "test: add new-project fixture expectations"
```

---

### Task 11: Fixture — `tests/fixtures/legacy-tuist/`

**Files:**
- Create: `tests/fixtures/legacy-tuist/Tuist.swift`
- Create: `tests/fixtures/legacy-tuist/Project.swift`
- Create: `tests/fixtures/legacy-tuist/App/Sources/*`,
  `App/Tests/*`
- Create: `tests/fixtures/legacy-tuist/EXPECTATIONS.md`

**Interfaces:**
- Consumes: same real-Tuist-install validation approach as Task 8.
- Produces: the Scenario B check described in spec §8.1/§11.

- [ ] **Step 1: Author a real, older-style Tuist project**

This fixture must use `sources: ["Sources/**"]` / `resources:
["Resources/**"]` array-based folder integration (explicitly NOT
`buildableFolders`), and a single-target app structure representative of
a project that predates Buildable Folders adoption. It must be a real,
currently-buildable project with the installed Tuist version (the
"legacy" quality is about its *conventions*, not about using a broken or
unbuildable manifest).

- [ ] **Step 2: Validate it builds as-is**

```bash
cd tests/fixtures/legacy-tuist
tuist install
tuist generate --no-open
xcodebuild -workspace *.xcworkspace -scheme App build
xcodebuild test -workspace *.xcworkspace -scheme App -destination 'platform=iOS Simulator,name=iPhone 16'
rm -rf *.xcworkspace *.xcodeproj .build
```

Expected: build and test both succeed before any skill touches it.

- [ ] **Step 3: Write `tests/fixtures/legacy-tuist/EXPECTATIONS.md`**

```markdown
# Fixture: legacy-tuist

**Exercises:** `ios-tuist-feature` (PRD §40 Scenario B)

## Starting state

A real, buildable Tuist project using `sources: ["Sources/**"]` /
`resources: ["Resources/**"]` array-based folder integration — explicitly
NOT Buildable Folders. Single `App` target with tests.

## Prompt to exercise this fixture

> Add LoginFeature.

## Expected behavior

- The pinned Tuist version is detected from this project's own
  `Tuist.swift`/config before any manifest is touched.
- The existing `sources`/`resources` array convention is preserved for
  the new `LoginFeature` code — it must NOT be switched to
  `buildableFolders`, even though that might be "more modern."
- No implicit modernization of any kind occurs.
- Existing dependency conventions (however this fixture declares its
  dependencies, if any) are preserved.
- `tuist generate` succeeds after the change.
- The app (now depending on LoginFeature, if that's how the feature was
  wired) and LoginFeature's own tests build and pass.

## What must NOT happen

- Switching `App`'s or `LoginFeature`'s folder integration to
  `buildableFolders`.
- Changing the Tuist version pin.
- Introducing a new architecture pattern not already present in this
  fixture.

## How to check

1. Read the skill's Output Contract — confirm "Not changed" lists the
   preserved folder-integration convention explicitly.
2. `git diff` the fixture directory — confirm `App`'s existing manifest
   only gained the minimal wiring needed to depend on LoginFeature (if
   any), with no unrelated formatting/style changes.
3. Independently run `tuist generate && xcodebuild build && xcodebuild
   test` against the result.
4. Reset with `git checkout -- tests/fixtures/legacy-tuist && git clean
   -fdx tests/fixtures/legacy-tuist` to restore the fixture for reuse.
```

- [ ] **Step 4: Commit**

```bash
git add tests/fixtures/legacy-tuist
git commit -m "test: add legacy-tuist fixture (array-based folder integration)"
```

---

### Task 12: Fixture — `tests/fixtures/version-mismatch/`

**Files:**
- Create: `tests/fixtures/version-mismatch/Tuist.swift`
- Create: `tests/fixtures/version-mismatch/Project.swift`
- Create: `tests/fixtures/version-mismatch/App/Sources/*`,
  `App/Tests/*`
- Create: `tests/fixtures/version-mismatch/.tool-versions`
- Create: `tests/fixtures/version-mismatch/EXPECTATIONS.md`

**Interfaces:**
- Consumes: same validation approach as Task 8/11.
- Produces: the Scenario C check described in spec §8.1/§11.

- [ ] **Step 1: Determine two distinct real Tuist versions**

Run: `tuist version` to find the currently installed version (version B).
Pick a distinct, older, real released Tuist version (version A) to pin
via `.tool-versions` (e.g. `tuist <version-A>`) — check
`tuist run` / Tuist's release list to confirm version A is a real
past release, not invented. Document both concrete version strings in
`EXPECTATIONS.md` (Step 3) rather than leaving them as unfilled
placeholders — this is the one fixture where an actual mismatch must be
real and reproducible, not aspirational.

- [ ] **Step 2: Author the project pinned to version A**

Write `Tuist.swift`/`.tool-versions` declaring version A as the pin, and
write `Project.swift` using manifest syntax valid for version A
specifically (not necessarily valid for version B — that's the point of
this fixture). Keep the app minimal (one target, one test) — the fixture
exists to exercise version-mismatch *detection*, not architectural
complexity.

- [ ] **Step 3: Write `tests/fixtures/version-mismatch/EXPECTATIONS.md`**

```markdown
# Fixture: version-mismatch

**Exercises:** version mismatch detection in `references/version-safety.md`,
via `ios-tuist-feature` (PRD §40 Scenario C)

## Starting state

- Project-pinned Tuist version (via `.tool-versions`/`Tuist.swift`):
  `<version A — fill in with the real version chosen in Task 12 Step 1>`
- Locally/CI-installed active Tuist version at time of authoring:
  `<version B — fill in with the real version from `tuist version` at
  authoring time>`
- These are deliberately different.

## Prompt to exercise this fixture

> Add a simple settings screen to this project.

## Expected behavior

- The skill detects the pinned version (A) from this fixture's own
  config files.
- The skill detects the active version (B) via `tuist version`.
- The skill reports the mismatch explicitly in its Output Contract
  (Version Context section) as a risk.
- The skill does NOT silently install/switch to version A to make things
  work.
- The skill does NOT silently generate code for version B (the active
  version) while claiming to target the project's actual pin.
- The skill treats the project-pinned version as authoritative for any
  manifest syntax choices it makes.

## What must NOT happen

- Any automatic Tuist version change (install, switch, upgrade,
  downgrade) performed without the user explicitly requesting a
  migration.
- The mismatch going unreported.

## How to check

1. Read the skill's Output Contract — the Version Context section must
   show both versions and flag the mismatch; Risks/Follow-up must
   mention it.
2. Confirm no `.tool-versions`/`Tuist.swift` pin was changed by the run
   (`git diff` those two files specifically should be empty unless the
   task itself required a version change, which it doesn't here).
3. This fixture's build validation in CI (Task 13) intentionally uses
   version A (the pin) to install and build with — proving the fixture
   itself is real and buildable under its stated pin, independent of
   whatever version happens to be active when a skill is exercised
   against it.
```

- [ ] **Step 4: Validate the fixture builds under its pinned version**

```bash
cd tests/fixtures/version-mismatch
# install/switch to version A specifically for this validation pass, e.g.:
# mise install tuist@<version-A> && mise use tuist@<version-A>
# or the equivalent for whatever version manager is available
tuist install
tuist generate --no-open
xcodebuild -workspace *.xcworkspace -scheme App build
rm -rf *.xcworkspace *.xcodeproj .build
```

Expected: succeeds under version A. Switch back to whatever Tuist version
was active before this step if you changed it locally.

- [ ] **Step 5: Commit**

```bash
git add tests/fixtures/version-mismatch
git commit -m "test: add version-mismatch fixture with real distinct Tuist pins"
```

---

### Task 13: Fixture — `tests/fixtures/modular/`

**Files:**
- Create: `tests/fixtures/modular/Tuist.swift`
- Create: `tests/fixtures/modular/Project.swift`
- Create: `tests/fixtures/modular/App/Sources/*`, `App/Tests/*`
- Create: `tests/fixtures/modular/ProfileFeature/Sources/*`,
  `ProfileFeature/Tests/*`
- Create: `tests/fixtures/modular/SharedUI/Sources/*`,
  `SharedUI/Tests/*`
- Create: `tests/fixtures/modular/EXPECTATIONS.md`

**Interfaces:**
- Consumes: same validation approach as prior fixture tasks.
- Produces: the Scenario D check described in spec §8.1/§11.

- [ ] **Step 1: Author a real, buildable feature-modular project**

Three targets beyond the app: `App` (depends on `ProfileFeature`),
`ProfileFeature` (depends on `SharedUI`), `SharedUI` (no feature
dependencies). Each has real source and at least one real test. This
demonstrates a dependency graph with more than one level, so the
narrowest-target rule has somewhere meaningful to apply.

- [ ] **Step 2: Validate it builds as-is**

```bash
cd tests/fixtures/modular
tuist install
tuist generate --no-open
xcodebuild -workspace *.xcworkspace -scheme App build
xcodebuild test -workspace *.xcworkspace -scheme App -destination 'platform=iOS Simulator,name=iPhone 16'
rm -rf *.xcworkspace *.xcodeproj .build
```

Expected: success.

- [ ] **Step 3: Write `tests/fixtures/modular/EXPECTATIONS.md`**

```markdown
# Fixture: modular

**Exercises:** `ios-tuist-dependency` (PRD §40 Scenario D)

## Starting state

A real, buildable feature-modular Tuist project:
`App -> ProfileFeature -> SharedUI`. Each target has its own tests.

## Prompt to exercise this fixture

> Add Kingfisher only to ProfileFeature.

## Expected behavior

- `ProfileFeature` is identified as the consumer target directly from the
  prompt (no ambiguity here — this fixture is the "explicit target"
  case; ambiguous-target resolution is exercised manually, not by CI).
- Kingfisher is attached to `ProfileFeature`'s dependency list only.
- `App` and `SharedUI`'s dependency lists are unchanged.
- The integration mechanism used matches whatever this fixture already
  uses for its (if any) existing dependencies — do not introduce a second
  mechanism.
- `tuist install`/generate succeed.
- `ProfileFeature` and `App` build successfully afterward.

## What must NOT happen

- Kingfisher attached to `App` or `SharedUI`.
- Any existing target's dependency list touched beyond `ProfileFeature`.
- Conversion of the project's dependency integration mechanism.

## How to check

1. `git diff` the fixture — only `ProfileFeature`'s manifest (and lock/
   resolved-dependency files) should change.
2. Confirm via `grep`/manual read that `App/Project.swift` and
   `SharedUI/Project.swift` (or the root `Project.swift` if targets are
   defined in one file — match whatever this fixture actually uses) are
   untouched.
3. Independently run `tuist install && tuist generate && xcodebuild
   build` and confirm success.
4. Reset with `git checkout -- tests/fixtures/modular && git clean -fdx
   tests/fixtures/modular`.
```

- [ ] **Step 4: Commit**

```bash
git add tests/fixtures/modular
git commit -m "test: add modular fixture (App -> ProfileFeature -> SharedUI)"
```

---

### Task 14: CI workflow — `validate-fixtures.yml`

**Files:**
- Create: `.github/workflows/validate-fixtures.yml`

**Interfaces:**
- Consumes: `tests/fixtures/legacy-tuist/`,
  `tests/fixtures/version-mismatch/`, `tests/fixtures/modular/` (all must
  already exist and build, from Tasks 11–13). `new-project` (Task 10) is
  intentionally excluded from CI build validation since it starts empty —
  there is nothing to generate/build until a skill has been run against
  it by a human.
- Produces: the automated regression gate described in spec §8.2/§11.

- [ ] **Step 1: Write `.github/workflows/validate-fixtures.yml`**

```yaml
name: Validate fixtures

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  legacy-tuist:
    runs-on: macos-14
    defaults:
      run:
        working-directory: tests/fixtures/legacy-tuist
    steps:
      - uses: actions/checkout@v4
      - name: Install Tuist
        run: curl -Ls https://install.tuist.io | bash
      - name: Resolve dependencies
        run: tuist install
      - name: Generate project
        run: tuist generate --no-open
      - name: Build
        run: xcodebuild -workspace *.xcworkspace -scheme App -destination 'generic/platform=iOS Simulator' build
      - name: Test
        run: xcodebuild test -workspace *.xcworkspace -scheme App -destination 'platform=iOS Simulator,name=iPhone 16'

  modular:
    runs-on: macos-14
    defaults:
      run:
        working-directory: tests/fixtures/modular
    steps:
      - uses: actions/checkout@v4
      - name: Install Tuist
        run: curl -Ls https://install.tuist.io | bash
      - name: Resolve dependencies
        run: tuist install
      - name: Generate project
        run: tuist generate --no-open
      - name: Build
        run: xcodebuild -workspace *.xcworkspace -scheme App -destination 'generic/platform=iOS Simulator' build
      - name: Test
        run: xcodebuild test -workspace *.xcworkspace -scheme App -destination 'platform=iOS Simulator,name=iPhone 16'

  version-mismatch:
    runs-on: macos-14
    defaults:
      run:
        working-directory: tests/fixtures/version-mismatch
    steps:
      - uses: actions/checkout@v4
      - name: Install Tuist pinned by this fixture
        run: |
          PINNED_VERSION=$(cat .tool-versions | grep '^tuist ' | awk '{print $2}')
          curl -Ls https://install.tuist.io | bash -s "$PINNED_VERSION"
      - name: Resolve dependencies
        run: tuist install
      - name: Generate project
        run: tuist generate --no-open
      - name: Build
        run: xcodebuild -workspace *.xcworkspace -scheme App -destination 'generic/platform=iOS Simulator' build
```

Note: `version-mismatch`'s job deliberately installs the **pinned**
version (A), not "latest," and does not run a build using any other
version — this job validates that the fixture is real and buildable
under its stated pin, per `EXPECTATIONS.md`. It is not the same thing as
testing a skill's mismatch-handling behavior, which is a human-in-the-loop
check (spec §8.2).

- [ ] **Step 2: Verify workflow YAML is syntactically valid**

Run: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/validate-fixtures.yml'))" `
Expected: no error (requires PyYAML; if unavailable, use
`ruby -ryaml -e "YAML.load_file('.github/workflows/validate-fixtures.yml')"`
or any available YAML parser as a substitute).

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/validate-fixtures.yml
git commit -m "ci: validate buildable fixtures on macOS runners"
```

- [ ] **Step 4: Push and confirm the workflow runs**

```bash
git push
```

Then check the Actions tab (or `gh run watch`) to confirm all three jobs
pass. If any fail, apply Evidence-Driven Debugging (see any `SKILL.md`'s
Failure Handling section) before proceeding — do not mark this task done
until CI is green.

---

### Task 15: `examples/sample-minimal/` and `examples/sample-modular/`

**Files:**
- Create: `examples/sample-minimal/` (copy of `templates/minimal/` with
  slightly more realistic content — a real small feature, not just
  boilerplate)
- Create: `examples/sample-modular/` (copy of `templates/feature-modular/`
  with slightly more realistic content)
- Create: `examples/sample-minimal/README.md`
- Create: `examples/sample-modular/README.md`

**Interfaces:**
- Consumes: `templates/minimal/`, `templates/feature-modular/`.
- Produces: reference material for Codex/humans reading the repo — not
  wired into CI (per spec §8.3).

- [ ] **Step 1: Build `examples/sample-minimal/`**

Copy `templates/minimal/`'s structure and extend it with one small,
realistic piece of app logic and a matching real test (e.g. a simple
counter or a settings toggle persisted via `UserDefaults`) so a reader
sees the template in actual use, not just its skeleton.

- [ ] **Step 2: Build `examples/sample-modular/`**

Same approach using `templates/feature-modular/` as the base — extend
`ExampleFeature` with slightly more realistic content.

- [ ] **Step 3: Validate both build**

```bash
for d in examples/sample-minimal examples/sample-modular; do
  (cd "$d" && tuist install && tuist generate --no-open && \
   xcodebuild -workspace *.xcworkspace -scheme App -destination 'generic/platform=iOS Simulator' build && \
   rm -rf *.xcworkspace *.xcodeproj .build)
done
```

Expected: both succeed.

- [ ] **Step 4: Write both README.md files**

Explain what makes each example different from its base template (the
added realistic logic) and that these are for human/Codex reading
context, not automated validation.

- [ ] **Step 5: Commit**

```bash
git add examples
git commit -m "docs: add sample-minimal and sample-modular examples"
```

---

### Task 16: README.md and CHANGELOG.md

**Files:**
- Modify: `README.md`
- Create: `CHANGELOG.md`

**Interfaces:**
- Consumes: everything built in Tasks 1–15 (this task documents the
  finished repo).
- Produces: the installation/usage doc a human reads first.

- [ ] **Step 1: Read the current README.md**

Run: `cat README.md`

(Confirm its current one-line content before overwriting, so nothing
existing is silently dropped.)

- [ ] **Step 2: Write the new `README.md`**

Cover, in order:
1. One-paragraph summary (from spec §1's Purpose).
2. Installation as a Claude Code plugin — reference `.claude-plugin/plugin.json`
   and give the actual install command/flow Claude Code uses for
   plugins (check current Claude Code plugin-install documentation for
   the exact command syntax rather than guessing — if uncertain, state
   the general mechanism and link to Claude Code's plugin docs rather
   than inventing a command).
3. The three skills, one paragraph each: what triggers them, one example
   prompt.
4. Repository layout (can reuse spec §2's tree, trimmed).
5. How fixtures/CI work, briefly, linking to
   `tests/fixtures/*/EXPECTATIONS.md`.
6. Explicit non-goals, briefly (from spec §10), so users don't expect
   this to replace Tuist's own docs/MCP.
7. Link to the full design spec at
   `docs/superpowers/specs/2026-09-17-ios-tuist-skills-v0.1-design.md`.

- [ ] **Step 3: Write `CHANGELOG.md`**

```markdown
# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [0.1.0] - <fill in actual release date when tagged>

### Added
- `ios-tuist-bootstrap` skill: creates a new Tuist-based iOS project with
  a selected architecture profile, validated via generate/build/test.
- `ios-tuist-feature` skill: adds a feature to an existing Tuist project
  while preserving its conventions.
- `ios-tuist-dependency` skill: adds/removes/relocates a dependency
  scoped to the narrowest required target.
- Shared references: version-safety, source-of-truth, testing,
  dependencies, modularization.
- Templates: minimal, feature-modular, clean.
- Fixtures: new-project, legacy-tuist, version-mismatch, modular, each
  with an `EXPECTATIONS.md`.
- CI: fixture build/generate/test validation on macOS runners.
```

- [ ] **Step 4: Commit**

```bash
git add README.md CHANGELOG.md
git commit -m "docs: write README and seed CHANGELOG for v0.1"
```

---

### Task 17: Final spec-compliance sweep

**Files:**
- No new files — this task audits the whole repo against spec §11's
  acceptance criteria and fixes any gaps found.

**Interfaces:**
- Consumes: the entire repository state after Tasks 1–16.
- Produces: nothing new by default; only produces fixes if gaps are
  found.

- [ ] **Step 1: Run the acceptance checklist from spec §11**

For each of the following, confirm true or fix before proceeding:

```bash
# All three SKILL.md files exist and start with valid frontmatter
for f in skills/ios-tuist-bootstrap/SKILL.md skills/ios-tuist-feature/SKILL.md skills/ios-tuist-dependency/SKILL.md; do
  head -1 "$f" | grep -q '^---$' && echo "OK: $f" || echo "MISSING/BROKEN: $f"
done

# All five shared references exist
for f in references/version-safety.md references/source-of-truth.md references/testing.md references/dependencies.md references/modularization.md; do
  test -f "$f" && echo "OK: $f" || echo "MISSING: $f"
done

# All four fixtures have EXPECTATIONS.md
for d in tests/fixtures/new-project tests/fixtures/legacy-tuist tests/fixtures/version-mismatch tests/fixtures/modular; do
  test -f "$d/EXPECTATIONS.md" && echo "OK: $d" || echo "MISSING: $d/EXPECTATIONS.md"
done

# Three templates exist
for d in templates/minimal templates/feature-modular templates/clean; do
  test -f "$d/Project.swift" && echo "OK: $d" || echo "MISSING: $d/Project.swift"
done

# Plugin manifest, license, changelog, readme
for f in .claude-plugin/plugin.json LICENSE CHANGELOG.md README.md; do
  test -f "$f" && echo "OK: $f" || echo "MISSING: $f"
done

# No Config.swift anywhere in generated content
grep -rl "Config.swift" skills/ references/ templates/ examples/ tests/fixtures/ 2>/dev/null | grep -v EXPECTATIONS.md
```

The last command should output nothing except possibly explanatory prose
mentioning "Config.swift" by name as something to avoid (check any hits
manually — a mention in prose explaining the rule is fine; an actual
`Config.swift` file being created is not).

- [ ] **Step 2: Confirm CI is green**

Run: `gh run list --branch develop --limit 5`

Expected: the most recent `validate-fixtures.yml` run shows `success`.

- [ ] **Step 3: Remove any leftover `.gitkeep` files made obsolete by real content**

```bash
git status --short
```

For any directory that now has real tracked content (e.g.
`references/.gitkeep` once `references/` has real `.md` files), remove
the now-unnecessary `.gitkeep`:

```bash
git rm --ignore-unmatch references/.gitkeep templates/.gitkeep examples/.gitkeep tests/fixtures/.gitkeep skills/ios-tuist-bootstrap/references/.gitkeep skills/ios-tuist-feature/references/.gitkeep skills/ios-tuist-dependency/references/.gitkeep
```

(Leave `.gitkeep` in any skill's `references/` subfolder if it is still
genuinely empty — v0.1's spec doesn't require skill-specific reference
content beyond what's in root `references/`.)

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "chore: v0.1 spec-compliance sweep, remove obsolete placeholders"
git push
```

---

## Post-plan note

This plan intentionally stops at the PRD's v0.1 milestone (spec §1,
§11). `ios-tuist-module`, `ios-tuist-architecture-review`,
`ios-tuist-ci`, and `ios-tuist-migrate` (PRD §9 v0.2/v0.3) are separate,
future specs — do not fold them into this implementation pass.
