# Phase 1 Benchmark — Aggregate Summary

Status: **All 28 runs captured (14 baseline + 14 with-skill). All 14
comparisons rubric-scored (PRD §5.1) and real-artifact scored (§5.2).**

See:
- PRD: `docs/superpowers/specs/2026-09-20-skill-effectiveness-benchmark-prd.md`
- Execution guide: `docs/superpowers/benchmarks/2026-09-20-skill-effectiveness/EXECUTION-GUIDE.md`
- Raw per-run captures: `docs/superpowers/benchmarks/2026-09-20-skill-effectiveness/raw/`
- Full rubric tables with per-item justifications:
  `RUBRIC-SCORES-1-4.md`, `RUBRIC-SCORES-5-8.md`, `RUBRIC-SCORES-9-11.md`,
  `RUBRIC-SCORES-12-14.md` (each scored by an independent grading pass —
  a fresh `general-purpose` subagent per batch, reading only that
  batch's raw files, with no access to other batches or this summary)

## Known limitations — read before drawing conclusions

1. **All 14 baseline responses are CONTAMINATED.** They were generated
   by Claude sessions/subagents that, earlier in this same
   conversation, had read every `ios-tuist-*` `SKILL.md` and every
   fixture's `EXPECTATIONS.md` multiple times. This is explicitly *not*
   the PRD's defined baseline condition (a fresh `claude` session with
   no `--plugin-dir` and no prior exposure). **Every baseline score in
   this document should be read as an upper bound on a naive baseline's
   likely performance, not a representative sample of one.** A real,
   uncontaminated baseline rerun is still required before this
   benchmark's conclusions can be treated as PRD-conformant evidence —
   see `EXECUTION-GUIDE.md`.
2. **N=1 per condition per comparison, single grading pass.** As the
   PRD itself states (§3, §8), this is a weak measurement design by
   construction — one run per condition, no statistical repeats. Every
   verdict below describes 28 specific artifacts, not a general claim
   about the plugin's effect size.
3. **14 comparisons, not 12** — the PRD's original §4.2 draft
   undercounted (`extract-candidate`, `restyle-candidate`, and
   `test-target-candidate` each have two documented scenarios, not just
   the latter two); corrected in the PRD and reflected here.
