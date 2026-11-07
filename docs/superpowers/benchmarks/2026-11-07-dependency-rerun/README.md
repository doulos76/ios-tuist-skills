# Dependency scenario rerun: Claude, `large-graph` scenario 2 (2026-11-07)

Follow-up to the WS-F trial (`../2026-11-05-large-graph-trial/README.md`), where Claude's `ios-tuist-result` block was **invalid** in the dependency scenario (run 2). Question: does it happen again? **N=3**, one scenario, one agent. Prompt: "Add RetryKit to SearchFeature so its requests can be retried." Expectations: `tests/fixtures/large-graph/EXPECTATIONS.md` scenario 2. Reports: `raw/` (from `scripts/benchmark-isolated-run.sh collect`). Final messages: `transcripts/`.

## Setup

- Plugin revision `d8fb355` (develop after v0.9.2 Tasks 1-2), Tuist 4.206.0, Claude Code 2.1.319, model `claude-opus-5-5` (from the CLI JSON; the harness report says "unrecorded").
- Same command as the trial: `claude -p ... --setting-sources project --plugin-dir <repo> --permission-mode acceptEdits --allowedTools "Read Grep Glob Bash" --max-budget-usd 3 --output-format json`.
- Runs 4-6 (new numbers so the trial evidence is untouched). Cost: $0.316 + $0.338 + $0.382 = **$1.04** (13/18/18 turns, all `success`).

## Results

| Run | Generate / Build / Test (harness) | Changed (excl. generated) | Block | Claimed vs measured |
|---|---|---|---|---|
| 4 | pass / pass / pass (6 tests) | 1 (`Project.swift`) | **valid** | files 1=1, edges 1=1 |
| 5 | pass / pass / pass (6 tests) | 1 | **valid** | files 1=1, edges 1=1 |
| 6 | pass / pass / pass (6 tests) | 1 | **valid** | files 1=1, edges 1=1 |

All three blocks claim `outcome: completed`, `validation: {generate: pass, build: pass, test: not-run}` and `usage: none-found`. The agent ran no tests (runs 4-5: `SearchFeature` has no test target; run 6 lists "Existing test targets were not run" under Unverified). The harness ran the schemes itself and they pass, so the claims are conservative, not wrong.

## Grading against the expectations

- Met (3/3): `.external(name: "RetryKit")` added to `SearchFeature` only; no second `.package` entry (each report says `Tuist/Package.swift` already declared it); nothing under `Packages/`, `.tool-versions` or `productTypes` touched; the edge check ran and reported 1 added edge with no usage found; the report does not call the edge unnecessary.
- Partly met: the expected statement that the product name may differ from the module name when no usage is found (new in v0.9.2 Task 1) appears in 1 of 3 reports. Run 5 says "The product name and module name are both `RetryKit` in its manifest, so I expect it to work". Runs 4 and 6 only say "no usage found" as expected. Whether the script's own caveat line was printed to them is not visible: the JSON output keeps only the final message.

## Findings

1. **Block validity: 3/3 valid.** The trial's invalid block (run 2) did not reproduce.
2. **Cause of run 2 stays unknown.** Run 2's invented keys match the prose "Validation" example in the dependency skill's Output Contract, which suggests it was copied instead of the schema; that reading was never confirmed. Per the plan's decision rule (3/3 valid → one-off), **no skill change** is made.
3. The Output Contract example in `skills/ios-tuist-dependency/SKILL.md` is unchanged and still shows non-schema keys; it remains a plausible risk, not a measured one.

## Limits

- N=3 cannot rule out a rare failure (a 1-in-4 invalid rate would still give 3/3 valid about 42% of the time; this is arithmetic, not a measured rate).
- The conditions are not identical to the trial: plugin revision `c32db1b` -> `d8fb355` (step 9 of `skills/ios-tuist-dependency/SKILL.md` changed in Task 1), Claude Code 2.1.318 -> 2.1.319, and the trial's model was not recorded. A fix from those changes cannot be excluded.
- Only the Claude dependency scenario was rerun; other skills' blocks were not measured here.
