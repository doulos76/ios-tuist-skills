# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

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
