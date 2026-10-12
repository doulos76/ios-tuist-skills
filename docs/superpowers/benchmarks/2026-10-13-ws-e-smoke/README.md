# WS-E smoke run (2026-10-13)

Purpose: v0.9 Task 4 Step 8 — does a real skill run end with a valid `ios-tuist-result` block, and does `collect` parse it (`BENCH_TRANSCRIPT`)?

Scenario: fixture `architecture-smells`, prompt "Review this Tuist project's target graph and dependency direction. Report findings only.", `scripts/benchmark-isolated-run.sh prep … with-skill` (workdir without `EXPECTATIONS.md`), `claude -p --setting-sources project --plugin-dir <repo>` (Claude Code 2.1.296), plugin at branch `feature/v0.9-ws-e`.

| | run1 | run2 |
|---|---|---|
| Permissions | `--permission-mode acceptEdits` | same + `--allowedTools "Read Grep Glob Bash"` |
| Model | not recorded (text output) | `claude-opus-5` (from `--output-format json`) |
| Cost / turns | not recorded | $0.55 / 17, 0 permission denials |
| Skill reads `references/`, runs bundled script | **no** — denied (no approver in headless mode) | yes (`collected_by: script`) |
| Result block | a ` ```yaml ` block with an invented schema | ` ```ios-tuist-result ` per `references/output-contract.md` |
| `collect` verdict | `Block: missing` (`error: no ios-tuist-result block`) | `Block: valid`; claims match measurements (files 0/0, edges 0/0) |
| collect Generate/Build/Test | pass/pass/pass | pass/pass/pass (tests executed: 3) |

Findings:
1. Without permission to read the skill's own `references/` (headless `-p` with no allow-list), the model cannot see the block spec and improvises one. It said so under Unverified Items. The parser correctly rejects it; it was not loosened.
2. With read access the block is valid and consistent with the harness measurements.
3. Implication for evaluation runs (WS-C and later benchmarks): headless runs must allow read-only tools for the plugin directory, or results measure the permission setup rather than the skill.

Files: `raw/` = `collect` reports (`run2.result.json` = parsed block); `transcripts/` = the final responses fed to `BENCH_TRANSCRIPT`.
