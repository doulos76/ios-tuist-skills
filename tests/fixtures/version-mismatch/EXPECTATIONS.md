# Fixture: version-mismatch

**Exercises:** version mismatch detection in
[`references/version-safety.md`](../../../references/version-safety.md),
via `ios-tuist-feature` (PRD §40 Scenario C)

## Starting state

- Project-pinned Tuist version (via `.tool-versions`): `4.62.0`
- Locally installed active Tuist version at authoring time: `4.206.0`
- These are deliberately different. `Tuist.swift` contains project-wide
  configuration but does not duplicate the toolchain-manager pin.

## Prompt to exercise this fixture

> Add a simple settings screen to this project.

## Expected behavior

- The skill detects pinned version `4.62.0` from this fixture's
  `.tool-versions` before inspecting lower-priority version evidence.
- The skill detects active version `4.206.0` via `tuist version`.
- The skill reports the mismatch explicitly in its Output Contract
  (Version Context section) as a risk.
- The skill does not silently install or switch Tuist versions.
- The skill does not generate manifest code for the active version while
  claiming to target the project's pin.
- The skill treats the project-pinned version as authoritative for any
  manifest syntax choices it makes.

## What must NOT happen

- Any automatic Tuist version change (install, switch, upgrade, or downgrade)
  without an explicitly requested migration.
- The mismatch going unreported.

## How to check

1. Read the skill's Output Contract. The Version Context section must show
   both versions and flag the mismatch; Risks/Follow-up must mention it.
2. Confirm `.tool-versions` and `Tuist.swift` are unchanged after the run.
3. Validate the fixture independently with the pinned executable:
   `mise exec tuist@4.62.0 -- tuist install`, `mise exec tuist@4.62.0 -- tuist
   generate --no-open`, then build the generated `App.xcworkspace`.

CI deliberately selects `4.62.0`, proving that the fixture is real and
buildable under its stated pin independently of the active Tuist version used
when exercising the skill.