4. Rubric scoring was done by 4 independent `general-purpose` subagents
   (not this session directly), each scoring a disjoint batch of
   comparisons from the raw files alone, per PRD §5.1's own
   bias-avoidance instruction ("should not pre-decide which response
   'should' score higher before reading both"). This session did not
   pre-score or bias the graders' batches.

## Rubric score summary (PRD §5.1, 7 items, 0–2 each, N/A = full credit)

| # | Comparison | Baseline (contaminated) | With-skill | Higher | Real-artifact outcome |
|---|---|---|---|---|---|
| 1 | new-project | 8/12 | 12/12 | **With-skill** (wide) | Both BUILD/TEST PASS, but baseline's TEST claim was incomplete (a feature test silently excluded from the scheme) |
| 2 | legacy-tuist | 10/12 | 12/12 | **With-skill** | Both BUILD/TEST PASS |
| 3 | version-mismatch | 7/12 | 12/12 | **With-skill** (widest gap) | Both BUILD/TEST PASS, but baseline never detected/reported the version mismatch this fixture exists to test |
| 4 | modular | 10/12 | 11/12 | **With-skill** (narrow rubric, decisive real-artifact) | Baseline **BUILD FAIL / TEST FAIL** (unconstrained Kingfisher hit an iOS-13-floor incompatibility); with-skill BUILD/TEST PASS (explicit version constraint avoided it) |
| 5a | extract-candidate (networking) | 11/12 | 9/12 | **Baseline** | Both BUILD/TEST PASS; with-skill added a real, independently-confirmed unrequested dependency edge (`App -> NetworkingKit`) nothing in `App` actually uses |
| 5b | extract-candidate (SettingsRow) | 11/12 | 11/12 | Comparable | Both REFUSAL PASS; baseline additionally reverified the untouched fixture's BUILD/TEST |
| 6 | architecture-smells | 11/12 | 11/12 | Comparable | Both zero-edit PASS; baseline ran real BUILD/TEST, with-skill's finding was more precise (proved via grep, not just cited) |
| 7 | ci-gaps | 11/12 | 12/12 | **With-skill** | Both BUILD/TEST PASS; baseline applied its fix **without** presenting the diff for approval (self-reported gap), with-skill stopped and got explicit approval first |
| 8 | migrate-candidate | 12/12 | 11/12 | **Baseline** (by 1) | Both BUILD/TEST PASS; with-skill's *initial plan* proposed editing this repo's real CI config before a human redirected it — baseline never proposed that |
| 9a | restyle-candidate (CleanFeature) | 12/12 | 11/12 | **Baseline** (by 1) | Both BUILD/TEST PASS; baseline additionally inspected the built resource bundle's actual contents, with-skill left that specific check as "Unverified" |
| 9b | restyle-candidate (ExcludeFeature) | 12/12 | 11/12 | **Baseline** (by 1) | Both REFUSAL PASS; baseline additionally ran a real pre-conversion BUILD/TEST as empirical proof, with-skill reasoned to the same conclusion without that run |
| 10a | test-target-candidate (FeatureA) | 8/8 | 7/8 | **Baseline** (by 1) | Both REFUSAL PASS; baseline reverified BUILD/TEST against the unmodified fixture, with-skill explicitly skipped that as unnecessary |
| 10b | test-target-candidate (FeatureB) | 12/12 | 12/12 | **Tie** | Both BUILD/TEST PASS, near-identical diffs |
| 11 | scaffold-candidate | 11/12 | 11/11* | Comparable / ambiguous | Both real scratch-copy `tuist scaffold` executions PASS; **genuine interpretive divergence, not a defect** — see below |

*Comparison 11's totals aren't directly summable (see `RUBRIC-SCORES-12-14.md`'s own note) — read the per-item table, not the fraction.

**Score tally:** With-skill scored strictly higher in 5/14 comparisons,
baseline scored strictly higher in 5/14, and 4/14 were ties or
essentially comparable (≤1 point apart, no real-artifact divergence).

## Reading the mixed result correctly

This is **not** a simple "the skill wins" or "the skill loses" outcome,
and the raw score tally above would be misleading read alone — the
*kind* of gap matters:

### Where with-skill's advantage reflects real skill design intent

- **version-mismatch (widest gap, 12 vs 7):** this fixture's entire
  documented purpose is testing whether a Tuist version mismatch gets
  silently glossed over. The contaminated baseline's own report states
  its correct real-world outcome was an *accident* of `mise`'s
  directory auto-switching — the response itself never detected or
  disclosed the mismatch. With-skill explicitly detected it, reported
  it with a ⚠️ marker, and enforced the pinned version via `mise exec
  tuist@<pin> --`. This is the clearest evidence in the whole benchmark
  that the skill changes behavior in exactly the way it's designed to.
- **ci-gaps:** the contaminated baseline applied its fix directly and
  self-reported skipping the approve-before-apply step; with-skill
  stopped, presented the diff, and got explicit approval — the literal
  behavior `ios-tuist-ci`'s Decision Rules exist to enforce, holding up
  under the "just fix it" pull a CI-gap task naturally creates.
- **modular:** the with-skill run's explicit dependency-version
  constraint (`from: "7.0.0"`) avoided a real build failure the
  baseline hit (Kingfisher's unconstrained resolution pulled in a
  version incompatible with this toolchain). This is a genuine
  real-artifact win, independent of rubric scoring.
- **new-project:** with-skill reused this repo's own pre-verified
  `templates/feature-modular/` profile and avoided a real defect the
  baseline's improvised structure introduced (a feature test silently
  excluded from the scheme a user would naturally run).

### Where baseline's advantage is a verification-thoroughness artifact, not a correctness difference

In 4 of the 5 comparisons where baseline scored higher
(extract-candidate-settingsrow, migrate-candidate,
restyle-candidate×2, test-target-candidate-FeatureA — 5 of 6 total
baseline-favored rows), **the underlying technical judgment and final
diff/refusal were identical or near-identical between conditions.**
The point gaps came from one extra concrete verification step shown in
the baseline's report (e.g. physically `ls`-ing a built resource
bundle, or re-running BUILD/TEST against an unmodified fixture before
refusing) that the with-skill run's own report didn't narrate — not
from with-skill reaching a different or worse engineering conclusion.
Given these baselines are contaminated (i.e., generated by sessions
with prior exposure to this repo's own verification-discipline
conventions), this pattern is plausibly the contamination itself
showing through, not evidence about what the skill does or doesn't
improve.

### The one real, unambiguous with-skill defect found

**extract-candidate (networking)** is the one comparison where
with-skill's own artifact has a concrete, independently-verified
problem: it added an `App -> NetworkingKit` dependency edge in
`Project.swift` that nothing in `App/Sources/ExtractCandidateApp.swift`
actually requires (the grader confirmed this by reading the file
directly — it only references `SettingsRow`). The contaminated
baseline explicitly grepped for consumers first and correctly declined
to add that edge for exactly that reason. With-skill's own report even
flagged this as something "worth checking... during scoring" rather
than resolving it — the grading pass resolved it, and it's a real
scope-creep defect (rubric items 2 and 6), not a contamination
artifact, since nothing about baseline's restraint here depends on
prior exposure to this repo.

