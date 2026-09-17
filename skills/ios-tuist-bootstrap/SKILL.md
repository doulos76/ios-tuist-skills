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
   [version-safety](../../references/version-safety.md)). Note deployment-target
   defaults and package manager availability.
2. **Requirements** — determine: app name, bundle identifier, platform,
   deployment target, SwiftUI vs UIKit, architecture profile, testing
   strategy, dependencies, localization/resource needs. Only ask the user
   about fields not already answered by their request. Do not ask
   questions whose answers are obvious from context (e.g. don't ask
   platform if the user said "iOS app").
3. **Structure** — generate the minimum required structure:
   - `Tuist.swift` for project-wide configuration, only if project-wide
     configuration is actually needed.
   - Never `Config.swift` (see
     [source-of-truth](../../references/source-of-truth.md)'s configuration
     rule).
   - `Workspace.swift` only if justified per
     [source-of-truth](../../references/source-of-truth.md)'s decision rule —
     state the justification if created.
4. **Architecture** — select one profile based on the user's request, or
   `minimal` if unspecified:
   - `minimal` — [`templates/minimal/`](../../templates/minimal/)
   - `feature-modular` —
     [`templates/feature-modular/`](../../templates/feature-modular/)
   - `clean` — [`templates/clean/`](../../templates/clean/)
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
  Mode, so this preference applies by default — see
  [source-of-truth](../../references/source-of-truth.md)).
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
