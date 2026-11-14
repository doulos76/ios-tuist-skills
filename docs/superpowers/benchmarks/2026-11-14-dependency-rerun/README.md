# Dependency scenario rerun after the Output Contract example fix (2026-11-14)

Follow-up to `../2026-11-07-dependency-rerun/README.md` (3/3 valid blocks; example in `skills/ios-tuist-dependency/SKILL.md` still showed non-schema keys). This run tests the fixed example (commit `4ad511b`: nine standard section names, plus a schema-shaped `yaml` block example). **N=3**, one scenario, one agent. Prompt: "Add RetryKit to SearchFeature so its requests can be retried." Reports: `raw/`; final messages: `transcripts/`.

## Setup

- Plugin revision `4ad511b`, Tuist 4.206.0, Claude Code 2.1.325, model `claude-opus-5-5` (set with `ANTHROPIC_MODEL`; CLI JSON `modelUsage` confirms it).
- Same command as the 2026-11-07 rerun (`--permission-mode acceptEdits --allowedTools "Read Grep Glob Bash" --max-budget-usd 3`). Runs 22-24. Cost $0.268 + $0.294 + $0.258 = **$0.82** (9/10/8 turns, all `success`).

## Results

| Run | Generate / Build / Test (harness) | Changed (excl. generated) | Block (`parse-skill-result.sh`) | `usage` value in block |
|---|---|---|---|---|
| 22 | pass / pass / pass (6 tests) | 1 (`Project.swift`) | valid | `"no usage found"` |
| 23 | pass / pass / pass (6 tests) | 1 | valid | `"no usage found"` |
| 24 | pass / pass / pass (6 tests) | 1 | valid | `"no usage found"` |

## Findings

1. **Block validity: 3/3 valid**, same as before the fix. The fix did not change validity (it was already 3/3), so this run cannot show that it helps; it shows the fixed example did not break anything the parser checks.
2. **New deviation: `usage` value.** `references/output-contract.md:52` says `usage` is the `file:line` or `none-found`. All three new blocks write `"no usage found"`; all three blocks of the 2026-11-07 rerun (before the fix) wrote `none-found`. The parser does not check this value, so the blocks are "valid" while off-contract. Likely cause (inference, not tested): `SKILL.md:101` names the script's string `no usage found`, and the new example shows only a `file:line` usage, so nothing in the skill shows the `none-found` mapping. The 2026-11-07 runs used an older plugin revision (`d8fb355`) and Claude Code 2.1.319, so version effects are not excluded either.
3. Grading otherwise as before: `.external(name: "RetryKit")` added to `SearchFeature` only, nothing under `Packages/`, `.tool-versions` or `productTypes` touched, one added edge, the edge reported as having no usage yet. The name-mismatch caveat (product name may differ from module name) was not seen in any of the three final messages (1 of 3 in the previous rerun).

## Limits

- N=3; revision, Claude Code version and example text all changed since the last rerun, so finding 2 cannot be pinned on the example alone.
- The final-message JSON hides whether the edge script printed its own caveat line.

## Proposed follow-up (not done)

One line in the dependency skill (or `output-contract.md`) stating that the script's `no usage found` is written as `none-found` in the block, then a small rerun. Needs a go-ahead; it is a second skill edit.