### A genuine ambiguity, not a defect either way

**scaffold-candidate** has no clean winner: the fixture's own
`EXPECTATIONS.md` wording ("author exactly this structure, **or an
equivalent one**") is honestly readable two ways. With-skill recognized
the already-committed `feature/` template already satisfies the
request and authored nothing new; baseline authored a new,
separately-named `labeled-enum/` template that is — by baseline's own
admission — structurally identical to the existing one. Both performed
equally rigorous real verification (scratch-copy `tuist scaffold`
execution, exact content match, Swift-parse check) of whichever
artifact they validated. This is flagged, not resolved, as exactly the
kind of fixture-wording ambiguity the PRD (§7) anticipates feeding back
into Phase 2's calibrated rubric.

## Real-artifact pass/fail tally (§5.2)

| Axis | Baseline | With-skill |
|---|---|---|
| BUILD | 13 PASS / 1 FAIL (`modular`) | 14 PASS / 0 FAIL |
| TEST | 12 PASS / 1 FAIL (`modular`, blocked by BUILD) / 1 N/A (refusal path, independently reverified anyway) | 12 PASS / 0 FAIL / 2 N/A (refusal paths, not independently reverified by with-skill's own report) |
| REFUSAL (4 should-refuse scenarios) | 4/4 PASS | 4/4 PASS |
| Scope discipline (git-diff-confirmed) | 13/14 PASS, 1 defect (extract-candidate-networking not applicable — that's a with-skill defect, see above) | 13/14 PASS, 1 defect (extract-candidate-networking) |

The one real-artifact-level failure across all 28 runs is baseline's
`modular` BUILD/TEST FAIL — a genuine, reproducible incompatibility
that with-skill's more careful dependency-version constraint avoided.

## Recurring patterns worth carrying forward (to Phase 2 and future skill revisions)

1. **Version-pin narration is where the skill earns its clearest,
   least-ambiguous wins** (version-mismatch, and partially new-project/
   legacy-tuist) — every comparison testing whether a version pin gets
   explicitly detected and reported showed with-skill winning cleanly,
   with baseline's correct outcomes (where they occurred) shown to be
   incidental rather than deliberate.
2. **Approve-before-apply discipline is real and holds under pressure**
   (ci-gaps) — worth spot-checking in Phase 2 against a task that
   creates a stronger "just fix it" pull than a CI-gap review.
3. **Dependency-version pinning discipline had a real, measurable
   build-outcome effect** (modular) — the one case in this benchmark
   where rubric behavior directly explains a BUILD PASS/FAIL
   divergence, not just a report-quality difference.
4. **Scope-creep risk is not eliminated by the skill** — the
   extract-candidate-networking finding shows with-skill can still
   introduce an unrequested manifest edge; this deserves a closer look
   at `ios-tuist-module`'s Decision Rules around adding dependency
   edges speculatively.
5. **The contaminated-baseline sessions in this benchmark consistently
   showed strong verification discipline** (physically inspecting
   built artifacts, re-running BUILD/TEST before refusing) — this is
   worth treating as a signal that "having read this repo's
   conventions" (even without the skill loaded) measurably changes
   baseline behavior, which is exactly why the PRD requires a genuinely
   naive baseline before treating any of these baseline numbers as
   representative.

## Next steps

1. **Run a genuinely uncontaminated baseline** (fresh `claude` session,
   no `--plugin-dir`, no prior exposure to this conversation or this
   repo's conventions) for all 14 comparisons, per `EXECUTION-GUIDE.md`,
   to replace the contaminated placeholders in `raw/*-baseline.md`
   with real evidence — this is the single most important remaining
   gap before this benchmark's conclusions can be trusted as
   PRD-conformant.
2. Re-score against the real baseline using the same rubric and the
   same independent-grader-per-batch methodology used here.
3. Investigate the `extract-candidate-networking` scope-creep finding
   against `ios-tuist-module`'s actual Decision Rules — determine
   whether this is a one-off or a systematic gap worth a skill fix.
4. Feed the `scaffold-candidate` ambiguity back into that fixture's
   `EXPECTATIONS.md` wording, per PRD §7's "what Phase 1 hands to
   Phase 2" calibration note.
5. Phase 2 (real external project, per PRD §7) remains unexecuted —
   this Phase 1 result should inform which 2–3 real tasks are worth
   selecting once that phase starts.
