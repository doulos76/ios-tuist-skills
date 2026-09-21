# PRD: `ios-tuist-skills` Effectiveness Benchmark

- **Status:** Draft for review
- **Date:** 2026-09-20
- **Author:** Claude (this session), at the user's request
- **Purpose:** Answer, per skill, with evidence rather than assertion:
  "does loading this plugin actually change what Claude produces for a
  Tuist task, and is that change better?" — and give the user a
  reusable procedure to re-run this whenever a skill changes.

## 1. Background and motivation

`ios-tuist-skills` has shipped nine skills (v0.1–v0.5; a tenth,
`ios-tuist-scaffold`, is in progress as of this PRD) and ten fixtures,
each validated by CI for one thing only: **the fixture project itself
is real and buildable**. CI does not, and was never designed to, answer
a different question: when a skill actually runs against a task, does
its output differ from — and improve on — what Claude would produce for
the same task with no `ios-tuist-skills` plugin loaded at all?

The user wants this measured directly, modeled on the rubric-based
with-skill/baseline comparison methodology already used in their
`evidence-driven-engineering` project (see
`tests/rubric.md` in that repo) — scored structure, not just a final
pass/fail, plus this repo's own standing bar of *actually running*
`tuist generate`/build/test rather than trusting that generated code
"looks right."

This PRD scopes two phases:

- **Phase 1** (this session, today): a same-repo comparison using this
  repository's own fixtures as the task source — no external project
  needed, runnable in under a session.
- **Phase 2** (future session): applying the same method to one of the
  user's real, external iOS projects — this PRD defines the procedure
  and a worked example structure now, but Phase 2's actual execution is
  out of scope for today per the user's own phasing.

## 2. Goals

- For each of the plugin's skills, produce a documented, reproducible
  comparison: baseline (no plugin) vs. with-skill, on the same task.
- Score each comparison on two independent axes:
  1. **Structural/behavioral rubric** — did the response exhibit the
     specific judgment this skill exists to enforce (refusal
     discipline, version-safety checks, scope discipline, convention
     preservation, etc.), scored 0/1/2 per item, mirroring
     `evidence-driven-engineering`'s rubric shape.
  2. **Real-artifact pass/fail** — does the generated/modified project
     actually `tuist generate`, build, and test successfully; does a
     "should refuse" scenario actually produce a refusal (no file
     changes), not just a response that talks about refusing.
- Produce one per-skill report plus one aggregate summary, saved as
  artifacts the user can review and re-run later.
- Define, but not execute, the Phase 2 procedure for applying this to a
  real external project.

## 3. Non-goals

- Not a general Claude/model benchmark — scoped strictly to whether
  *this plugin's skills* change outcomes on *Tuist-specific* tasks.
- Not a statistically rigorous study. Given the time budget (today,
  one session), this is N=1 per skill per condition — the rubric and
  the `evidence-driven-engineering` precedent this mirrors are explicit
  that a single pass is a weak measurement; this PRD reports findings
  with that caveat stated, not hidden.
- Not a comparison against other Tuist tooling, other plugins, or other
  models.
- Does not modify any existing skill, fixture, or spec as a side effect
  of running the benchmark — a finding that a skill underperforms is a
  reported result, not something this benchmark run silently "fixes."
- Phase 2 (real external project) is scoped (§7) but not executed by
  this PRD.

## 4. Method

### 4.1 Two conditions, one task

For each skill under test:

- **Baseline condition:** a fresh Claude Code session started with
  `--plugin-dir` **omitted** (or pointed at an empty/unrelated
  directory) — no `ios-tuist-skills` `SKILL.md` content is ever loaded
  into context. The user's global `~/.claude/CLAUDE.md` still applies
  (it is a personal, always-on instruction file, not part of this
  plugin) — this isolates the plugin's specific contribution, not
  Claude's general behavior with zero instructions of any kind.
- **With-skill condition:** a fresh Claude Code session started with
  `claude --plugin-dir /path/to/ios-tuist-skills`, same task prompt,
  verbatim.

Both conditions receive the **identical task prompt** and start from
the **identical fixture state** (a fresh copy of the relevant
`tests/fixtures/<name>/` directory — never the same working copy reused
across conditions, to avoid one condition's file changes leaking into
the other).

### 4.2 Task selection: reuse existing fixtures as the task source

