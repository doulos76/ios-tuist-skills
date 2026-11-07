# WS-F trial: `large-graph` fixture (2026-11-05)

Trial only: **N=1 per scenario and agent**. A single result is not evidence of a trend. Scenarios and expectations: `tests/fixtures/large-graph/EXPECTATIONS.md`. Reports: `raw/` (from `scripts/benchmark-isolated-run.sh collect`). Final messages: `transcripts/`.

## Setup

- Plugin revision `c32db1b` (develop, plugin 0.9.0), Tuist 4.206.0 (`.tool-versions`), Xcode 27.1, Swift 6.4.
- Claude: Claude Code 2.1.318, `--setting-sources project --plugin-dir <repo> --permission-mode acceptEdits --allowedTools "Read Grep Glob Bash" --max-budget-usd 3`. Cost: $2.08 + $1.01 + $1.42 = **$4.51**.
- Codex: codex-cli 0.166.0, `codex exec --disable plugins -s workspace-write` (skills from `.agents/skills`). Codex cannot rely on its sandbox to run `tuist`/`xcodebuild`; `collect` verifies the result and the sandbox was not widened.
- Runs 1-3 = Claude scenarios 1-3, runs 11-13 = Codex scenarios 1-3.

## Results (harness: `collect`)

| Run | Agent | Scenario | Generate / Build / Test | Tests executed | Changed (excl. generated) | `ios-tuist-result` block |
|---|---|---|---|---|---|---|
| 1 | Claude | 1 module | pass / pass / pass | 5 | 7 | valid |
| 11 | Codex | 1 module | pass / pass / pass | 5 | 8 | valid |
| 2 | Claude | 2 dependency | pass / pass / pass | 6 | 1 | **invalid (schema)** |
| 12 | Codex | 2 dependency | pass / pass / pass | 6 | 1 | valid (`outcome: partial`) |
| 3 | Claude | 3 review | pass / pass / pass | 6 | 0 | valid |
| 13 | Codex | 3 review | pass / pass / pass | 6 | 0 | valid |

## Grading against the expectations

**Scenario 1 (module extraction)** - both agents produced the same manifest shape.
- Met (both): `PricingKit` target with `buildableFolders: ["PricingKit/Sources"]` (an existing convention); consumer edges only from `CheckoutFeature` and `SettingsFeature` (plus `PricingKitTests` -> `PricingKit`); `subscriptionPrice` uses `PriceFormatter`; `CheckoutFeatureTests` not emptied (`CartTests` stays); no change to `.tool-versions`, `Tuist/`, `Packages/`; no restyle of `CheckoutFeature`/`LegacyHelpers`; generate, App build and all five existing schemes pass.
- Met (Claude only): checklist applied in the report (concrete reuse: `SettingsViewModel.subscriptionPrice` was a copy) and the linkage choice explained (`transcripts/claude-run1.md`).
- Missed (Codex): its final message does not show the checklist, the two cited users or the folder-style choice (`transcripts/codex-run11.md`); the manifest result is correct, the report is thin.
- Observation (both): the moved `PriceFormatterTests` live in `PricingKitTests`, which is not one of the five CI test schemes. Tests executed fell from 6 to 5 and `CheckoutFeature` from 2 to 1. Coverage is kept in the repo but not in the CI matrix; neither agent mentioned a new test scheme.

**Scenario 2 (dependency addition)**
- Met (both): `.external(name: "RetryKit")` added to `SearchFeature` only, one line, no second `.package` entry, no edits under `Packages/`, `.tool-versions` or `productTypes`.
- Claude: states the package was already declared and that nothing else was touched; the block is **invalid** (`raw/large-graph-with-skill-run2.md`: missing `outcome`, `version_evidence`, `dependency_edges_added/removed`, `unverified`; unknown `status`, `tuist_pinned`, `dependency`, ...; `validation` not in the required shape). It also states honestly that no file in `SearchFeature/Sources` imports RetryKit yet (`transcripts/claude-run2.md:31`).
- Codex: honest about limits: `usage: none-found`, `outcome: partial`, generate/build claimed `fail` because the sandbox could not write Tuist's session directory. `collect` shows generate/build/test pass, so the claim was an environment limit, not a defect in the change. Block valid.

**Scenario 3 (architecture review, no edits)** - both: working tree empty, no file modified, `App` -> `CoreUtilities`/`LegacyHelpers` assessed, "Not Flagged" present.

| Expected finding | Claude (run 3) | Codex (run 13) |
|---|---|---|
| `SearchFeature` -> `CoreNetworking` / `requestDescription` bypasses `CatalogDomain` | **missed** | **missed** |
| Price formatting duplicated (Checkout vs Settings) | **missed** | found |
| `LegacyHelpers` inconsistent (dynamic, `sources:` glob, `com.example.` bundle ID) | found (dynamic framework, `com.example.` bundle ID); `sources:` glob of `LegacyHelpers` not mentioned | partial (dynamic framework only) |

Both added findings that are not in the expected list (unused `CoreUI` edge on `CheckoutFeature`, unused `RetryKit` package). They are traceable to the fixture, so they do not violate "must not happen", but each agent also reports a different subset.

## Findings

1. Manifest edits are reliable on this 16-target graph: scenarios 1 and 2 passed in both agents with minimal diffs and no forbidden edits.
2. Block validity: Codex 3/3 valid, Claude 2/3 valid (PRD open question 4: Codex can produce a valid block). The Claude failure is on the smallest scenario; with N=1 this may be noise, but it contradicts the all-valid WS-E smoke result and is worth a repeat run. *Repeat (2026-11-07, N=3): all three blocks valid; cause of this failure unconfirmed, see `../2026-11-07-dependency-rerun/README.md`.*
3. Review quality differs per run and both missed the planned `SearchFeature` finding. Review output is the least stable result in this trial.
4. The moved-test CI gap (scenario 1) is a skill gap to consider: extracting tests into a new target should prompt a test-scheme decision.
5. Codex's reported `fail` in run 12 and the claimed pass in run 11 show the sandbox is not a stable verifier; keep using `collect`.

## Limits

N=1 per cell; one fixture; synthetic project; Claude and Codex sessions differ in tooling, so cross-agent differences are not a ranking. Model names were unrecorded by the harness.
