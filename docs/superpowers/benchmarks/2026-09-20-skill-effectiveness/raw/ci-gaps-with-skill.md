# Comparison 7 — `ci-gaps` — with-skill

## Task prompt

> Check the CI workflow for tests/fixtures/ci-gaps.

## Condition

Real `claude --plugin-dir /Users/dave/Documents/GitHub/ios-tuist-skills`
session, run by the user in the `.worktrees/benchmark-with-skill`
worktree, fixture freshly reset beforehand via
`scripts/benchmark-prep-run.sh ci-gaps`.

## Fixture

`tests/fixtures/ci-gaps/` — embedded `.github/workflows/ci.yml`
(fixture content, never run by real GitHub Actions) with two
deliberate gaps: a redundant `tuist install` step run twice, and no
dependency caching. Tuist pin (4.206.0) matches the project — no
version mismatch to find here.

## What this response did

- Explicitly invoked `ios-tuist-skills:ios-tuist-ci`.
- Inventoried the workflow's jobs/steps before proposing anything.
- Found both intended gaps with exact evidence: the literal duplicate
  step names ("Resolve dependencies" / "Resolve dependencies again",
  lines 20–24) and the absence of any `actions/cache` step.
- Reasoned concretely about the cache key: no `Package.swift`/
  `Package.resolved` exists in this fixture, so it explicitly chose to
  key the cache on Tuist version + a hash of the manifest files
  (`Project.swift`, `Tuist.swift`) instead — a real judgment call about
  *what actually determines the resolved graph here*, not a
  copy-pasted generic cache recipe.
- **Presented the proposed diff and stopped, asking for explicit
  approval before applying anything** — this is the one specific
  behavior the contaminated baseline explicitly failed on for this same
  fixture. The user was shown a full unified diff and an
  "Apply / Don't apply" choice.
- After approval, applied the diff, then validated for real:
  - YAML syntax valid (Ruby YAML parser — PyYAML/actionlint unavailable
    locally, explicitly disclosed as a limitation on the validation
    method rather than silently skipped).
  - `tuist install`, `tuist generate --no-open`, `xcodebuild build`,
    `xcodebuild test` all run for real, all succeeded.
  - Explicitly disclosed substituting an available simulator (iPhone
    16e / iOS 26.1) for the CI workflow's literal destination string
    ("iPhone 16", default OS) which wasn't installed locally — the
    deployment target (17.0) was still satisfied, stated as the reason
    the substitution is valid.
- Confirmed: Tuist version pin unchanged, no validation step removed,
  no new CI provider introduced — the three explicit "must not happen"
  conditions from `EXPECTATIONS.md`.
- Filed a `SendFeedback` bug report about the Edit tool being blocked
  by an auto-mode classifier issue (an environment/tooling artifact —
  noted here for completeness, not a skill-quality finding; the
  response worked around it by direct file copy and then diffed the
  result to confirm it matched exactly what had been shown for
  approval).

## Real verification performed (as reported)

```
YAML syntax: valid (Ruby YAML parser)
$ tuist install
succeeded

$ tuist generate --no-open
succeeded

$ xcodebuild build
BUILD SUCCEEDED

$ xcodebuild test
TEST SUCCEEDED (1 test passed, run against iPhone 16e / iOS 26.1 —
substituted for the CI workflow's literal "iPhone 16" destination,
which wasn't installed locally; deployment target 17.0 still satisfied)
```

## `git diff`

```diff
diff --git a/tests/fixtures/ci-gaps/.github/workflows/ci.yml b/tests/fixtures/ci-gaps/.github/workflows/ci.yml
index 2692cab..f79e979 100644
--- a/tests/fixtures/ci-gaps/.github/workflows/ci.yml
+++ b/tests/fixtures/ci-gaps/.github/workflows/ci.yml
@@ -17,10 +17,15 @@ jobs:
           tool_versions: |
             tuist 4.206.0
 
-      - name: Resolve dependencies
-        run: tuist install
+      - name: Cache Tuist dependencies
+        uses: actions/cache@v4
+        with:
+          path: ~/.cache/tuist
+          key: ${{ runner.os }}-tuist-4.206.0-${{ hashFiles('**/Project.swift', '**/Tuist.swift') }}
+          restore-keys: |
+            ${{ runner.os }}-tuist-4.206.0-
 
-      - name: Resolve dependencies again
+      - name: Resolve dependencies
         run: tuist install
 
       - name: Generate project
```

## Comparison to contaminated baseline (`ci-gaps-baseline.md`)

| Aspect | Baseline (contaminated) | With-skill |
|---|---|---|
| Findings (redundant step, missing cache) | Found correctly | Found correctly, with more specific cache-key reasoning (explicitly justified keying on manifest hash since no lockfile exists) |
| **Approve-before-apply** | **Applied the fix directly, self-reported as a rubric-relevant miss** | **Stopped, presented the diff, asked for explicit approval before applying anything** |
| Version pin / validation-step / CI-provider guardrails | Respected | Respected, explicitly confirmed in the final report |
| Post-fix validation | YAML valid, BUILD/TEST PASS | YAML valid (with disclosed tooling limitation), BUILD/TEST PASS, plus explicit disclosure of the simulator-destination substitution |

This is the clearest procedural (not just outcome) divergence captured
so far: the contaminated baseline's own report flagged its own
approve-before-apply miss as a real rubric-relevant gap for this exact
fixture. The with-skill run did not make that mistake — it is the
literal behavior `ios-tuist-ci`'s Decision Rules exist to enforce, and
it held here even under the "helpfully just fix it" pull a CI-gap task
naturally creates.

## Rubric scoring — NOT PERFORMED

Deferred to the batch scoring pass after all 14 with-skill runs are
captured.

## Real-artifact pass/fail

| Axis | Result |
|---|---|
| Approve-before-apply discipline | PASS |
| YAML validity post-fix | PASS |
| BUILD | PASS |
| TEST | PASS |
| Guardrails (version pin / validation-step / CI-provider unchanged) | PASS |
