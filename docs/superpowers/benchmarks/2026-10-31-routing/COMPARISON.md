# Routing re-baseline — 2026-10-31 vs 2026-10-13

Condition `plugin-only`, N=1 per case, 45 cases (`tests/routing/cases.yaml`, identical `cases_sha256`; plugin 0.9.0 in both).

| | 2026-10-13 | 2026-10-31 |
|---|---|---|
| Claude Code | 2.1.296 | 2.1.316 |
| Observer | stops at first Write (plan files counted as writes) | records plan-mode plan files, keeps reading (v0.9.x Task 1) |
| Budget/case | $0.30 | $0.60 |
| Accuracy | 42/45 (93.3%) | 42/45 (93.3%) |
| Forbidden-skill violations | 0 | 0 |
| Negative cases selecting a plugin skill | 0 | 0 |
| Rows ending `eof` / `no-output` | — | 0 / 0 |

## Per-case changes

| Case | Expected | 10-13 | 10-31 |
|---|---|---|---|
| `pos-testtarget-en` | test-target | none (budget hit) | test-target |
| `pos-scaffold-en` | scaffold | scaffold | none (budget hit after plan-file write) |

All other 43 cases select the same skill as before. Remaining misses are `pos-feature-ko`, `adj-feature-not-module` (both runs) and `pos-scaffold-en` (new); `pos-testtarget-en` is fixed. The seven cases that used to end at `write-tool` (`adj-feature-not-module`, `off-migrate-xcode-ko`, `off-generate-and-test`, `amb-latest-ko`, `amb-latest-tooling`, `amb-version-warning-ko`, `amb-modernize`) now end at `result`; none selected a plugin skill that is forbidden, so their classification (correct or miss) is unchanged.

## Budget confound (first attempt)

A first run at the old $0.30 budget scored 39/45: 20 cases ended with `error_max_budget_usd` (5 in the 10-13 run), including four positives (`pos-bootstrap-en/ko`, `pos-feature-en`, `pos-scaffold-ko`) that were cut off before choosing a skill. Claude Code 2.1.316 spends more per case than 2.1.296, so $0.30 is no longer enough. That run is not kept in the repo. The $0.60 run still has 10 budget-capped cases (`pos-feature-ko`, `pos-scaffold-en`, `adj-feature-not-module`, `off-generate-fails-ko`, `off-cache-compare`, `off-flaky`, `amb-latest-ko`, `amb-latest-tooling`, `amb-version-warning-ko`, `amb-modernize`); two of them are misses. Treat the two misses that differ from 10-13 as run-to-run noise plus budget, not a description regression. Suggested follow-up: make `--budget` default 0.60.

## Limits

- N=1 per case: a single flip is not evidence of a regression or an improvement.
- Different Claude Code version than the old baseline.
- 24 of 45 cases stop at the `Skill` call, so their cost is unknown.

## Pass threshold proposal (PRD open question 3) — for the user to decide

A routing run passes when:

1. forbidden-skill violations = 0;
2. accuracy is not lower than the latest baseline by more than 2 cases;
3. no `negative` case selects a plugin skill;
4. (added after this run) fewer than 6 rows ended with `eof`, and the run records its budget.

This run meets 1–3. Not yet adopted; README records the rule only after the user answers.
