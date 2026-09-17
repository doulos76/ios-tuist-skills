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
