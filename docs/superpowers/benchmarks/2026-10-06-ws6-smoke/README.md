# WS6 acceptance smoke run (2026-10-06)

Scenario: `extract-candidate`, prompt "Extract the networking code into its own module called NetworkingKit." (identical in every run), run with `scripts/benchmark-isolated-run.sh` (prep / manual session / collect). All sessions started with `--setting-sources project`; with-skill sessions added `--plugin-dir`. Runs: baseline x1, with-skill x3 (run1 on develop f40348a, runs 2-3 on branch feature/v0.8-ws1b with the validation fix). **Model: not recorded** for any run (`BENCH_MODEL=unrecorded`; see run3 session file for what the header showed).

| | baseline run1 | with-skill run1 | with-skill run2 | with-skill run3 (fixed skill) |
|---|---|---|---|---|
| Plugin | none | f40348a (before fix) | feature/v0.8-ws1b | feature/v0.8-ws1b |
| Outcome | extracted | extracted | **refused** (checklist gate, no change) | extracted |
| `App -> NetworkingKit` edge | no | no | n/a | no |
| Baseline `App` test run before changing files | no | no | n/a | **yes (passed)** |
| collect: Resolve/Generate/Build | pass/pass/pass | pass/pass/pass | pass/pass/pass | pass/pass/pass |
| collect: Test (`App` scheme) | pass | **fail** | pass (nothing changed) | pass |
| What the final report said about the `App` scheme | "still succeeds" | "All validation passed" (only the NetworkingKit scheme was run; empty `AppTests` mentioned under Risks) | n/a | **"Validation did NOT fully pass ... App test scheme: FAILED"** |

## Finding 1 - emptied test target and the existing `App` test scheme
With the skill, `App/Tests/AppTests.swift` is moved wholesale, leaving the `AppTests` target with no sources (skill rule: do not delete, report under Risks / Follow-up). The baseline kept a compilable empty shell `AppTests.swift`.
With a source-less `AppTests`, `xcodebuild test -scheme App` is **not deterministic** here: collect run 1 failed (`The bundle "AppTests" couldn't be loaded`, reproduced once separately); in run 3 the model saw "TEST SUCCEEDED" with 0 tests, then the same load failure, then a hang; collect run 3 passed on the identical end state. So `Test: pass` in the harness does not prove that tests ran.
Run 1's skill validated only the new scheme and reported "All validation passed". Fix (branch feature/v0.8-ws1b, `ios-tuist-module`): take a baseline of the pre-existing test schemes before moving code, re-run them afterwards, report any failure with its cause and say plainly that validation did NOT fully pass. Run 3 behaved exactly so. Evidence for the fix is N=1 (one run where the extraction proceeded after the change).

## Finding 2 - outcome variance on this fixture
Same prompt, same fixture, with-skill: run 1 extracted, run 2 refused (it judged ownership/reusability/compile-isolation/test-boundary "not concretely met" for a 3-file single-target app), run 3 extracted. The fixture expects the extraction to proceed, so 1 of 3 with-skill runs deviates. Not explained; not fixed.

## Phase 0 / Step 7b (in-fixture pins only)
**Pass, with caveats.** The with-skill Version Context (runs 1-3) cites `.tool-versions` and nothing from the plugin repo's root CI matrix or workflow. Caveats: only final responses (or a condensed trace) were captured, not full transcripts; the `ios-tuist-module` Output Contract prints a "Version Context" block, not the per-axis Tool Version Evidence table; this fixture has no in-fixture CI files, so "no CI conflicts" is trivially true.

## Measurement caveats
- "changed-file count (including untracked)" includes Tuist generation artifacts (`App.xcodeproj/`, `App.xcworkspace/`, `Derived/`): baseline 7, with-skill 6, versus 3 source files.
- Model not recorded for runs 1-2 (BENCH_MODEL left `unrecorded`); run 3 ambiguous (see its session file).
- N=1-3 per condition on one scenario; not evidence of a skill effect. The baseline also avoided the phantom `App` edge, so this scenario does not separate the conditions on that metric.
