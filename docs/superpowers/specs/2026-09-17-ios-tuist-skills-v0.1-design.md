# ios-tuist-skills v0.1 — Design Spec

- **Status:** Approved for planning
- **Date:** 2026-09-17
- **Source:** `ios-tuist-skills-PRD.md` (v1.0, 2026-09-17)
- **Scope:** PRD v0.1 milestone — "Safe Project Creation and Extension"
- **Implementation owner:** Codex (this repo's Claude session only produces spec + plan)
- **Planning/review owner:** Claude

## 1. Purpose

Ship a Claude Code plugin that gives Claude version-aware iOS/Tuist engineering
judgment: detect the project's real Tuist/Xcode/Swift versions, preserve
existing repository conventions, generate only version-compatible Tuist code,
and validate every meaningful change through generate/build/test — instead of
assuming the latest Tuist syntax or silently modernizing a project.

This spec covers exactly the PRD's v0.1 milestone (PRD §43, §47): three
skills, the shared version-safety/source-of-truth foundation they all depend
on, and the fixtures/CI needed to prove they behave correctly across
version-sensitive scenarios. Later milestones (`ios-tuist-module`,
`ios-tuist-architecture-review`, `ios-tuist-ci`, `ios-tuist-migrate`) are out
of scope for this spec and this implementation pass.

## 2. Repository layout

```text
ios-tuist-skills/
├── .claude-plugin/
│   └── plugin.json
├── .github/
│   └── workflows/
│       └── validate-fixtures.yml
├── skills/
│   ├── ios-tuist-bootstrap/
│   │   ├── SKILL.md
│   │   └── references/           # skill-specific only; shared refs live at repo root
│   ├── ios-tuist-feature/
│   │   ├── SKILL.md
│   │   └── references/
│   └── ios-tuist-dependency/
│       ├── SKILL.md
│       └── references/
├── references/                    # shared across all three skills
│   ├── version-safety.md
│   ├── source-of-truth.md
│   ├── testing.md
│   ├── dependencies.md
│   └── modularization.md
├── templates/
│   ├── minimal/
│   ├── feature-modular/
│   └── clean/
├── examples/
│   ├── sample-minimal/
│   └── sample-modular/
├── tests/
│   └── fixtures/
│       ├── new-project/           # empty dir + expectations doc (bootstrap writes into it)
│       ├── legacy-tuist/          # older Tuist syntax, sources: ["Sources/**"] convention
│       ├── version-mismatch/      # pinned Tuist version deliberately != CI-installed version
│       └── modular/                # existing feature-modular multi-target project
├── CHANGELOG.md
├── LICENSE
├── README.md
└── .gitignore
```

**Why this shape:**
- `references/` at repo root (not duplicated per-skill) because version-safety
  and source-of-truth are consumed identically by all three skills — PRD §10
  says explicitly this must be one shared procedure, not three copies.
- Each skill's own `references/` subfolder holds only content specific to
  that skill (e.g., bootstrap's architecture-profile scaffolds), keeping
  NFR-005 (small context footprint — don't load every reference for every
  task).
- `templates/` holds the actual Tuist manifest scaffolding referenced by
  `ios-tuist-bootstrap`'s architecture profiles and `ios-tuist-feature`'s
  scaffold-reuse step.
- `examples/` are fuller worked repositories a human/Codex can read for
  context; `tests/fixtures/` are narrower, purpose-built repos CI actually
  generates/builds/tests against.

## 3. Plugin packaging

`.claude-plugin/plugin.json` declares this repo as an installable Claude Code
plugin (per the earlier decision: plugin form, not per-project copy/symlink).
Minimum fields: `name` (`ios-tuist-skills`), `description`, `version`
(`0.1.0`), pointing Claude Code at the `skills/` directory. No other plugin
capabilities (commands, hooks, MCP servers) are in scope for v0.1.

## 4. Shared references — content contract

Each shared reference file must contain **principles and decision
procedures**, not version-specific API syntax (PRD §37, NFR-002). Concretely:

### 4.1 `references/version-safety.md`

- Detection order, exactly PRD §10.1: `mise.toml`, `.mise.toml`,
  `.tool-versions`, `Tuist.swift`, `Tuist/Package.swift`, `Package.swift`, CI
  workflow files, repository scripts, existing manifest syntax, then live
  commands `tuist version`, `xcodebuild -version`, `swift --version`.
- Rule: the project-pinned version (from files) is authoritative; the active
  local/CI version is compared against it, never substituted for it.
- The "Tuist Context" block skills must establish before touching manifests
  (PRD §11 format): Project Tuist / Active Tuist / Xcode / Swift / Platform /
  Deployment Target / Manifest Style / Folder Integration / Dependency
  Integration / Architecture.
- Mismatch handling: treat as a **risk to report**, never a trigger for
  silent adaptation or upgrade (PRD §12, §26 "never upgrade Tuist unless
  explicitly requested").

### 4.2 `references/source-of-truth.md`

- The exact 10-level precedence order from PRD §5 (project-pinned Tuist
  version down to this repo's own reference material).
- Rule: a lower-priority source must not override a higher-priority source
  without explicit justification recorded in the skill's output.
- Existing Project Mode vs New Project Mode decision procedure (PRD §12):
  existing conventions win unless the user explicitly requests migration;
  new repos may default to current supported practice (Buildable Folders
  where compatible, no Workspace.swift unless justified, Tuist.swift not
  Config.swift, Swift Testing for new tests).

### 4.3 `references/testing.md`

- Swift Testing preferred for new unit/integration tests when compatible;
  XCTest preserved when the repo already standardizes on it; XCTest/XCUI for
  UI tests; never migrate existing test infra as a side effect (PRD §23).
- No placeholder tests except an explicitly-labeled minimal template smoke
  test.

### 4.4 `references/dependencies.md`

- Dependency classification taxonomy (PRD §20): Swift package library,
  Swift package macro, build tool plugin, binary framework, XCFramework,
  local package, local Tuist project, system framework.
- Narrowest-target attachment rule (PRD §20) and the SPM integration-method
  preservation rule (PRD §21 — don't convert between Tuist-native
  `Package.swift` vs Xcode-native SwiftPM integration unless required).

### 4.5 `references/modularization.md`

- Pre-module checklist (PRD §18): ownership boundary, dependency direction,
  reusability, compile-time isolation benefit, test boundary, resource
  ownership, public API surface, cyclic-dependency likelihood, build cost.
- Linkage-is-a-graph-decision rule (PRD §19): never default to
  `.staticFramework`/`.framework`/etc.; inspect existing convention,
  transitive graph, resources, extensions, binary requirements before
  choosing.

## 5. `ios-tuist-bootstrap`

**Purpose:** Create a new Tuist-based iOS project using a selected
architecture profile, with version-safe, minimal, validated output.

**Trigger conditions:** User asks to create/start/scaffold a new iOS app
using Tuist (e.g., "Create a new SwiftUI iOS app using Tuist with a
feature-modular structure").

**Non-trigger conditions:** Target directory already contains a Tuist
project (→ delegate reasoning to `ios-tuist-feature`); request is only to add
a dependency to an existing project (→ `ios-tuist-dependency`).

**Preconditions:**
- Confirm no existing `Project.swift`/`Tuist.swift`/`Workspace.swift` in the
  target directory (New Project Mode applies only when true).
- Environment inspection: locally installed Tuist/Xcode/Swift versions.

**Version safety:** Apply `references/version-safety.md` in full before
writing any manifest. Since there is no pinned project version yet, the
locally active Tuist version becomes the working version — but the skill
must state this explicitly in its output rather than assuming latest is
always correct (e.g., surface the active version and let the user object if
it's unexpectedly old/new).

**Workflow (PRD §30):**
1. **Environment** — detect Tuist/Xcode/Swift/deployment-target defaults,
   package manager, relevant CI context.
2. **Requirements** — determine app name, bundle identifier, platform,
   deployment target, SwiftUI vs UIKit, architecture profile, testing
   strategy, dependencies, localization/resource needs. Skip questions
   already answered by explicit user input; ask only what's missing.
3. **Structure** — generate the minimum required structure. `Tuist.swift`
   for project-wide config; `Workspace.swift` only if justified per §13's
   decision rule; never `Config.swift`.
4. **Architecture** — select one profile: `minimal` (default if
   unspecified), `feature-modular`, `clean`, `tca`, `custom`. Pull the
   corresponding scaffold from `templates/`.
5. **Generation** — write manifests using APIs verified compatible with the
   active version detected in step 1 (consult Tuist's own docs/MCP if
   available rather than trusting a possibly-stale embedded example, per
   PRD §37).
6. **Validation** — `tuist install`/resolve if needed → `tuist generate` →
   build → run tests → capture actual results.

**Decision rules:**
- Buildable Folders preferred over `sources`/`resources` arrays only for new
  projects on a supported toolchain (§16 decision tree).
- `ProjectDescriptionHelpers` created only per §15's rule (repeated
  behavior/naming/target-standardization need — not just because an
  expression is long).

**Validation (required before declaring success):** `tuist generate`
succeeds; app target builds; test target(s) run and pass. Report exact
command output/exit status, not just "files created."

**Failure handling:** Evidence-Driven Debugging per PRD §25 — record Tuist
version, active version, Xcode/Swift version, failing command, exact error,
affected manifest; generate ≥2 hypotheses when cause is unclear; attempt to
disprove the leading one before changing code; apply the smallest change
that explains the failure.

**Output contract:** PRD §34 format — Version Context, Changes Made, Files
Changed, Dependency Changes, Validation Performed, Build Result, Test
Result, Unverified Items, Risks/Follow-up.

## 6. `ios-tuist-feature`

**Purpose:** Add a feature to an existing Tuist project while preserving its
architecture and dependency conventions.

**Trigger conditions:** Request to add a feature/screen/module to a
repository that already has a Tuist project (e.g., "Add LoginFeature").

**Non-trigger conditions:** No existing Tuist project (→ `bootstrap`);
request is purely about adding/moving a dependency with no new feature code
(→ `dependency`).

**Preconditions:** An existing Tuist project is present and readable;
version context can be established from it.

**Version safety:** Full `references/version-safety.md` procedure. The
project-pinned version is authoritative (Existing Project Mode). If active
≠ pinned, report the mismatch as a risk before proceeding — do not adapt
generated code to the active version instead of the pinned one.

**Workflow (PRD §31):**
1. Inspect neighboring features: target definitions, dependencies, file
   organization, test style, existing scaffold/template, target naming
   convention, resource organization.
2. Decision: existing scaffold found → reuse it. No scaffold, but this is a
   repeated structure → consider creating one (goes through the same
   justification bar as bootstrap's templates, not automatic). Otherwise →
   create only the minimum files needed.
3. Connect dependencies minimally (narrowest target, per
   `references/dependencies.md`).
4. Validate: generate/build/test the affected target(s) only — not a full
   repo rebuild unless the change is graph-wide.

**Decision rules:** Never introduce a new architecture style inside one
feature (PRD §31). Never migrate an unrelated existing convention (e.g.,
`sources: ["Sources/**"]` → `buildableFolders`) as a side effect (PRD §12
example).

**Validation:** `tuist generate` succeeds; the new feature target and its
consumer(s) build; the feature's tests (existing style — Swift Testing or
XCTest, matching repo convention) run and pass.

**Failure handling:** Same Evidence-Driven Debugging procedure as bootstrap.

**Output contract:** Same PRD §34 format.

## 7. `ios-tuist-dependency`

**Purpose:** Add, remove, or relocate a Swift Package / binary dependency
using the correct Tuist integration approach, scoped to the narrowest target
that needs it.

**Trigger conditions:** Requests like "Add Kingfisher to ProfileFeature",
"remove X from Y", "move X from App to Z".

**Non-trigger conditions:** Request also requires new feature scaffolding
beyond wiring the dependency (→ `ios-tuist-feature` handles the feature,
this skill handles the dependency attachment within it).

**Preconditions:** Consumer target identifiable, either from the user's
request or from actual `import` usage in the codebase.

**Version safety:** Full `references/version-safety.md` procedure — the
project's pinned Tuist version determines valid dependency-declaration
syntax (Tuist-native `Package.swift` vs Xcode-native SwiftPM integration).

**Workflow (PRD §32):**
1. Identify the consumer target (explicit from request, or inferred from
   actual/intended imports if ambiguous — prefer the narrowest valid
   target).
2. Check current dependency integration mechanism already used in the repo.
3. Classify the dependency per `references/dependencies.md`'s taxonomy.
4. Determine the compatible declaration approach for the detected Tuist
   version and existing integration mechanism (don't convert mechanisms
   without cause, PRD §21).
5. Attach to the identified target only — never widen to app-level.
6. Resolve/install.
7. Generate.
8. Build the affected target(s) and the app.

**Decision rules:** PRD §20's narrowest-target rule is non-negotiable
(FR-005). Do not convert an existing SPM integration mechanism (Tuist
`Package.swift` vs Xcode project SwiftPM) unless the task explicitly
requires it.

**Validation:** Dependency resolves; `tuist generate` succeeds; the
consumer target and app build successfully.

**Failure handling:** Same Evidence-Driven Debugging procedure. Additional
first hypothesis to consider: version constraint conflict with an existing
dependency.

**Output contract:** Same PRD §34 format, with a populated "Dependency
Changes" section (package, version constraint, target attached to,
integration mechanism used).

## 8. Fixtures and CI validation

Per the earlier decision, fixtures under `tests/fixtures/` must be **real,
buildable Tuist projects** — not structure-only stand-ins — and validation
runs in **CI**, not assumed to work on arbitrary local machines.

### 8.1 Fixtures (PRD §40 scenarios A–D map directly)

- `tests/fixtures/new-project/` — starts empty (or near-empty); exercises
  `ios-tuist-bootstrap` end-to-end (Scenario A).
- `tests/fixtures/legacy-tuist/` — a real, older-style Tuist project (older
  manifest syntax, `sources: ["Sources/**"]` convention, no Buildable
  Folders) that already builds; exercises `ios-tuist-feature` adding
  `LoginFeature` without modernizing anything (Scenario B).
- `tests/fixtures/version-mismatch/` — a real Tuist project whose pinned
  version (via `Tuist.swift`/`.tool-versions`) deliberately differs from
  whatever Tuist version CI has installed; exercises mismatch detection and
  the "no silent adaptation, report risk" behavior (Scenario C).
- `tests/fixtures/modular/` — a real existing feature-modular project with
  multiple targets; exercises `ios-tuist-dependency` attaching a package to
  one feature target only, proving no app-wide pollution (Scenario D).

Each fixture directory includes a short `EXPECTATIONS.md` describing what a
correct skill run against it should and should not change — this is what a
human (or an eval harness) checks the skill's actual output against.

### 8.2 CI (`.github/workflows/validate-fixtures.yml`)

- Runs on a macOS runner.
- Installs the Tuist version(s) each fixture needs (via `mise`/official
  Tuist installer, respecting each fixture's pin).
- For each fixture: resolve dependencies → `tuist generate` → build → test,
  asserting these succeed (or, for `version-mismatch`, asserting the
  mismatch is what's under test, not silently resolved by installing the
  pinned version transparently to the skill).
- This CI job validates the **fixtures themselves stay buildable** as a
  regression gate. It does not run Claude/Codex automatically — skill
  behavior evaluation (does the skill actually preserve conventions when
  invoked) is a separate, manual/human-in-the-loop step documented in the
  plan, not part of this automated CI.

### 8.3 `templates/` and `examples/`

- `templates/{minimal,feature-modular,clean}/` — the actual scaffold
  sources `ios-tuist-bootstrap` copies from when instantiating a profile.
  These are the "supported profiles" from PRD §17, kept intentionally small
  (no `tca` or `custom` template in v0.1 — those profiles are selectable by
  name but fall back to `custom` = minimal + user-directed structure, since
  PRD explicitly says the skill must not impose a single architecture).
- `examples/{sample-minimal,sample-modular}/` — fuller worked repositories
  for a human or Codex to read as reference context; not wired into CI.

## 9. CHANGELOG.md

Standard Keep-a-Changelog style, seeded with an `[Unreleased]` section and a
`0.1.0` entry once the milestone ships.

## 10. Explicit non-goals (restated from PRD §7, §35)

The implementation must **not**: replace official Tuist agent skills or
Tuist MCP; implement a Tuist CLI; hard-code a Tuist-version compatibility
table; auto-upgrade Tuist; auto-redesign architecture; force any single
architecture/linkage/modularization strategy; modernize manifests as a side
effect of an unrelated task; assume SwiftUI or the latest Xcode/Swift for
every project. It must never silently upgrade Tuist, change deployment
target, change Swift language version, replace XCTest with Swift Testing,
change linkage, change dependency manager, rename targets, or regenerate
unrelated files.

## 11. Acceptance criteria for this v0.1 implementation pass

Directly from PRD §40/§47, this spec's implementation is done when:
- All three skills (`bootstrap`, `feature`, `dependency`) exist with
  complete `SKILL.md` files following the PRD §28 structure (Purpose,
  Trigger Conditions, Non-Trigger Conditions, Preconditions, Version
  Safety, Workflow, Decision Rules, Validation, Failure Handling, Output
  Contract).
- All five shared `references/*.md` files exist and contain principles/
  procedures, not embedded version-specific API syntax.
- The four fixtures exist as real, independently buildable Tuist projects,
  each with an `EXPECTATIONS.md`.
- CI validates all fixtures build/generate/test successfully (or, for
  `version-mismatch`, validates the mismatch condition itself).
- `templates/` contains working `minimal`, `feature-modular`, and `clean`
  scaffolds usable by `ios-tuist-bootstrap`.
- `.claude-plugin/plugin.json` makes the repo installable as a Claude Code
  plugin.
- `README.md` explains installation (as a plugin) and usage of each skill.
- `CHANGELOG.md` and `LICENSE` (MIT) are present.
