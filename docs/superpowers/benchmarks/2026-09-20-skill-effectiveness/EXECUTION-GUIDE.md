# Phase 1 Benchmark — Execution Guide

Companion to `docs/superpowers/specs/2026-09-20-skill-effectiveness-benchmark-prd.md`.
Read the PRD first — this file is just the runbook for the 24 runs (12
comparisons × baseline + with-skill).

## Why this is a manual runbook, not an automated script

A spike confirmed: a `general-purpose` subagent launched from *this*
session does **not** see any `ios-tuist-*` skill in its own skills
listing — this plugin is loaded into this session only via
`--plugin-dir`, and that does not propagate to subagents. So:

- **Baseline** condition = any fresh Claude Code session with no
  `--plugin-dir` pointed at this repo. A subagent works for this, but a
  plain terminal session works too and is simpler to keep consistent
  with the with-skill runs below.
- **With-skill** condition = a fresh Claude Code session started with
  `claude --plugin-dir /Users/dave/Documents/GitHub/ios-tuist-skills`.
  This **cannot** be automated from inside this session — it requires a
  separate `claude` process. You (the user) run these 12, and the 12
  baseline runs, in separate terminal tabs/windows.

## ⚠️ Baseline isolation gap found — read before running any baseline

A real baseline rerun (2026-09-21) found that **"no `--plugin-dir`" is
not sufficient isolation** for the baseline condition, and the first
attempt at a full rerun was abandoned after 3/14 comparisons because of
it. Full account in `AGGREGATE-SUMMARY.md`'s "Real-baseline rerun:
attempted and abandoned" section — summary here:

`--plugin-dir` only controls whether `SKILL.md` content is
*automatically injected into context*. It does not, and cannot, stop
an agentic `claude` session running with this repo (`ios-tuist-skills`)
as its working directory from **independently discovering and reading**
`skills/`, `references/`, or this repo's own `CLAUDE.md`/project-memory
files, if it goes looking — and a capable session investigating an
unfamiliar fixture has every reason to go looking. Across 3 attempted
baseline reruns, contamination got strictly worse: fixture 1
(`new-project`, empty starting state — nothing in the fixture pointed
elsewhere) stayed genuinely clean; fixture 2 (`legacy-tuist`) read
project memory and *inferred the matching skill's name* before being
told to proceed without it; fixture 3 (`version-mismatch`) went
further and **read the skill's own files directly**, reasoning "this is
effectively what's being asked."

**Do not rerun baseline comparisons using the steps below (as
originally written) and expect clean results.** Before attempting
another rerun, fix the isolation gap — the two options considered:

- **(a) Detached fixture copy:** copy just the target
  `tests/fixtures/<name>/` directory to a location entirely outside
  this repo (e.g. `/tmp/baseline-<name>/`) and launch the baseline
  `claude` session there, so `skills/`, `references/`, and this repo's
  `CLAUDE.md` are physically unreachable, not merely unloaded.
- **(b) Explicit no-exploration instruction:** tell the baseline
  session up front not to read any file outside its current working
  directory — weaker than (a) since it relies on the session actually
  following the instruction rather than making read access structurally
  impossible.

Option (a) is the only one that was validated as reliable by this
finding — (b) was not tested. Until one of these is adopted, treat any
new baseline run the same way the 3 reruns above were treated: capture
it, but label its contamination level explicitly and do not fold it
into scoring without that caveat.

## Setup already done

Three worktrees exist under `.worktrees/`, all off `develop` @ `c298d21`:

| Worktree | Branch | Purpose |
|---|---|---|
| `.worktrees/benchmark-baseline` | `benchmark/baseline-scratch` | Run the 12 baseline (no-plugin) tasks here |
| `.worktrees/benchmark-with-skill` | `benchmark/with-skill-scratch` | Run the 12 with-skill tasks here |
| `.worktrees/benchmark-report` | `docs/skill-effectiveness-benchmark-phase1` | Where the 13 report files get written and committed |

Each of `benchmark-baseline` and `benchmark-with-skill` has the full
repo, including `tests/fixtures/`. Every fixture directory in both
worktrees starts **byte-identical** to `develop` — reset with `git
checkout -- tests/fixtures/<name>` between runs (see per-run steps
below), never reuse a dirtied copy.

## The 12 comparisons

Each row = one baseline run + one with-skill run, both against the
**same fixture directory**, both given the **exact prompt** below
verbatim (never paraphrase, never mention "skill" or this plugin's
name — see PRD §4.3).

