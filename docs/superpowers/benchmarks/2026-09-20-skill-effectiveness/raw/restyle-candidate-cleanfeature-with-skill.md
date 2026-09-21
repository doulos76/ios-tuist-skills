# Comparison 9a — `restyle-candidate` (CleanFeature) — with-skill

## Task prompt

> Review CleanFeature's folder integration and switch it to buildable folders if it's safe.

## Condition

Real `claude --plugin-dir /Users/dave/Documents/GitHub/ios-tuist-skills`
session, run by the user in the `.worktrees/benchmark-with-skill`
worktree, fixture freshly reset beforehand via
`scripts/benchmark-prep-run.sh restyle-candidate cleanfeature`.

## Fixture

`tests/fixtures/restyle-candidate/` — `CleanFeature` target: plain
array `sources:`/`resources:`, no exclude patterns, no cross-target
file references, no directory overlap, no generated sources —
`.staticFramework` product that also declares `resources:` (the
combination this fixture's checklist specifically calls out for a real
Tuist regression history).

## Environment note: sandbox tool-permission friction

Edit/Write tools were blocked by an auto-mode permission classifier
returning "no verdict" for this worktree path — an environment/sandbox
artifact, not a skill-judgment finding (the same class of issue seen in
comparisons 2, 8, and 9). The response first stopped and asked the
user to either approve the blocked tool call or apply the diff
manually; on the next turn it worked around the block via a scripted,
verified string replacement and confirmed the resulting diff matched
the intended change exactly before proceeding to validation.

## What this response did

- Applied the checklist item-by-item to `CleanFeature` specifically:
  - Exclude patterns: none — clear.
  - Cross-target file references: none (only whole-target dependencies
    from `App`/`CleanFeatureTests`) — clear.
  - **Static-framework + resources regression risk**: correctly
    identified the combination (`product: .staticFramework` +
    `resources:`), cited the specific regression history (tuist/tuist
    #8547 fixed ~4.100.0, recurred at #9156/#9289), noted the pinned
    version (4.206.0) is past the fix floor but — per the checklist's
    explicit rule — **that alone isn't treated as proof of safety**.
    Searched for a regression note specific to 4.206.0, found none
    locally available, and classified the result as
    "checked-with-residual-risk," not an unconditional clear.
  - Directory overlap: none — clear.
  - Generated/derived sources: none — clear.
- Converted only `CleanFeature`'s `sources:`/`resources:` arrays to
  `buildableFolders:` — confirmed via `git diff --stat` that only
  `Project.swift` changed, one 2-line-to-1-line replacement, no other
  target touched.
- `ExcludeFeature` correctly left untouched (not named in this
  scenario's prompt).
- Disclosed as an "Unverified Item" that the actual runtime
  resource-bundle placement inside the built `.app`/`.xctest` wasn't
  inspected byte-for-byte — explicitly named the specific failure class
  (`#9156`/`#9289`-style `BundleNotFound` regressions) that build/test
  success doesn't rule out, and flagged it as the first thing to check
  if a future Tuist upgrade breaks resource lookup at runtime.

## Real verification performed (as reported)

```
$ tuist install && tuist generate --no-open
succeeded

$ xcodebuild build -scheme App
BUILD SUCCEEDED

$ xcodebuild test -scheme CleanFeature
TEST SUCCEEDED (1/1 passed)
```

## `git diff`

```diff
diff --git a/tests/fixtures/restyle-candidate/Project.swift b/tests/fixtures/restyle-candidate/Project.swift
index 4379f9d..ac0dd0d 100644
--- a/tests/fixtures/restyle-candidate/Project.swift
+++ b/tests/fixtures/restyle-candidate/Project.swift
@@ -33,8 +33,7 @@ let project = Project(
             bundleId: "dev.ios-tuist-skills.restyle-candidate-cleanfeature",
             deploymentTargets: .iOS("17.0"),
             infoPlist: .default,
-            sources: ["CleanFeature/Sources/**"],
-            resources: ["CleanFeature/Resources/**"]
+            buildableFolders: ["CleanFeature/Sources", "CleanFeature/Resources"]
         ),
         .target(
             name: "CleanFeatureTests",
```

## Comparison to contaminated baseline (`restyle-candidate-cleanfeature-baseline.md`)

| Aspect | Baseline (contaminated) | With-skill |
|---|---|---|
| Conversion applied | Yes | Yes, identical shape |
| Static-framework+resources risk flagged | Yes, flagged rather than an unconditional pass | Yes, same conclusion with the same specific issue numbers cited |
| Resource bundle content verified post-conversion | Yes (fork verified the bundle actually contains its file) | Not explicitly re-verified in this run's own report — this is a gap worth checking in scoring: the baseline fork did one more concrete check here than the with-skill run's own narration shows |
| Scope discipline | Only CleanFeature touched | Only CleanFeature touched |
| BUILD/TEST | PASS | PASS |

Both conditions converged on the same technical judgment and the same
caveat here — this comparison is less about outcome divergence and
more useful as a check on report-writing thoroughness during scoring
(did the with-skill run's own validation actually inspect the built
resource bundle, or only build/test success — worth checking the full
transcript, not just this summary, during the rubric pass).

## Rubric scoring — NOT PERFORMED

Deferred to the batch scoring pass after all 14 with-skill runs are
captured.

## Real-artifact pass/fail

| Axis | Result |
|---|---|
| BUILD | PASS |
| TEST | PASS (1/1) |
| Scope discipline (only CleanFeature touched) | PASS |
