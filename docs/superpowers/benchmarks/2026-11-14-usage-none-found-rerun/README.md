# Dependency rerun: `usage: none-found` mapping (2026-11-14)

Follow-up to `../2026-11-14-dependency-rerun/README.md` (finding 2: all three blocks wrote `usage: "no usage found"`, the contract says `none-found`). Change under test (commit `17783ea`): step 9 of `skills/ios-tuist-dependency/SKILL.md` now says to write `usage: none-found` in the `ios-tuist-result` block for an edge with no usage; the script's `no usage found` wording stays in the prose sections. **N=3**, same scenario and command as the previous rerun. Reports: `raw/`; final messages: `transcripts/`.

## Setup

- Plugin revision `17783ea`, Tuist 4.206.0, Claude Code 2.1.325, model `claude-opus-5-5` (CLI JSON). Runs 25-27. Cost $0.253 + $0.255 + $0.268 = **$0.78** (8/8/8 turns, all `success`).

## Results

| Run | Generate / Build / Test (harness) | Changed (excl. generated) | Block | `usage` in block |
|---|---|---|---|---|
| 25 | pass / pass / pass (6 tests) | 1 (`Project.swift`) | valid | `none-found` |
| 26 | pass / pass / pass (6 tests) | 1 | valid | `none-found` |
| 27 | pass / pass / pass (6 tests) | 1 | valid | `none-found` |

3/3 blocks use the contract value (before the sentence: 0/3 in `../2026-11-14-dependency-rerun`; before the example change: 3/3 in `../2026-11-07-dependency-rerun`).

## Limits

- N=3, one scenario, one model. Same plugin/CLI as the previous rerun except this one sentence, so the change is the likely cause, but it was not isolated beyond that.
- The parser still does not check the `usage` value; conformance relies on the skill text. Other skills that report added edges (`ios-tuist-module`, `ios-tuist-feature`) were not changed or measured here; the 2026-11-05 trial's module blocks used `file:line` usages only.
