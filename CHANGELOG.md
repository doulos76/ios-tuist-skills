# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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
