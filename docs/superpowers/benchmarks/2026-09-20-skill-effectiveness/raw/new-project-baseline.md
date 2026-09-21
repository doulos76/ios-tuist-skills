# Comparison 1 — `new-project` — baseline (REAL, uncontaminated)

Real baseline: fresh `claude` session (no `--plugin-dir`), run by the
user in `.worktrees/benchmark-baseline`, no prior exposure to this
repo's skill content or fixture answer keys.

*(A CONTAMINATED reference version of this comparison — generated
earlier in this conversation, before the methodology gap was
discovered — remains at `new-project-baseline-CONTAMINATED.md` for
comparison purposes only.)*

## Task prompt

> Create a new SwiftUI iOS app using Tuist with a feature-modular structure.

## Fixture

`tests/fixtures/new-project/` (empty starting state — only
`EXPECTATIONS.md` and `.gitkeep` existed before this run).

## What this response did

- Checked the environment (Tuist 4.206.0, Xcode 27.0, installed
  simulator runtimes) before designing the structure — but did **not**
  run any formal version-safety procedure (no reference to a
  `version-safety.md`-style detection process, since none was known to
  exist); just `which`/`--version` checks.
- Designed a feature-modular structure as **two separate Tuist
  projects** (`Projects/App/Project.swift`, `Projects/Features/Home/
  Project.swift`) tied together by a `Workspace.swift` — a materially
  different structural interpretation than "one project, multiple
  targets."
- **Created `Workspace.swift`**, with self-stated justification: "the
  minimal requirement to tie two independent `Project.swift` files into
  one graph" — reasoned as satisfying "don't create a Workspace.swift
  without real justification" on its own judgment, with no skill
  guidance to consult.
- No `Config.swift` created (correct for Tuist 4.x either way).
- **Hit two real, self-corrected failures during the process:**
  1. `tuist generate` initially failed — a root-level manifest alone
     (`Tuist.swift`) wasn't sufficient without the project structure
     also being in place; resolved by trial and error, not from prior
     knowledge of Tuist's requirements.
  2. Did not specify `deploymentTargets` on the first manifest attempt
     → defaulted to the Xcode SDK's latest (27.0), which had no
     matching installed simulator runtime → build blocked. Diagnosed
     and fixed after the first failed build attempt, not caught in
     advance.
- Produced no structured Output Contract-style report — free-form
  prose narrative instead of a Version Context / Validation Performed
  breakdown.

## Real verification performed (as reported, then independently re-checked)

```
$ tuist generate --no-open
succeeded (after fixing the manifest-structure issue above)

$ xcodebuild build (App scheme, iPhone 17 simulator)
succeeded (after fixing the deploymentTargets issue above)

$ xcodebuild test — both App and Home schemes run, both passed
```

**Independent re-check of the `App` scheme's actual test coverage**
(same class of check performed on the contaminated baseline and on the
with-skill run, for exact comparability):

```
$ python3 -c "... parse App.xcscheme for BuildableName entries ..."
App scheme testables: ['App.app', 'AppTests.xctest', 'App.app', 'App.app']
```

**Finding: the `App` scheme's `testAction` includes only `AppTests` —
`HomeTests` is not wired into it**, identical in shape to the
contaminated baseline's `HomeFeatureTests` gap on this same fixture. A
user running `xcodebuild test -scheme App` alone would silently never
exercise `HomeTests`; it only runs via the separate `Home` scheme. This
recurs across two independently-generated baselines on the same
fixture, which is stronger evidence than either alone that this is a
real baseline tendency (a feature module's own scheme doesn't
automatically get folded into the app scheme's test plan without
deliberate wiring), not a one-off artifact of either specific run.

## `git diff` (untracked files added)

```
?? tests/fixtures/new-project/Projects/
?? tests/fixtures/new-project/Tuist.swift
?? tests/fixtures/new-project/Workspace.swift
```

`Projects/App/Project.swift` (target: `App`, `AppTests`,
`bundleId: com.example.app`, `deploymentTargets: .iOS("17.0")` — fixed
after the initial failure) and `Projects/Features/Home/Project.swift`
(target: `Home`, `HomeTests`) — a two-project + workspace shape, not
this repo's own `templates/feature-modular/` single-project multi-target
shape.

## Rubric scoring — NOT PERFORMED

Deferred to the batch scoring pass (per the same methodology used for
the with-skill runs) — a rescoring pass against this real baseline data
should replace `RUBRIC-SCORES-1-4.md`'s comparison-1 section, which
currently scores the contaminated version.

## Real-artifact pass/fail

| Axis | Result |
|---|---|
| BUILD | PASS (after a self-corrected `deploymentTargets` omission) |
| `tuist generate` | PASS (after a self-corrected manifest-structure issue) |
| TEST (App scheme) | PASS, but incomplete — `HomeTests` excluded, same gap class as the contaminated baseline |
| TEST (Home scheme, run separately) | PASS |
| Workspace.swift justification | Self-reasoned, not skill-guided; a genuinely different structural choice (2 projects + workspace) than the with-skill run's single-project profile reuse |
