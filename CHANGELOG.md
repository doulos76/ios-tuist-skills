# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [0.8.0] - 2026-10-06

### Added

- WS3 (#40): every fixture in the CI matrix has its own `.tool-versions` pin
  (the manual `new-project` and `existing-xcode` scenarios have none);
  `scripts/check-fixture-pins.sh` and `lint.yml`'s `check-pins` job enforce equality
  with `tests/fixtures/ci-matrix.json`.
- WS6 (#43): `scripts/benchmark-isolated-run.sh` adds prep/collect, an isolation guard
  and a dependency-edge snapshot. `benchmark-prep-run.sh` drops hard-coded `/Users/...`
  paths; EXECUTION-GUIDE adds "Isolated runs" (Phases 2-3 documented only). Baseline and
  with-skill sessions use `--setting-sources project`: plain `claude` loads a user-scope
  installed plugin.

### Changed

- WS2 (#39): version-safety collects evidence from every source by Tool Version / Xcode /
  Swift / Manifest compatibility axis. Only Tool Version determines the effective Tuist
  version; conflicts are reported, never fixed, and commands record their cwd.
  `Package.swift` / `Tuist/Package.swift` are no longer Tuist-version sources:
  `swift-tools-version` is Swift evidence.
- WS4 (#41): "Coexisting guidance" in `ios-tuist-feature`, `ios-tuist-dependency` and
  `ios-tuist-restyle`, plus README's "Relationship to the official Tuist plugin" section.
  All 10 descriptions state what the skill does, when to use it and "Not for ...",
  preserving every existing prohibition.
- WS5 (#42): `ios-tuist-bootstrap` stops if the target path or a directory one level below
  contains a `*.xcodeproj` / `*.xcworkspace`, pointing to the official Tuist `migrate` skill.
  `tests/fixtures/existing-xcode/` is a manual scenario, outside the CI matrix.
- CI (#27, #29, #30, #37): duplicate-run handling, a measurement helper, fixture matrix in
  `tests/fixtures/ci-matrix.json`, path-based selection, `lint.yml`, `fixtures-ok` aggregate
  and a weekly full run. No behavior change for skill users. CI-3 was reverted for no gain
  (#34, #35); evidence and decision records are in #33 and #36.

### Fixed

- WS1 (#38): `ios-tuist-module` adds an edge to the new target only from targets with a
  verified usage site (import + moved-symbol reference), with file:line evidence under
  Dependency Changes; "no edge added" is valid. An emptied original test target is
  reported, never deleted. The `App -> NetworkingKit` defect was a spec contradiction
  across SKILL.md, EXPECTATIONS.md and the rubric, not an agent rule violation.
- WS1 follow-up (#44): baseline the project's pre-existing test schemes before moving code,
  re-run them afterwards and never claim success while one fails. A source-less `AppTests`
  left the `App` scheme failing/unstable while old validation said "all passed".
  Updated extract-candidate EXPECTATIONS and fixed the leftover `App` → `NetworkingKit`
  dependency contradiction.

### Breaking changes

- Version-safety output now uses per-axis evidence tables, a `Conflicts` line and cwd for
  live commands; `Effective project version` replaces the single detected version.
  Workflows that parse skill output may be affected.

### Verification gates

- `.xcode-version` / `.swift-version`: no Tuist consumption found (grep of `cli/Sources`
  on tuist/tuist main `9365e96` returned 0 hits); docs not confirmed. The "Tuist does not
  consume this" labels are kept.
- Agent Skills `description` limit: 1024 characters ([specification](https://agentskills.io/specification));
  longest description in this repo is 548.
- `tuist init --help` (4.206.0): "Get started with Tuist in your project." with only
  `--path`. Existing-project support is not clearly documented; bootstrap does not mention
  `tuist init`.
- Official plugin, tuist/agent-plugin `038e54c` (2026-08-18): `generated-projects` still says
  "Use `buildableFolders` instead of `sources` and `resources` globs"; `migrate` converts
  Xcode projects to Tuist.
- Codex: codex-cli 0.160.0 in an isolated CODEX_HOME installed the plugin from
  `.claude-plugin/` alone via `codex plugin marketplace add` + `codex plugin add`
  ("installed, enabled", 10 skills). WS7's generated Codex manifest was not implemented.
  Not verified: Codex invokes the skills at runtime.

### Known limitations

- `swiftVersion` in `Tuist.swift` / `Config.swift` is consumed by Tuist 3.42.2 (`tuist fetch`),
  only stored in the 4.62.0 and 4.184.0 sources that were checked, and deprecated/ignored
  from 4.184.1. The Swift axis does not yet label this per version.
- `.tuist-version` is unused by current Tuist (3.x behavior not verified) and is not a
  Tool Version source.
- On `extract-candidate`, with-skill outcomes varied (extracted / refused / extracted).
  The `App` scheme with a source-less test target is not deterministic: harness `Test: pass`
  does not prove tests ran; changed-file counts include Tuist generation artifacts.
- The 2026-09-20 benchmark's baseline isolation is unverified. Models were not recorded in
  the WS6 acceptance run; evidence: `docs/superpowers/benchmarks/2026-10-06-ws6-smoke/`.

## [0.7.1] - 2026-09-26

### Added

- README: Codex CLI installation instructions (`codex plugin marketplace
  add` / `codex plugin add`), confirmed working against the existing
  `.claude-plugin/marketplace.json` — no marketplace or plugin manifest
  changes were needed.
- README: note the v0.7 (marketplace-distribution) milestone alongside
  the existing v0.1-v0.6 list.

## [0.7.0] - 2026-09-24

### Added

- Skill effectiveness benchmark (Phase 1): baseline-vs-with-skill
  comparison across all 14 fixture scenarios, with real
  `tuist generate`/build/test verification and independent rubric
  scoring, in `docs/superpowers/benchmarks/2026-09-20-skill-effectiveness/`.
- `.claude-plugin/marketplace.json` so this repository can be installed
  as a Claude Code plugin marketplace via `/plugin marketplace add`.

### Changed

- Repository is now public.
- Fixture-validation CI now runs on GitHub-hosted `macos-15` runners
  instead of the temporary self-hosted runner used while the repo was
  private.
- README install instructions now lead with `/plugin marketplace add`
  and `/plugin install`; `--plugin-dir` is documented as the
  local-development path.

## [0.6.0] - 2026-09-20

### Added

- `ios-tuist-scaffold`: authors one explicitly user-named `tuist
  scaffold` template — its `Tuist/Templates/<name>/<name>.swift`
  manifest plus the `.stencil` file(s) it references — matching a shape
  the user describes or points at in existing files. Generates
  `Template.Item.file` + `.stencil` (attribute-substitution-only)
  output; never `.string`/`.directory` items or Stencil control-flow
  syntax. Verifies every authored template by actually running `tuist
  scaffold` in a scratch location, never against the real project tree.
- `scaffold-candidate` fixture: a minimal real Tuist 4.206.0 project
  with a committed `feature` scaffold template, wired into the existing
  fixture-validation CI matrix.

## [0.5.0] - 2026-09-20

### Added

- `ios-tuist-test-target`: creates a new unit, integration, or UI test
  target for one explicitly user-named existing target and enrolls it
  in the relevant scheme's test action, following the project's own
  testing and naming conventions. Represents "integration test" as a
  named `.unitTests` target since Tuist has no distinct product case for
  it. Generates a single labeled placeholder test only — never real
  coverage. Refuses when a test target of the requested kind already
  exists.
- `test-target-candidate` fixture: a real Tuist 4.206.0 project with a
  target that already has a unit test target (FeatureA) and a target
  that doesn't (FeatureB), plus a custom scheme bundling the existing
  test target, wired into the existing fixture-validation CI matrix.

## [0.4.0] - 2026-09-19

### Added

- `ios-tuist-restyle`: converts explicitly user-named targets' folder
  integration from array-based sources:/resources: declarations to
  buildableFolders, gated by a per-target safety checklist grounded in
  real Tuist defects and their regression history (tuist/tuist#8337;
  tuist/tuist#8547 and its later regressions tuist/tuist#9156,
  tuist/tuist#9289). Never sweeps a whole project, never bundles a
  version bump, never silently drops an exclusion pattern.
- `restyle-candidate` fixture: a real Tuist 4.206.0 project with a
  proceed-with-residual-risk target (CleanFeature) and a
  checklist-failing target (ExcludeFeature, with a genuine
  `.glob(excluding:)` exclusion pattern), wired into the existing
  fixture-validation CI matrix.

## [0.3.0] - 2026-09-18

### Added

- `ios-tuist-migrate`: moves a project's pinned Tuist version forward to
  a user-specified target version, updating version-pin sources and the
  minimum manifest syntax the target version actually requires. The only
  skill in this repository permitted to change a project's Tuist version
  pin, and only on explicit request — never bundles a structural/style
  migration into a version bump.
- `migrate-candidate` fixture: a real Tuist 3.42.2 project with a
  verified breaking-change surface (the Tuist 4.0 `Config.swift` ->
  `Tuist.swift` rename and `Target(...)`/`platform:` ->
  `.target(...)`/`destinations:` manifest API change), wired into the
  existing fixture-validation CI matrix at its starting version.

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

## [0.1.0] - 2026-09-17

### Added

- `ios-tuist-bootstrap`: creates a new Tuist-based iOS project with a selected
  architecture profile and generate/build/test validation.
- `ios-tuist-feature`: adds features while preserving an existing project's
  conventions.
- `ios-tuist-dependency`: adds, removes, or relocates dependencies at the
  narrowest required target.
- Shared version-safety, source-of-truth, testing, dependency, and
  modularization references.
- Minimal, feature-modular, and clean templates.
- New-project, legacy-Tuist, version-mismatch, and modular fixtures with
  scenario expectations.
- macOS CI validation for fixture generation, builds, and tests.