Every fixture already has two things this benchmark needs: a real
starting project state, and an `EXPECTATIONS.md` describing the correct
behavior. The benchmark's task prompt for each skill is derived
directly from that fixture's own documented scenario — not invented
fresh — so "correct" is already independently defined before either
condition runs (avoiding the trap of judging correctness in a way that
happens to favor whichever condition ran first).

| Skill | Fixture(s) | Task prompt source |
|---|---|---|
| `ios-tuist-bootstrap` | `new-project` | `EXPECTATIONS.md`'s described new-project request |
| `ios-tuist-feature` | `legacy-tuist`, `version-mismatch` | Scenario B (preserve legacy conventions) and Scenario C (report version mismatch, don't silently reconcile) |
| `ios-tuist-dependency` | `modular` | Scenario D (attach a dependency to the narrowest target) |
| `ios-tuist-module` | `extract-candidate` | Both the extraction-proceeds and extraction-refused paths |
| `ios-tuist-architecture-review` | `architecture-smells` | The documented coupling smell the skill must name without editing anything |
| `ios-tuist-ci` | `ci-gaps` | The documented redundant/uncached workflow gap |
| `ios-tuist-migrate` | `migrate-candidate` | The documented Tuist 3.42.2 → 4.206.0 breaking-change surface |
| `ios-tuist-restyle` | `restyle-candidate` | Both the checklist-clear and checklist-failing targets |
| `ios-tuist-test-target` | `test-target-candidate` | Both the refuse (FeatureA) and create+enroll (FeatureB) paths |
| `ios-tuist-scaffold` | `scaffold-candidate` (v0.6, once merged) | The documented template-authoring scenario |

Each row runs as **one task prompt per documented scenario** — e.g.
`ios-tuist-test-target` and `ios-tuist-restyle` each run twice (their
two documented paths), everything else once — for **12 total
comparisons** (24 individual runs: 12 baseline + 12 with-skill).

### 4.3 Task prompt discipline

The task prompt given to both conditions is the natural-language
request a user would actually type — e.g. "Create a unit test target
for FeatureB and wire it into the existing App scheme" — **never** a
prompt that names the skill, quotes its Decision Rules, or otherwise
leaks the plugin's own instructions into the baseline condition's
context. The baseline condition must fail (or succeed) purely on
Claude's own judgment plus the fixture's real file contents — the
comparison is meaningless if the baseline prompt is secretly scaffolded
toward the same answer the skill would produce.

### 4.4 What gets captured per run

For every one of the 24 runs:

1. The full transcript (or a faithful verbatim excerpt if the harness
   truncates) of the response.
2. A `git diff` of the fixture directory after the run, before any
   cleanup.
3. Real command output: `tuist generate`, `xcodebuild build`, and (where
   the scenario implies it) `xcodebuild test` — actually executed
   against the *result* of that run's changes, not assumed.
4. The fixture directory is reset (`git checkout -- .` / discard) after
   capture, before the next run starts, so no run's state leaks into
   the next.

## 5. Scoring

### 5.1 Structural rubric (per response, 0–2 per item)

Adapted from `evidence-driven-engineering`'s rubric shape, but scoped to
what each `ios-tuist-skills` skill specifically claims to enforce
(its own Decision Rules / Non-Trigger Conditions), rather than a
generic engineering-judgment rubric. Score **every item that applies to
that skill's own Decision Rules** — not every item applies to every
skill (e.g. "refusal correctness" is N/A-full-credit for a scenario
with no refusal path).

1. **Version/convention detection** — Did the response inspect and
   report the project's actual pinned Tuist version and existing
   conventions (naming, folder layout, test framework) before acting,
   rather than assuming defaults?
2. **Scope discipline** — Did the response touch only the target(s)
   the task named, leaving every other target's manifest/source
   byte-identical? (Check against the `git diff`, not the response's
   own claim.)
3. **Refusal correctness (where applicable)** — For a scenario whose
   fixture documents a "should refuse" path: did the response actually
   refuse (zero file changes) rather than proceeding anyway, and did it
   name the specific reason (e.g. "FeatureATests already exists")
   rather than a generic disclaimer?
4. **No invented API** — Did the response use only real, current
   `ProjectDescription` API (verifiable against Tuist's own docs), with
   no plausible-sounding but nonexistent symbol, case, or parameter?
5. **Verification performed, and claimed only what was verified** — Did
   the response actually run (or instruct running) `tuist generate`/
   build/test, and does its final claim of success match what those
   commands actually returned — not a claim of "this should work"?
6. **No unrequested scope creep** — Did the response avoid bundling in
   an unrelated convention change, version bump, or "while I'm here"
   modernization the task didn't ask for?
7. **Output legibility** — Is it possible for a reader to tell, from
   the response alone, exactly what changed, what was verified, and
   what remains unverified — without reading the diff?

Each comparison's baseline and with-skill responses are scored
independently by the same grader (this session, or a fresh
general-purpose subagent per the "avoid biasing scores toward the
expected result" principle `evidence-driven-engineering`'s rubric
itself flags as a known limitation) — the grader should not
pre-decide which response "should" score higher before reading both.

### 5.2 Real-artifact pass/fail (per response)

Independent of the rubric score:

- **BUILD:** does `tuist generate` succeed and does the affected
  scheme/target build, after the response's changes are applied to a
  fresh fixture copy?
- **TEST:** where the scenario implies new/existing tests, do they run
  and pass?
- **REFUSAL:** for a should-refuse scenario, is the `git diff` **empty**
  (proving no file was touched), not merely "the response said it
  refused"?

A response can score well on the rubric and still fail BUILD/TEST (e.g.
syntactically plausible but non-compiling manifest code) — both axes
are reported, never collapsed into one number, so this gap itself is a
finding worth surfacing rather than averaging away.

## 6. Deliverables

1. **This PRD**, committed to `docs/superpowers/specs/`.
2. **One report file per skill comparison** (12 files, or one combined
   file with 12 sections — see Task breakdown), each containing: the
   task prompt used, both responses (or faithful excerpts), the rubric
   scores with brief justification per item, the BUILD/TEST/REFUSAL
   pass-fail results with actual command output, and a one-paragraph
   verdict.
3. **One aggregate summary** — a table of all 12 comparisons' rubric
   totals and pass/fail results, plus the known-limitations caveat
   (N=1 per condition, single grading pass) stated explicitly, mirroring
   `evidence-driven-engineering/tests/rubric.md`'s own "Known
   limitations" section rather than omitting it.
4. Saved under `docs/superpowers/benchmarks/2026-09-20-skill-effectiveness/`
   (a new directory — this is evaluation output, not a spec or a plan,
   so it does not belong under `specs/` or `plans/`).

## 7. Phase 2 (future, not executed today): real external project

Once Phase 1 establishes the method works on this repo's own fixtures,
the same procedure applies to a real project the user actually
maintains, with these adjustments the user will need to make explicit
before Phase 2 starts:

- **Project selection:** a project with an existing Tuist setup (this
  benchmark method assumes Existing Project Mode skills; a from-scratch
  `ios-tuist-bootstrap` comparison could use any empty directory).
- **Isolation:** every run must start from an identical, clean git
  state (a throwaway branch or worktree per run, discarded after
  capture) — never run baseline and with-skill against the same
  uncommitted working tree in sequence.
- **Task selection:** 2–3 real, currently-relevant tasks from the
  user's own backlog for that project (not invented) — each mapped to
  exactly one skill, same task-prompt discipline as §4.3.
- **Scoring:** identical rubric (§5.1) and pass/fail axis (§5.2); the
  real project's own build/test suite stands in for the fixture's
  `EXPECTATIONS.md`.
- **What Phase 1 hands to Phase 2:** the calibrated rubric itself (if
  Phase 1's scoring reveals an item that's ambiguous or doesn't
  discriminate — same "known limitations" pattern
  `evidence-driven-engineering` documented after its own first rubric
  run — Phase 2 uses the corrected version, not the original draft).

This section is the "정당한 예시" (a legitimate worked example of the
procedure) the user asked to have ready — Phase 2's actual execution
is a separate future session's task, not part of today's deliverable.

## 8. Acceptance criteria for Phase 1

- All 12 comparisons (24 runs) captured with real transcripts, real
  diffs, and real command output — no run's BUILD/TEST/REFUSAL result
  is asserted without the actual command output backing it.
- Every comparison scored on both axes (§5.1, §5.2), independently,
  before either score is used to write the verdict paragraph.
- The aggregate summary states the N=1/single-pass limitation
  explicitly, not silently.
- Nothing in this repository's actual skills, fixtures, or CI is
  modified as a side effect of running the benchmark — findings are
  reported, not auto-applied.
