# Test-scheme gap report smoke: Claude, `large-graph` scenario 1 (2026-11-14)

Follow-up to v0.9.2 Task 2 (`references/testing.md`, optional smoke <= $3). Question: when the module skill moves tests into a new `PricingKitTests` target, does the agent now report the CI test-scheme gap? **N=1**, one scenario, one agent. Prompt: scenario 1 of `tests/fixtures/large-graph/EXPECTATIONS.md` ("Extract `PriceFormatter` ... into `PricingKit` ..."). Report: `raw/` (from `scripts/benchmark-isolated-run.sh collect`). Final message: `transcripts/claude-run21.md`.

## Setup

- Plugin revision `d18ebd7` (develop at v0.9.2), Tuist 4.206.0, Claude Code 2.1.325, model `claude-fable-5-1` (from the CLI JSON `modelUsage`; the harness report shows the `BENCH_MODEL` I set).
- Command: `claude -p ... --setting-sources project --plugin-dir <repo> --permission-mode acceptEdits --allowedTools "Read Grep Glob Bash" --max-budget-usd 3 --output-format json`, same as the 2026-11-05 trial.
- Run 21 (new number; trial evidence untouched). Cost **$1.774**, 30 turns, `success`.

## Result

| Check | Outcome |
|---|---|
| Harness: generate / App build / 5 test schemes | pass / pass / pass (1 test per scheme, 5 total) |
| `ios-tuist-result` block | **valid** (`outcome: completed`) |
| Scheme-gap report present | **yes, but only the "not found" branch**: "CI test scheme list not found" appears under Unverified Items, under Risks / Follow-up and in the block's `unverified` |
| Edges | `CheckoutFeature`, `SettingsFeature`, `PricingKitTests` -> `PricingKit`, each with a `file:line` usage; no edge from `App` |
| Forbidden edits | none (`.tool-versions`, `Tuist/`, `Packages/` untouched; `CheckoutFeature`/`LegacyHelpers` not restyled) |

## What this shows and does not show

- **Shows:** the new procedure fires. The agent searched for a CI definition, found none, and reported "not found" in all three places the procedure names, without editing any CI file.
- **Does not show:** the branch that matters most, a CI list that exists but omits `PricingKitTests`, with a `file:line`. The fixture has no CI definition (`find` finds no workflow, Fastfile, `scripts/` or `Makefile` in `tests/fixtures/large-graph`; the "CI matrix" exists only as prose in `EXPECTATIONS.md:45`). So the expectation at `EXPECTATIONS.md:75-79` (report the gap with the CI list's `file:line`) cannot be met by any agent on this fixture. This is a fixture gap, not an agent miss.
- The run was on `claude-fable-5-1`, not `claude-opus-5-5` as in the other v0.9.2 runs, so it is not like-for-like with them.

## Observations

- The agent renamed `CheckoutTests/PriceFormatterTests.swift` to `CartTests.swift` after moving the formatter test out (the remaining test is `Cart`'s). It is disclosed in the report; it was not requested. The 2026-11-05 trial also ended with a `CartTests` file, so this is not new behavior.
- The agent said it ran six test bundles through the workspace scheme; the harness ran the five CI schemes (1 test each) and all passed. Both are consistent.

## Decision

No skill change from this run. Proposed follow-up (not done): give `large-graph` a minimal CI definition that lists the five test schemes (for example `.github/workflows/ci.yml`), then rerun scenario 1 so the `file:line` branch can be observed. That changes a fixture (and may need `check-fixture-pins.sh` review), so it needs a separate go-ahead.
