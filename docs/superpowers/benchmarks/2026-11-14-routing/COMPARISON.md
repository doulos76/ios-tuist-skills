# Routing baseline on claude-opus-5-5 — 2026-11-14 vs 2026-10-31

Condition `plugin-only`, N=1 per case, 45 cases (`tests/routing/cases.yaml`, identical `cases_sha256`). Closes the v0.9.2 follow-up "like-for-like baseline on opus-5-5".

| | 2026-10-31 | 2026-11-14 |
|---|---|---|
| Model | `claude-fable-5` | `claude-opus-5-5` (all 215 model fields in `raw/`; set with `ANTHROPIC_MODEL`) |
| Claude Code | 2.1.316 | 2.1.325 |
| Plugin | 0.9.0 | 0.9.2 |
| Budget/case | $0.60 | $0.60 |
| Accuracy | 42/45 (93.3%) | **45/45 (100.0%)** |
| Forbidden-skill violations | 0 | 0 |
| Negative cases selecting a plugin skill | 0 | 0 |
| Cases ending `error_max_budget_usd` | 10 | **0** |
| Rows ending `eof` / `no-output` | 0 / 0 | 0 / 0 |

Stops: 27 at the `Skill` call, 18 at `result` (the 18 `none`-expected cases). In 28 rows `Skill` was the first tool call.

## Per-case changes

The three 10-31 misses (`pos-feature-ko`, `adj-feature-not-module`, `pos-scaffold-en`) now select the expected skill. This matches the 2026-11-07 diagnosis (9/9 on opus-5-5 at $1.20), now also at the default $0.60 budget.

## Limits

- Model, Claude Code version and plugin version all changed against the 10-31 baseline, so the improvement cannot be attributed to the model alone. `git diff v0.9.0..HEAD -- skills/*/SKILL.md` shows no changed `description:` line, so the descriptions are the same as in the 10-31 baseline.
- N=1 per case: 100% does not rule out rare misses.
- 27 of 45 cases stop at the `Skill` call, so their cost is unknown. Known cost: $2.68 over the 18 cases that reached a result.
- Housekeeping: the 32 plan-mode plan files listed in `plugin-only/plans-created.txt` were deleted from `~/.claude/plans` after the run.

## Decision

New baseline for future description-change PRs: **45/45 on `claude-opus-5-5`**. The pass rule (at most 2 cases below baseline) now means at least 43/45 on this model. The 2026-10-31 fable-5 baseline remains valid for runs on that model.
