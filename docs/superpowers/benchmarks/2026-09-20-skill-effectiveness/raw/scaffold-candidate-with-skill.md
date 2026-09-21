# Comparison 11 — `scaffold-candidate` — with-skill

## Task prompt

> Add a scaffold template that generates a labeled-enum Swift file from a name.

## Condition

Real `claude --plugin-dir /Users/dave/Documents/GitHub/ios-tuist-skills`
session, run by the user in the `.worktrees/benchmark-with-skill`
worktree, fixture freshly reset beforehand via
`scripts/benchmark-prep-run.sh scaffold-candidate`.

## Fixture

`tests/fixtures/scaffold-candidate/` — already has a committed
`tuist scaffold` template at `Tuist/Templates/feature/` that happens to
produce exactly the labeled-enum shape this prompt describes.

## What this response did — and a genuine judgment divergence from baseline

- Confirmed the project-pinned Tuist version (4.206.0) matches active.
- **Recognized that the existing committed `feature/` template already
  fulfills the request exactly** (required `name` attribute, `.file`
  with Swift-interpolated `path:`, `source.stencil` rendering the exact
  labeled-enum shape requested) — cited the git commit that introduced
  it (`fd9889e`) as evidence it's pre-existing, not something to
  recreate.
- **Authored no new template.** Explicit reasoning given: "writing a
  second one would duplicate this without a differing name, path, or
  content shape to justify it."
- Still performed full real validation of the *existing* template
  rather than trusting its contents on sight: ran `tuist scaffold
  feature --name Sample` in a `mktemp` scratch copy under `/tmp`
  (never inside the committed tree), confirmed the generated
  `Sources/SampleLabel.swift` matches the expected content exactly,
  confirmed it parses as valid Swift (`swiftc -parse`), and deleted the
  scratch copy afterward.
- Explicitly offered a fallback: if the user actually wanted a second,
  differently-shaped template, to say how it should differ and it
  would author that as a separate one.

## Real verification performed (as reported)

```
$ mktemp -d && cp -r tests/fixtures/scaffold-candidate/* <scratch>/
$ mise exec tuist@4.206.0 -- tuist scaffold feature --name Sample
succeeded, in scratch dir only

Generated Sources/SampleLabel.swift:
public enum SampleLabel { public static let text = "Sample" }
(matches expected content exactly)

$ swiftc -parse Sources/SampleLabel.swift
succeeded

Scratch copy deleted afterward.
```

## `git diff`

```
(empty — no changes to tests/fixtures/scaffold-candidate)
```

## Comparison to contaminated baseline (`scaffold-candidate-baseline.md`) — a genuine divergence

| Aspect | Baseline (contaminated) | With-skill |
|---|---|---|
| Interpretation of the prompt | "General capability request" → author a **new**, separately-named `labeled-enum` template, leave `feature/` untouched | "The existing `feature/` template already IS this shape" → author **nothing new**, validate the existing one instead |
| Existing `feature/` template | Untouched either way | Untouched, explicitly identified as already satisfying the request |
| New files created | `Tuist/Templates/labeled-enum/` (feature.swift + source.stencil) | None |
| Real scaffold execution proof | Yes, in `/tmp` scratch copy, for the newly-authored template | Yes, in `/tmp` scratch copy, for the **existing** template |
| `EXPECTATIONS.md` fit | Partially — the fixture's own expectations text says "author exactly this `Tuist/Templates/feature/` structure (or an equivalent one...)," which reads as expecting a new template to be authored | Partially — "or an equivalent one" could be read as license to recognize the existing template already qualifies, but the fixture's overall framing ("this skill authors *new* templates on request") leans toward expecting new authorship |

**This is the one comparison where the correct answer is genuinely
ambiguous from the fixture's own wording**, not a case where one
condition is clearly right and the other clearly wrong. Both responses
are internally coherent and both performed real, honest verification
of whatever template they ended up validating. Flagging this
explicitly rather than silently picking a winner — this is exactly the
kind of ambiguity the PRD's rubric-scoring pass should resolve with an
explicit judgment call (and ideally feed back into `EXPECTATIONS.md`'s
own wording as a Phase 1 → Phase 2 calibration correction, per PRD §7's
"what Phase 1 hands to Phase 2" note).

## Rubric scoring — NOT PERFORMED

Deferred to the batch scoring pass after all 14 with-skill runs are
captured. This comparison in particular needs the scorer to make an
explicit call on whether "recognize and reuse an existing template" is
an acceptable interpretation of "add a scaffold template," and to note
the ambiguity rather than silently resolving it in either direction.

## Real-artifact pass/fail

| Axis | Result |
|---|---|
| Real `tuist scaffold` execution in scratch copy | PASS |
| Generated file content matches expected exactly | PASS |
| Existing `feature/` template left untouched | PASS |
| "New template authored" (if that's the required interpretation) | Did not happen — see ambiguity note above |
