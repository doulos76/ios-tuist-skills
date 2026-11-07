# Routing miss diagnosis, 2026-11-07

Question: the 2026-10-31 baseline (42/45) missed `pos-feature-ko`, `adj-feature-not-module` and `pos-scaffold-en`. All three selected no skill and ended `error_max_budget_usd` at $0.60 (they explored with Bash/Read, wrote a plan file, then ran out). Is that a budget problem or a description problem?

Method: the three cases only, `plugin-only`, `--budget 1.20`, three separate runs (`run1`-`run3`, each a new `--out`): `scripts/run-routing-eval.sh run --condition plugin-only --only pos-feature-ko,adj-feature-not-module,pos-scaffold-en --budget 1.20 --out <dir>`. Claude Code 2.1.319, plugin 0.9.1, model `claude-opus-5-5`. Cost: the cases stop at the `Skill` call, so the harness records none (3 cases x 3 runs, worst case 9 x $1.20 = $10.80).

## Result

| Case | Run 1 | Run 2 | Run 3 | Hits |
|---|---|---|---|---|
| `pos-feature-ko` (expect feature) | feature | feature | feature | 3/3 |
| `adj-feature-not-module` (expect feature, forbid module) | feature | feature | feature | 3/3 |
| `pos-scaffold-en` (expect scaffold) | scaffold | scaffold | scaffold | 3/3 |

9/9 correct, 0 forbidden-skill violations, 0 anomalies. In every case `Skill` was the **first tool call** (`tools_before_stop: []`), so the budget was never close to binding.

## What this does and does not show

- **Does not support "budget was the cause".** The earlier misses did not end because $0.60 was slightly too little; they never called `Skill` while exploring first. Here the model called it immediately, so a higher cap changed nothing observable.
- **Model differs across the three data sets.** 2026-10-13 miss: `claude-opus-5` (Claude Code 2.1.296, $0.30). 2026-10-31 misses: `claude-fable-5` (2.1.316, $0.60). This run: `claude-opus-5-5` (2.1.319, $1.20). Model, Claude Code version, plugin version and budget all changed, so none of them can be isolated. `pos-feature-ko` also missed on `claude-opus-5` at $0.30, so "newer model only" is not established either.
- **No description evidence.** None of the nine runs picked a wrong skill, and the three descriptions were unchanged between the runs compared. N=3 per case on one model; a rare miss would not show up.

## Decision (per the v0.9.2 plan rule)

- All three cases hit 3/3 (>= 2/3): **no `description:` change**, so the full 45-case rerun that README requires for description changes is not triggered.
- `--budget` default stays $0.60: this run gives no evidence that raising it helps (the cases did not use it). Left as a user decision.
- Open (not done): the 45-case baseline is on `claude-fable-5`; a baseline on `claude-opus-5-5` would make future comparisons like-for-like (up to $27 equivalent; the 10-31 run's known cost was $10.73 over 21 cases). Needs a separate go-ahead.

Housekeeping: the nine plan-mode plan files these runs wrote to `~/.claude/plans` (listed in each `plans-created.txt`) were deleted after the runs. The summaries print "Plan-mode plan files: none" although the files existed; the observer stops at the `Skill` call and does not see them.
