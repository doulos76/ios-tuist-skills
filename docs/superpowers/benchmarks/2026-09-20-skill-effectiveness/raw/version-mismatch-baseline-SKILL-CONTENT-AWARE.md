# Comparison 3 — `version-mismatch` — DISQUALIFIED baseline attempt (read skill content directly)

> **⚠️ This is NOT a valid baseline run — kept only as a record of what
> happened, not as baseline evidence.** This session, while never having
> `ios-tuist-skills` loaded via `--plugin-dir`, discovered
> `skills/ios-tuist-feature/` in this repo's own directory tree,
> **read `references/version-safety.md` and the skill's own workflow
> directly**, and explicitly decided to "simulate/follow its
> instructions manually" — i.e., it read and applied the skill's actual
> content, just without the `Skill` tool formally loading it. This is
> full content-level contamination, not the narrower
> name/existence-only awareness seen in `legacy-tuist-baseline.md`. This
> file must **not** be used as this comparison's baseline in any
> rescoring pass — see `version-mismatch-baseline.md` for the actual
> real baseline (pending a cleaner rerun).

## Task prompt

> Add a simple settings screen to this project.

## What happened

The session correctly identified this as a Tuist project fixture, then
went looking for whether a matching skill was invokable, found it
wasn't in its loaded-skills list (correct — no `--plugin-dir`), but
then **read the skill's files from disk anyway** (`skills/
ios-tuist-feature/`, `references/version-safety.md`) and deliberately
followed their documented procedure by hand, reasoning "this is
effectively what's being asked — this is a benchmark fixture." This
produced a response that detected and reported the version mismatch
explicitly (project pin 4.62.0 vs. global/unpinned active 4.194.1),
matching the with-skill run's behavior closely — but this outcome is
not informative about what a **baseline** (no skill exposure) actually
does, since the skill's content was in fact consulted.

## `git diff`

```diff
diff --git a/tests/fixtures/version-mismatch/App/Sources/VersionMismatchApp.swift b/tests/fixtures/version-mismatch/App/Sources/VersionMismatchApp.swift
index 969f7dc..46b44a8 100644
--- a/tests/fixtures/version-mismatch/App/Sources/VersionMismatchApp.swift
+++ b/tests/fixtures/version-mismatch/App/Sources/VersionMismatchApp.swift
@@ -4,8 +4,7 @@ import SwiftUI
 struct VersionMismatchApp: App {
     var body: some Scene {
         WindowGroup {
-            Text(SettingsTitle.value)
-                .padding()
+            SettingsView()
         }
     }
 }
```
Plus new untracked: `App/Sources/SettingsView.swift`.

## Real verification performed (as reported)

```
$ mise exec tuist@4.62.0 -- tuist install
success

$ mise exec tuist@4.62.0 -- tuist generate --no-open
success

$ xcodebuild build (App, iOS Simulator)
BUILD SUCCEEDED

$ xcodebuild test (AppTests)
TEST SUCCEEDED (1/1)
```

## Real-artifact pass/fail (informational only — not counted as baseline evidence)

| Axis | Result |
|---|---|
| BUILD | PASS |
| TEST | PASS |
| Version mismatch detection | Detected and reported — but via direct skill-file consultation, not baseline judgment |

## Why this happened, and what it means for the benchmark's methodology

This is a real, structural risk the PRD's "baseline = no `--plugin-dir`"
definition didn't fully anticipate: **a `claude` session running inside
this repo's own working directory can discover and read the skill's
source files on disk**, even without the plugin being formally loaded.
`--plugin-dir` controls whether `SKILL.md` content is *injected into
context automatically*; it does not prevent an agentic session from
independently finding and reading those same files if it goes looking
for them, especially once it (correctly) infers a skill's name from
project memory (as happened one comparison earlier, in
`legacy-tuist-baseline.md`, at a narrower "name only" contamination
level).

**Implication for `EXECUTION-GUIDE.md` (should be added as a
correction):** truly isolating a baseline session may require either
(a) running it against a *copy* of just the fixture directory, entirely
outside this repo's own tree, so `skills/`, `references/`, and project
memory are physically unreachable, or (b) explicitly instructing the
baseline session not to read anything outside the fixture directory —
neither safeguard was in place for this run.
