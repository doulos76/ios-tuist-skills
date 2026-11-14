# Test-scheme gap report with a CI file in the fixture (2026-11-14)

Follow-up to `../2026-11-14-scheme-report-smoke/README.md`, where `large-graph` had no CI definition and only the "CI test scheme list not found" branch could be observed. This PR adds `tests/fixtures/large-graph/.github/workflows/ci.yml` (commit `874a6b5`: build `App`, then one test step each for `App`, `HomeFeature`, `CheckoutFeature`, `CatalogDomain`, `CoreNetworking`, matching `tests/fixtures/ci-matrix.json`) and reruns scenario 1. **N=1.** Report: `raw/`; final message: `transcripts/claude-run28.md`.

## Setup

- Plugin revision `874a6b5`, Tuist 4.206.0, Claude Code 2.1.325, model `claude-opus-5-5` (CLI JSON; the earlier smoke ran on `claude-fable-5-1`, so the two are not like-for-like). Run 28. Cost **$0.542**, 23 turns, `success`.

## Result

| Check | Outcome |
|---|---|
| Harness: generate / App build / 5 schemes | pass / pass / pass (5 tests) |
| `ios-tuist-result` block | valid, `outcome: completed` |
| Gap report | **yes, with `file:line`**: "CI doesn't run `PricingKitTests`. `.github/workflows/ci.yml` lines 33-53 test only App, HomeFeature, CheckoutFeature, CatalogDomain and CoreNetworking"; same citation in the block's `unverified`; follow-up asks whether to add a `PricingKit` test step |
| CI file edited | no (stated "I didn't edit CI") |
| Edges | `CheckoutFeature`, `SettingsFeature`, `PricingKitTests` -> `PricingKit` with `file:line` usages |

Lines 33-53 are the `-scheme` lines of the five test steps (checked against the file), so the citation is accurate.

## Limits

- N=1, one model. The gap branch fires here; this does not measure how often.
- The fixture now contains a workflow file under `tests/fixtures/`, which GitHub does not run as a repository workflow (same as `ci-gaps`). Changes under `tests/fixtures/large-graph/` select that fixture in the fixture CI matrix; `check-fixture-pins.sh` and `tests/ci/test-select-fixtures.sh` pass locally. The full fixture CI run on the PR is the remaining check.
- The earlier fable-5-1 run and this opus-5-5 run differ in model, so differences in wording say nothing about the fixture change.
