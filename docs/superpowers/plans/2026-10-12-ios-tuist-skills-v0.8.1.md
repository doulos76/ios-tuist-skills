# ios-tuist-skills v0.8.1 (version-evidence follow-ups) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the two v0.8.0 "Known limitations" on version evidence: `.tuist-version` (#48) and `swiftVersion` (#47).

**Architecture:** Docs-only change to the shared procedure `references/version-safety.md` (every skill links to it), one line in `skills/ios-tuist-migrate/SKILL.md`, and `CHANGELOG.md`. No manifests, fixtures or scripts change. "Tests" are grep checks on the exact text; agent behavior is not exercised by CI.

**Tech Stack:** Markdown, `grep`, `git`, `gh`.

**Spec:** GitHub issues #47 and #48, including their research comments
(#48: issuecomment-6126412752, #47: issuecomment-6126438836). Those
comments are the evidence; this plan copies the needed facts verbatim.

## Global Constraints

- Branch: `fix/v0.8.1-version-evidence` from `develop` (`84fa328` or later). One PR into `develop`; release afterwards via `chore/release-0.8.1` (Task 4).
- Cite only the checked tuist/tuist tags: 2.7.2, 3.0.0, 3.42.2, 4.0.0, 4.62.0, 4.184.0, 4.184.1, 4.206.0. Never write a claim about an unchecked version as fact.
- `.tuist-version` priority (user decision 2026-10-12): conditional Tool Version source #3, after `.tool-versions`, before CI workflows.
- Conflicts are reported, never fixed (existing rule in `version-safety.md`). No skill other than `ios-tuist-migrate` edits a pin.
- Do not touch the Xcode axis, Manifest compatibility axis, Authority rule, Mismatch handling or Tuist Context block.
- Commit messages: Conventional Commits, referencing the issue (`(#48)`), ending with the attribution line the delivering session uses.

## Review Focus

1. A project with only `.tuist-version` (no mise config, no `.tool-versions`) — the effective version must come from `.tuist-version`, not "none detected". Pinned by Task 1 Step 1 check (c).
2. A project with both `.tool-versions` and a different `.tuist-version` — `.tool-versions` wins, `.tuist-version` is listed under Conflicts. Pinned by Task 1 Step 1 check (d).
3. A Tuist 3.x project whose `swiftVersion` sits in `Tuist/Config.swift`, not `Tuist.swift` — it must still be collected. Pinned by Task 2 Step 1 check (a).
4. A project with no effective version — the `swiftVersion` label falls back to the active Tuist version and says so. Pinned by Task 2 Step 1 check (c).
5. A 4.184.1+ project that still declares `swiftVersion` — reported as deprecated/ignored, never removed by a non-migrate skill. Pinned by Task 2 Step 1 check (d).

---

### Task 1: `.tuist-version` as a conditional Tool Version source (#48)

**Files:**
- Modify: `references/version-safety.md` (Tool Version axis list, lines 20-34; Live commands, lines 60-68; output template, lines 101-110)
- Modify: `skills/ios-tuist-migrate/SKILL.md:95-98` (step 5 pin-source list)

**Interfaces:**
- Produces: the source name `.tuist-version` and the label text `conditional` used again in Task 3's CHANGELOG entry.

- [ ] **Step 1: Write the failing checks**

Save as `/tmp/v081-task1.sh` (outside the repo; do not commit it):

```bash
#!/usr/bin/env bash
set -u
f=references/version-safety.md
fail=0
check() { if grep -qF -- "$2" "$f"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }
check "a: list item #3"       '3. `.tuist-version` (conditional'
check "b: tuistenv evidence"  '`.tuist-bin/tuist`'
check "c: sole-source case"   '`.tuist-version` is the only Tool Version source'
check "d: conflict rule"      '`.tuist-version` is listed under `Conflicts`'
check "e: mise setting cmd"   'mise settings get idiomatic_version_file_enable_tools'
check "f: template row"       '.tuist-version               <ver|none>   (conditional'
grep -qF '`.tuist-version`' skills/ios-tuist-migrate/SKILL.md && echo "ok   g: migrate" || { echo "FAIL g: migrate"; fail=1; }
exit $fail
```

- [ ] **Step 2: Run the checks to verify they fail**

Run: `bash /tmp/v081-task1.sh`
Expected: every line `FAIL`, exit 1.

- [ ] **Step 3: Edit the Tool Version axis list**

In `references/version-safety.md`, replace:

```markdown
1. `mise.toml` / `.mise.toml` (plus any additional mise config paths
   confirmed by the mise docs)
2. `.tool-versions`
3. CI workflow files (e.g. `.github/workflows/*.yml`) that pin or install
   a specific Tuist version
4. Repository scripts (`Scripts/`, `Makefile`, `Brewfile`, bootstrap
   scripts) that install or reference a specific Tuist version
```

with:

```markdown
1. `mise.toml` / `.mise.toml` (plus any additional mise config paths
   confirmed by the mise docs)
2. `.tool-versions`
3. `.tuist-version` (conditional — see below)
4. CI workflow files (e.g. `.github/workflows/*.yml`) that pin or install
   a specific Tuist version
5. Repository scripts (`Scripts/`, `Makefile`, `Brewfile`, bootstrap
   scripts) that install or reference a specific Tuist version

`.tuist-version` is honored only by:

- `tuistenv`, the version-switching `tuist` shim of Tuist 2.x/3.x
  installs. It searches the current directory and then each parent; a
  `.tuist-bin/tuist` in the same directory wins over the file (checked
  in tuist/tuist 2.7.2, 3.0.0, 3.42.2:
  `Sources/TuistEnvKit/Versions/VersionResolver.swift`). Tuist 4.0.0
  removed this resolver; Tuist 4.x itself never reads the file.
- mise, when its `idiomatic_version_file_enable_tools` setting includes
  `tuist` (default: empty, so off).

Record it whenever it exists and label it `conditional`. If
`.tuist-version` is the only Tool Version source, it gives the effective
project version. When a higher source has a value, a differing
`.tuist-version` is listed under `Conflicts` like any other source.
```

- [ ] **Step 4: Add the live command**

In the "Live commands" list, after the `mise exec -- tuist version` item (which ends with `mise switches versions per directory)`), insert:

```markdown
- `mise settings get idiomatic_version_file_enable_tools` (only when
  `.tuist-version` exists and `mise` is installed; `tuist` in the list
  means mise reads `.tuist-version`)
```

- [ ] **Step 5: Add the template row**

In the `Tool Version Evidence` template, replace:

```text
.tool-versions              <ver|none>   PRIMARY candidate #2
CI workflows                <ver|none>   (file path)
```

with:

```text
.tool-versions              <ver|none>   PRIMARY candidate #2
.tuist-version               <ver|none>   (conditional: tuistenv on Tuist <= 3.x; mise idiomatic <on|off|n/a>)
CI workflows                <ver|none>   (file path)
```

- [ ] **Step 6: Edit the migrate pin-source list**

In `skills/ios-tuist-migrate/SKILL.md` step 5, replace:

```markdown
   the version-pin sources that will change (e.g. `.mise.toml`,
   `.tool-versions`, CI workflow install steps, any documented version
   reference) and, file by file, exactly which manifest syntax will
```

with:

```markdown
   the version-pin sources that will change (e.g. `.mise.toml`,
   `.tool-versions`, `.tuist-version`, CI workflow install steps, any
   documented version reference) and, file by file, exactly which manifest syntax will
```

- [ ] **Step 7: Run the checks to verify they pass**

Run: `bash /tmp/v081-task1.sh`
Expected: every line `ok`, exit 0.

Then run: `git diff --stat`
Expected: exactly `references/version-safety.md` and `skills/ios-tuist-migrate/SKILL.md`.

- [ ] **Step 8: Commit** (hand to Claude if the sandbox blocks `git commit`)

```bash
git add references/version-safety.md skills/ios-tuist-migrate/SKILL.md
git commit -m "fix(version-safety): treat .tuist-version as a conditional Tool Version source (#48)"
```

---

### Task 2: version-aware `swiftVersion` label (#47)

**Files:**
- Modify: `references/version-safety.md` (Swift axis, lines 43-47; Swift Evidence template, line 115)

**Interfaces:**
- Consumes: nothing from Task 1 (independent section of the same file).
- Produces: the label strings `consumed`, `stored only`, `deprecated, ignored` used in Task 3's CHANGELOG entry.

- [ ] **Step 1: Write the failing checks**

Save as `/tmp/v081-task2.sh`:

```bash
#!/usr/bin/env bash
set -u
f=references/version-safety.md
fail=0
check() { if grep -qF -- "$2" "$f"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }
check "a: Config.swift source"  '`Tuist/Config.swift` (Tuist 2.x/3.x)'
check "b: version table"        '| 4.0.0 – 4.184.0 | stored only'
check "c: fallback rule"        'if none was detected, use the active Tuist'
check "d: never remove"         'never remove it'
check "e: template row"         'Tuist.swift / Config.swift swiftVersion'
grep -qF 'Tuist.swift swiftVersion               <ver|none>' "$f" && { echo "FAIL f: old row still present"; fail=1; } || echo "ok   f: old row gone"
exit $fail
```

- [ ] **Step 2: Run the checks to verify they fail**

Run: `bash /tmp/v081-task2.sh`
Expected: a-e `FAIL`, f `FAIL` (old row still present), exit 1.

- [ ] **Step 3: Rewrite the Swift axis section**

Replace:

```markdown
### Swift axis (compatibility risk only)

`Tuist.swift` `swiftVersion`; `// swift-tools-version:` in
`Package.swift` and `Tuist/Package.swift`; `.swift-version` (Tuist does
not consume it — evidence of project intent); the active Swift.
```

with:

```markdown
### Swift axis (compatibility risk only)

`swiftVersion` in `Tuist.swift` (Tuist 4.x) or `Tuist/Config.swift` (Tuist 2.x/3.x);
`// swift-tools-version:` in `Package.swift` and `Tuist/Package.swift`;
`.swift-version` (Tuist does not consume it — evidence of project
intent); the active Swift.

What `swiftVersion` does depends on the Tuist version. Label it by the
effective project version; if none was detected, use the active Tuist
version and say so.

| Tuist | Effect of `swiftVersion` | Checked tags (tuist/tuist) |
|---|---|---|
| 2.x / 3.x | consumed: Swift tools version for dependency resolution in `tuist fetch` (2.x: `tuist dependencies fetch/update`); below 5.6 selects the legacy generated `Package.swift`; when absent, the active Swift is used | 2.7.2, 3.0.0, 3.42.2 |
| 4.0.0 – 4.184.0 | stored only; no reader found (4.0.0 takes the tools version from `Package.swift`) | 4.0.0, 4.62.0, 4.184.0 |
| 4.184.1 and later | deprecated, ignored ("`swiftVersion` is unused and no longer affects generation") | 4.184.1, 4.206.0 |

On 2.x/3.x, a `swiftVersion` that differs from the active Swift changes
how dependencies resolve: report it as a risk to dependency resolution,
not only as compatibility. On 4.184.1 and later, report it as
deprecated and never remove it; only `ios-tuist-migrate` changes it.
Versions between the checked tags are not verified.
```

- [ ] **Step 4: Replace the template row**

In the `Swift Evidence` template, replace:

```text
Tuist.swift swiftVersion               <ver|none>
```

with:

```text
Tuist.swift / Config.swift swiftVersion <ver|none>   <consumed (2.x/3.x) | stored only (4.0.0-4.184.0) | deprecated, ignored (>= 4.184.1)>
```

- [ ] **Step 5: Run the checks to verify they pass**

Run: `bash /tmp/v081-task2.sh && bash /tmp/v081-task1.sh`
Expected: every line `ok` in both, exit 0 (Task 1's text must survive).

- [ ] **Step 6: Commit**

```bash
git add references/version-safety.md
git commit -m "fix(version-safety): label swiftVersion by Tuist version (#47)"
```

---

### Task 3: CHANGELOG

**Files:**
- Modify: `CHANGELOG.md` (`## [Unreleased]`, line 7; 0.8.0 "Known limitations", lines 81-85)

**Interfaces:**
- Consumes: the label names from Tasks 1-2.

- [ ] **Step 1: Write the failing check**

```bash
grep -A12 '^## \[Unreleased\]' CHANGELOG.md | grep -qF '(#48)' && grep -A12 '^## \[Unreleased\]' CHANGELOG.md | grep -qF '(#47)' && echo ok || echo FAIL
```

Expected now: `FAIL`.

- [ ] **Step 2: Add the Unreleased entry**

Replace the line `## [Unreleased]` (and the blank line after it) with:

```markdown
## [Unreleased]

### Changed

- version-safety (#48): `.tuist-version` is a conditional Tool Version source (#3, after
  `.tool-versions`). It is honored only by `tuistenv` (Tuist 2.x/3.x) or by mise with
  `idiomatic_version_file_enable_tools` including `tuist`; Tuist 4.x never reads it.
  `ios-tuist-migrate` lists it among pin sources.
- version-safety (#47): the Swift axis collects `swiftVersion` from `Tuist.swift` or
  `Tuist/Config.swift` and labels it by Tuist version: consumed (2.x/3.x, dependency
  resolution), stored only (4.0.0-4.184.0), deprecated, ignored (4.184.1+).
- Output format: one new Tool Version Evidence row (`.tuist-version`) and a label column on
  the `swiftVersion` row. Additive; no existing row is removed.

```

- [ ] **Step 3: Leave 0.8.0's Known limitations as released**

Do not edit the `[0.8.0]` section (it is the published release record). Verify: `git diff CHANGELOG.md | grep '^-' | grep -v '^---'` prints nothing.

- [ ] **Step 4: Run the check to verify it passes**

Run the Step 1 command. Expected: `ok`.

- [ ] **Step 5: Commit**

```bash
git add CHANGELOG.md
git commit -m "docs(changelog): record v0.8.1 version-evidence changes (#47, #48)"
```

- [ ] **Step 6: Push and open the PR** (Claude/user, needs network + `gh`)

```bash
git push -u origin fix/v0.8.1-version-evidence
gh pr create --base develop --title "fix: version-evidence follow-ups (#47, #48)" --body-file <body>
```

PR body: summary, `Closes #47`, `Closes #48`, the grep check output from Tasks 1-3, and an "Unverified" section: agent behavior against fixtures not run; mise aqua backend handling of `.tuist-version` not verified; `.tuist-version` vs `mise.toml` precedence inside mise not verified; versions between checked tags not verified.

---

### Task 4: Release v0.8.1 (Claude + user, after the PR merges)

Follow the v0.8.0 release mechanics (memory / `git show 776f9c4 --stat`):

- [ ] Branch `chore/release-0.8.1` from `develop`; set `.claude-plugin/plugin.json` `"version": "0.8.1"`; rename `## [Unreleased]` to `## [0.8.1] - <date>` and add a fresh empty `## [Unreleased]` above it. PR into `develop`.
- [ ] PR `develop` -> `main` titled `release: v0.8.1` (run `gh pr update-branch <n>` only with user OK).
- [ ] After merge: annotated tag `v0.8.1` on the main merge commit (message `ios-tuist-skills 0.8.1`), push, `gh release create v0.8.1 --target main --title "v0.8.1 — Version evidence follow-ups"` with the CHANGELOG 0.8.1 section as notes. Tag and Release need user OK.

## Self-review notes

- Coverage: #48 plan items 1-3 -> research done, Task 1, Task 3. #47 items -> Task 2, Task 3. #47's "update EXPECTATIONS as applicable": not applicable, no fixture declares `swiftVersion` (grepped 2026-10-12), so no fixture task.
- The issues said "remove the Known limitation"; Task 3 Step 3 deliberately keeps the released 0.8.0 section unchanged and supersedes it via the 0.8.1 entry instead.