| # | Fixture | Prompt (type exactly this) |
|---|---|---|
| 1 | `new-project` | Create a new SwiftUI iOS app using Tuist with a feature-modular structure. |
| 2 | `legacy-tuist` | Add LoginFeature. |
| 3 | `version-mismatch` | Add a simple settings screen to this project. |
| 4 | `modular` | Add Kingfisher only to ProfileFeature. |
| 5a | `extract-candidate` | Extract the networking code into its own module called NetworkingKit. |
| 5b | `extract-candidate` | Extract SettingsRow into its own module. |
| 6 | `architecture-smells` | Review this project's architecture. |
| 7 | `ci-gaps` | Check the CI workflow for tests/fixtures/ci-gaps. |
| 8 | `migrate-candidate` | Migrate this project's Tuist manifests from 3.42.2 to 4.206.0. |
| 9a | `restyle-candidate` | Review CleanFeature's folder integration and switch it to buildable folders if it's safe. |
| 9b | `restyle-candidate` | Review ExcludeFeature's folder integration and switch it to buildable folders if it's safe. |
| 10a | `test-target-candidate` | Create a unit test target for FeatureA and wire it into the existing App scheme. |
| 10b | `test-target-candidate` | Create a unit test target for FeatureB and wire it into the existing App scheme. |
| 11 | `scaffold-candidate` | Add a scaffold template that generates a labeled-enum Swift file from a name. |

That's 14 comparisons across 11 fixtures (`extract-candidate`,
`restyle-candidate`, and `test-target-candidate` each contribute two
scenarios; the other 8 fixtures contribute one each) — 28 total runs
(14 baseline + 14 with-skill). The PRD (§4.2) was corrected in place to
match this count; see its inline note if you're comparing against an
earlier read of that file.

## Per-run steps (repeat for each of the 28 runs)

1. **Reset the fixture** in the worktree you're about to use:
   ```bash
   cd /Users/dave/Documents/GitHub/ios-tuist-skills/.worktrees/benchmark-baseline   # or benchmark-with-skill
   git checkout -- tests/fixtures/<name>
   git clean -fd tests/fixtures/<name>   # remove any untracked files a prior run left
   ```
2. **cd into the fixture directory itself** (the task prompt is a
   request about "this project" — the session's working directory
   should be the fixture root, not the repo root):
   ```bash
   cd tests/fixtures/<name>
   ```
3. **Launch the session:**
   - Baseline: `claude` (no `--plugin-dir`)
   - With-skill: `claude --plugin-dir /Users/dave/Documents/GitHub/ios-tuist-skills`
4. **Paste the exact prompt** from the table above. Let it run to
   completion (including any verification it performs on its own).
5. **Capture, before resetting anything:**
   - The full response (copy/paste or `claude` transcript export).
   - `git diff` of the fixture directory (`git -C
     /Users/dave/Documents/GitHub/ios-tuist-skills/.worktrees/<worktree>
     diff -- tests/fixtures/<name>` from a separate terminal, or `git
     diff` from inside the fixture dir).
   - If the response claims to have run `tuist generate`/build/test,
     re-run those yourself right after and capture the real output —
     don't trust the transcript's claim. From the fixture directory:
     ```bash
     mise exec tuist@<pinned-version> -- tuist install
     mise exec tuist@<pinned-version> -- tuist generate --no-open
     xcodebuild build -scheme <scheme> -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
     xcodebuild test -scheme <scheme> -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
     ```
     (pinned version and scheme name are in each fixture's own
     `Tuist.swift`/`.tool-versions` and `EXPECTATIONS.md`.)
6. **Save the capture** into
   `docs/superpowers/benchmarks/2026-09-20-skill-effectiveness/raw/<fixture>-<scenario>-<baseline|with-skill>.md`
   in the **`benchmark-report` worktree** (not baseline/with-skill — keep
   captures out of the scratch branches so they never get discarded).
7. **Reset the fixture again** (repeat step 1) so the next run starts
   clean.

## After all 28 runs are captured

Come back to this session (or hand the 28 raw capture files to a fresh
session) to:
1. Score every response on the §5.1 rubric and §5.2 pass/fail axis.
2. Write the 14 per-comparison report files + 1 aggregate summary into
   `docs/superpowers/benchmarks/2026-09-20-skill-effectiveness/` in the
   `benchmark-report` worktree.
3. Commit and open a PR from `docs/skill-effectiveness-benchmark-phase1`
   into `develop`.

## Cleanup

Once the benchmark is fully reported and merged, remove the scratch
worktrees (they carry no history worth keeping — `benchmark-baseline`
and `benchmark-with-skill` are throwaway by design):

```bash
cd /Users/dave/Documents/GitHub/ios-tuist-skills
git worktree remove .worktrees/benchmark-baseline
git worktree remove .worktrees/benchmark-with-skill
git branch -D benchmark/baseline-scratch benchmark/with-skill-scratch
```

Keep `.worktrees/benchmark-report` until its PR is merged, then remove
it the same way.
