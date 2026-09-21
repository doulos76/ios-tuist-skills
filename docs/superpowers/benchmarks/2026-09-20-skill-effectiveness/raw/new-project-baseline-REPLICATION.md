# Comparison 1 — `new-project` — baseline replication run

A second, independent baseline pass on the same fixture and prompt as
`new-project-baseline.md`, run in the same `.worktrees/benchmark-baseline`
worktree (no skill loaded — no `--plugin-dir`), for reproducibility
evidence. Not a substitute for the original real baseline; kept alongside
it because the failure modes it hit turned out to match closely.

## Task prompt

> Create a new SwiftUI iOS app using Tuist with a feature-modular structure.

## Fixture

`tests/fixtures/new-project/` (empty starting state — only
`EXPECTATIONS.md` and `.gitkeep`).

## What this response did

- Checked environment first: `tuist version` (4.206.0), `xcodebuild
  -version` (Xcode 27.0), `mise --version`, and `xcrun simctl list
  devices available` — again, `which`/`--version` style checks only, no
  formal version-safety procedure consulted (none referenced in this
  session).
- Designed the same structural shape as the original baseline: two
  separate Tuist projects (`Projects/App/Project.swift`,
  `Projects/Features/Home/Project.swift`) tied together with a root
  `Workspace.swift` and `Tuist.swift` — not this repo's own
  `templates/feature-modular/` single-project/multi-target shape.
- **Created `Workspace.swift`**, again self-justified in the moment as
  "the minimal requirement to tie two independent `Project.swift` files
  into one graph" — same reasoning, same conclusion, arrived at
  independently (no memory of the prior run).
- No `Config.swift` created.
- **Hit the identical two failures as the original baseline run, in the
  same order:**
  1. `tuist generate --no-open` failed first attempt — `Error: Manifest
     not found` — because only `Tuist.swift` existed at the root with no
     `Project.swift`/`Workspace.swift` yet at generate time in the
     initial structure attempt. Fixed by adding `Workspace.swift`.
  2. First successful `tuist generate` produced a project with no
     explicit `deploymentTargets`, defaulting to the latest Xcode SDK
     (iOS 27.0) — zero installed simulator runtimes matched (all
     available runtimes topped out at 26.5). `xcodebuild build` failed
     with a long list of "doesn't match deployment target" destination
     errors. Diagnosed only after the failed build, fixed by adding
     `deploymentTargets: .iOS("17.0")` to all four targets and
     regenerating.
- No structured Output Contract report produced — free-form narrative.

## Verification performed

```
$ tuist generate --no-open
✔ Success — Project generated. (after adding Workspace.swift)

$ xcodebuild build -workspace App.xcworkspace -scheme App \
    -destination 'platform=iOS Simulator,name=iPhone 17'
** BUILD SUCCEEDED ** (after fixing deploymentTargets)

$ xcodebuild test -workspace App.xcworkspace -scheme App \
    -destination 'platform=iOS Simulator,name=iPhone 17'
Test Suite 'AppTests' passed — 1 test, 0 failures
** TEST SUCCEEDED **

$ xcodebuild test -workspace App.xcworkspace -scheme Home \
    -destination 'platform=iOS Simulator,name=iPhone 17'
Test Suite 'HomeTests' passed — 1 test, 0 failures
** TEST SUCCEEDED **
```

Same gap as the original baseline: the `App` scheme's test action wires
up only `AppTests`; `HomeTests` only runs via the separate `Home`
scheme, not via `xcodebuild test -scheme App` alone. (Not independently
re-verified by scheme-XML parsing this run, since the fixture was reset
before that check was performed — see Notes.)

## `git diff` (untracked files added, captured before reset)

```
?? tests/fixtures/new-project/Projects/
?? tests/fixtures/new-project/Tuist.swift
?? tests/fixtures/new-project/Workspace.swift

 Projects/App/Project.swift             | 33 +++++++++++++++++++++
 Projects/App/Sources/AppApp.swift      | 11 +++++++
 Projects/App/Tests/AppTests.swift      |  8 +++++
 Projects/Features/Home/Project.swift   | 27 +++++++++++++++
 Projects/Features/Home/Sources/HomeView.swift | 19 +++++++++++
 Projects/Features/Home/Tests/HomeTests.swift  |  8 +++++
 Tuist.swift                            |  3 ++
 Workspace.swift                        |  9 +++++
 8 files changed, 118 insertions(+)
```

## Notes

- Fixture was reset to its empty starting state (`git clean -fdx
  tests/fixtures/new-project`) after this run per `EXPECTATIONS.md`'s
  own instructions, before a scheme-XML re-check of the `HomeTests`
  gap could be independently repeated on this run's own artifacts. The
  gap description above is carried over from the matching pattern
  observed live during this run's own `xcodebuild test -scheme App`
  output (only `AppTests` executed), not from a fresh XML parse.
- This replication was **not** scored against the rubric; it exists
  purely as reproducibility evidence for the original baseline's two
  documented failure modes (manifest-structure ordering,
  `deploymentTargets` omission) and structural choice (two-project +
  Workspace.swift instead of single-project/multi-target).

## Real-artifact pass/fail

| Axis | Result |
|---|---|
| BUILD | PASS (after a self-corrected `deploymentTargets` omission — same failure class as original baseline) |
| `tuist generate` | PASS (after a self-corrected manifest-structure issue — same failure class as original baseline) |
| TEST (App scheme) | PASS, but incomplete — `HomeTests` excluded, matching original baseline's gap |
| TEST (Home scheme, run separately) | PASS |
| Workspace.swift justification | Self-reasoned, not skill-guided; identical structural choice to original baseline (2 projects + workspace) |
