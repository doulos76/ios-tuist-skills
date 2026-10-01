# ios-tuist-skills v0.8 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Implementation owner: Codex.** This repo's Claude session only produced
> the spec and this plan. Codex's `workspace-write` sandbox cannot
> `git commit` or run `mise`/`tuist`/`xcodebuild`; for those steps Codex
> stops and hands the exact command to Claude/the user (see "Execution
> notes").

**Goal:** Make skill specs, fixture expectations and rubric consistent; make version detection evidence-based; make fixtures self-contained; coexist with the official Tuist plugin; ship an isolated benchmark harness.

**Architecture:** Mostly Markdown edits to `skills/*/SKILL.md`, `references/`, fixture `EXPECTATIONS.md`, plus three small shell scripts and one CI workflow change. Each workstream (WS) is its own `feature/v0.8-<ws>` branch cut from `develop`. "Tests" are the PRD's grep/shell verification commands: run before the change (expect failure), then after (expect pass).

**Tech Stack:** Markdown, bash/zsh, ruby (YAML parsing, as in `scripts/validate-fixtures-locally.sh`), GitHub Actions, mise, Tuist 4.206.0 / 4.62.0 / 3.42.2 (fixtures).

**Spec:** `docs/superpowers/specs/2026-10-01-ios-tuist-skills-v0.8-design.md` (PRD §3 WS1–WS7 is authoritative for rationale and acceptance criteria).

## Global Constraints

- Order: WS1 → WS2 → WS3 → WS4 → WS5 → WS6 → WS7. WS6 requires WS3 merged.
- One workstream per branch; branch name `feature/v0.8-ws<N>`, cut from `develop`. Never mix workstreams.
- No new skills (`ios-tuist-adopt` is explicitly out of scope).
- Do not relax `ios-tuist-ci`'s "Never remove a validation step".
- No refactors, rewording or manifest modernization outside the PRD.
- Commit messages: Conventional Commits + Jira key if the project rule requires one; follow the style of `git log` on `develop`.
- Every verification command is actually run and its output pasted in the PR description. A command that cannot run is reported as "Unverified".
- Items marked **검증 필요** in the PRD are research gates: if the official source contradicts the PRD, stop and report instead of improvising.
- Do not edit scores in `docs/superpowers/benchmarks/**` (footnote only).

## Review Focus

- Fixture dir with a **dotfile name collision**: `.tool-versions` added to a fixture must not change which Tuist `validate-fixtures-locally.sh` / mise selects for *other* fixtures (mise walks up from cwd; fixtures are siblings, so only the fixture's own file applies). Test by running the local validator for 2 fixtures with different pins.
- `migrate-candidate` pins 3.42.2 while repo-root mise config (if any) may pin 4.x: `mise exec -- tuist version` inside the fixture must print `3.42.2`.
- `version-safety.md` rewrite: a project with **no** pin anywhere must still produce "none detected" (not a crash/blank table row).
- Conflict case: `.mise.toml` says X, CI says Y → output reports a conflict and does not edit either (`version-mismatch` fixture).
- WS5: a **new empty dir that contains an unrelated `*.xcodeproj` one level down** is refused; an empty dir is not.
- Benchmark harness run from a temp dir under the repo (e.g. `$TMPDIR` symlinked into the repo) must fail the "no repo `skills/` in ancestors" check.

## Execution notes

- Before each task, re-verify the **Evidence** block against the files. If the file differs from what is quoted, stop and report; don't edit.
- Pre-verified on 2026-10-02 against `492fd7e`: all WS1–WS6 evidence matched, with one nuance: `skills/ios-tuist-module/SKILL.md` step 5 already says "Move the extracted code's existing tests with it", so WS1-3 is only a clarification about the emptied source test target.
- Resolved open question 3: `tests/fixtures/ci-gaps/EXPECTATIONS.md` states the embedded workflow pins 4.206.0 "matching this fixture's project (no version mismatch to find here)". Adding `.tool-versions` `tuist 4.206.0` preserves the intent.
- Default for open question 4 (emptied original test target): **report only**, never delete; deletion is the user's decision (matches PRD WS1-3).
- Fixture validation (`./scripts/validate-fixtures-locally.sh <fixture>`) needs mise/tuist/xcodebuild: Codex hands this to Claude/the user.

---

### Task 1: WS1 — module skill consumer-edge rule

Branch: `feature/v0.8-ws1`

**Files:**
- Modify: `skills/ios-tuist-module/SKILL.md` (Workflow step 5 ≈L83-92; Decision Rules ≈L100-103; Output Contract example ≈L152-170)
- Modify: `tests/fixtures/extract-candidate/EXPECTATIONS.md:30-31`
- Modify (conditional): `references/modularization.md` or `references/dependencies.md` (add one paragraph only if step 3 finds no existing rule)

**Interfaces:**
- Consumes: nothing.
- Produces: Output Contract wording "`Dependency Changes` lists each added edge with `(usage: <file>:<line>)`" that Task 7's CHANGELOG entry cites.

- [ ] **Step 1: Create branch and run the failing checks**

```bash
git switch develop && git switch -c feature/v0.8-ws1
grep -rn "App now depends on NetworkingKit\|App\` depends on it" skills/ tests/fixtures/   # expect 2 hits (FAIL)
grep -n "usage site" skills/ios-tuist-module/SKILL.md                                      # expect 0 hits (FAIL)
```

- [ ] **Step 2: Replace Workflow step 5, bullet 3** (currently "Wire the source target (and other consumers) to depend on the new target.") with:

```markdown
   - Add a dependency edge to the new target **only from targets with a
     verified usage site** — an `import` of the new module plus a
     reference to a moved symbol — found by searching the whole project
     after the move. The source target is not automatically a consumer:
     if nothing left in it references the moved symbols, it gets no edge.
```

- [ ] **Step 3: Replace the last Workflow bullet** (tests move with code) by appending:

```markdown
     If that leaves the original test target with no test files, do not
     delete it; report it under Risks / Follow-up and let the user decide.
```

- [ ] **Step 4: Add a Decision Rules item** after the "Never widen…" item:

```markdown
- Add a dependency edge to the new target only from targets with a
  verified usage site; record the evidence (`file:line`) for each added
  edge under `Dependency Changes` in the Output Contract. "No edge added
  (no usage site found)" is a valid, reportable result.
```

- [ ] **Step 5: Replace the Output Contract success example** lines `- App now depends on NetworkingKit instead of owning the code directly` with:

```text
Dependency Changes:
- FeatureX -> NetworkingKit (usage: FeatureX/Sources/Api.swift:12)
- App: no edge added (no usage site found)
```
and keep the other `Changed:` bullets. In the Output Contract list, no new field is needed: evidence goes in the existing `Dependency Changes` field; add one sentence above the code block: "`Dependency Changes` must give, per added edge, the usage-site evidence."

- [ ] **Step 6: Update `tests/fixtures/extract-candidate/EXPECTATIONS.md`** lines 30-31, replacing "`App` depends on it instead of owning the code." with:

```markdown
`App` gets **no** dependency edge on it: after the move nothing in
  `App/Sources` references `APIRequestBuilder` (usage site: none), and
  the only other reference, `App/Tests/AppTests.swift`, moves with the code.
```
Also add to "What must NOT happen": "- An `App -> NetworkingKit` edge added without a usage site."

- [ ] **Step 7: Check for an existing consumer-edge principle**

```bash
grep -n -i "consumer\|usage site\|narrowest" references/dependencies.md references/modularization.md
```
If a clear principle exists, link it from the new Decision Rules item (`[dependencies](../../references/dependencies.md)`). If not, add one paragraph to `references/dependencies.md` under its narrowest-target section: "A target gains a dependency on another target only where it has a verified usage site (import + symbol reference). Ownership of the old code is not a usage site." and link it.

- [ ] **Step 8: Run checks, expect pass**

```bash
grep -rn "App now depends on NetworkingKit\|App\` depends on it" skills/ tests/fixtures/   # expect none
grep -n "usage site" skills/ios-tuist-module/SKILL.md                                      # expect >=1
```
Then hand off to Claude/user: `./scripts/validate-fixtures-locally.sh extract-candidate` (the script's first arg is the fixture name, confirmed by `ONLY_FIXTURE="${1:-}"`). Expected: generate/build/test pass (no manifest changed, so this is a regression guard).

- [ ] **Step 9: Commit** (hand off if sandboxed)

```bash
git add skills/ios-tuist-module/SKILL.md tests/fixtures/extract-candidate/EXPECTATIONS.md references/
git commit -m "fix: require verified usage site for consumer edges in ios-tuist-module"
```

---

### Task 2: WS2 — version-safety: evidence collection and conflict reporting

Branch: `feature/v0.8-ws2`

**Files:**
- Modify: `references/version-safety.md` (replace "Detection order" L12-L38, update "Authority rule", "Mismatch handling" wording, "Tuist Context block")
- Modify: `skills/ios-tuist-migrate/SKILL.md:21,60,69` (they say "detection order" / "detection"); re-read L46-70 and reword only those phrases
- Modify (if contradicting): `tests/fixtures/version-mismatch/EXPECTATIONS.md`
- Check only: other `skills/*/SKILL.md` (grep below)

**Interfaces:**
- Consumes: Task 1 not required.
- Produces: terms "Evidence collection", "effective project version", "Tuist Version Evidence" used by Tasks 3, 5, 6.

- [ ] **Step 1: Research gates (do first, report results in the PR)**
  1. Does any official Tuist doc make `Tuist/Package.swift` or `Package.swift` a source of the *Tuist CLI version*? Check https://docs.tuist.dev (use Context7 `mcp__plugin_context7_context7__*` if available, else the site). Expected per PRD: no.
  2. Which additional mise config paths does mise officially read (`mise.local.toml`, `.config/mise.toml`, `.mise/config.toml`, `mise.<env>.toml`)? Source: https://mise.jdx.dev configuration docs.
  3. Confirm `Tuist.swift` / `Tuist` config has no Tuist-version field (`compatibleXcodeVersions`, `swiftVersion` only) at https://docs.tuist.dev/en/references/project-description/enums/tuistproject.
  Record each as: question → source URL → answer. If (1) says "yes, supported", keep the source and link the doc instead of removing it (PRD WS2-5).

- [ ] **Step 2: Failing checks**

```bash
grep -n "stopping as soon as" references/version-safety.md       # 1 hit (FAIL)
grep -n "compatible version range" references/version-safety.md  # 1 hit (FAIL)
grep -rln "version-safety" skills/ | xargs grep -n -i "detection order"   # hits in migrate (FAIL)
```

- [ ] **Step 3: Replace "## Detection order" through the "none detected" paragraph** (keep the live-commands list and the "Core rule") with:

````markdown
## Evidence collection

Inspect **every** source below to the end — never stop at the first
pin. Record each value found, with its file path. Sources, highest
authority first:

1. `mise.toml` / `.mise.toml` (plus any additional mise config paths
   confirmed by the mise docs — see the PR notes for this release)
2. `.tool-versions`
3. CI workflow files (e.g. `.github/workflows/*.yml`) that pin or install
   a specific Tuist version
4. Repository scripts (`Scripts/`, `Makefile`, `Brewfile`, bootstrap
   scripts) that install or reference a specific Tuist version
5. Existing manifest syntax (if the syntax used is only valid for a
   version range, that range is evidence)

The highest-authority source that has a value gives the **effective
project version**. A lower-authority source that disagrees is a
**conflict**: report it (both values, both file paths), do not fix it
(see Mismatch handling).

`Tuist.swift` is **not** a Tuist-version source. Its `compatibleXcodeVersions`
and `swiftVersion` are Xcode/Swift-axis evidence: record them, and if the
active Xcode is outside `compatibleXcodeVersions`, report that as a risk.

If no source yields a version, record "none detected" explicitly rather
than defaulting to "latest."

### Live commands

Run from the project root and record the working directory:

- `tuist version` (plain — what the user's shell resolves)
- `mise exec -- tuist version` (only when a mise config was found; the
  two can differ because mise switches versions per directory)
- `xcodebuild -version`
- `swift --version`
````

- [ ] **Step 4: Update "Authority rule"**: change "(found via steps 1–8 above)" to "(the effective project version from Evidence collection)". Update the Tuist Context block to add, directly after it:

````markdown
Followed by the evidence table:

```text
Tuist Version Evidence
----------------------
.mise.toml        <ver|none>   PRIMARY | ⚠ conflict
.tool-versions    <ver|none>
CI workflows      <ver|none>   (file path)
Scripts           <ver|none>   (file path)
Manifest syntax   <range|none>
Active (plain)    <ver>        (cwd)
Active (mise exec)<ver|n/a>
Effective project version: <ver | none detected>
```

Tuist.swift's `compatibleXcodeVersions`/`swiftVersion` go in the
`Xcode:` / `Swift:` lines of the Tuist Context block as constraints, not
in this table. In the Tuist Context block, `Project Tuist:` equals the
Effective project version.
````
Mark the PRIMARY row as whichever source supplied the effective version (not always `.mise.toml`).

- [ ] **Step 5: Fix citing skills.** `skills/ios-tuist-migrate/SKILL.md` L21, L60, L69: replace "detection order" / "detection" phrasing with "evidence collection". Re-read each surrounding sentence so meaning survives (e.g. migrate's "stop at the first pin" assumptions, if any). Other skills only say "Apply version-safety in full" — no change.

- [ ] **Step 6: Check `tests/fixtures/version-mismatch/EXPECTATIONS.md`** still agrees: it must describe the pin 4.62.0 as effective project version and the active version as the mismatch. Edit only if it names "detection order" or `Tuist.swift` as a version source.

- [ ] **Step 7: Run checks, expect pass**

```bash
grep -n "stopping as soon as" references/version-safety.md        # none
grep -n "compatible version range" references/version-safety.md   # none
grep -rln "version-safety" skills/ | xargs grep -n -i "detection order"   # none
grep -rn "Tuist.swift" references/version-safety.md               # only Xcode/Swift-axis mentions
```

- [ ] **Step 8: Commit**

```bash
git add references/version-safety.md skills/ios-tuist-migrate/SKILL.md tests/fixtures/version-mismatch/EXPECTATIONS.md
git commit -m "feat: collect all Tuist version evidence and report conflicts"
```

---

### Task 3: WS3 — self-contained fixture pins + CI pin consistency check

Branch: `feature/v0.8-ws3`

**Files:**
- Create: `tests/fixtures/{architecture-smells,ci-gaps,extract-candidate,restyle-candidate,scaffold-candidate,test-target-candidate}/.tool-versions` (content `tuist 4.206.0`)
- Create: `tests/fixtures/migrate-candidate/.tool-versions` (content `tuist 3.42.2`)
- Create: `scripts/check-fixture-pins.sh`
- Modify: `.github/workflows/validate-fixtures.yml` (add `check-pins` job)
- Modify: `tests/fixtures/migrate-candidate/EXPECTATIONS.md:53` ("Update whatever version-pin source names 3.42.2…")

**Interfaces:**
- Consumes: Task 2's term "evidence collection" (for the EXPECTATIONS wording).
- Produces: every non-`new-project` fixture has `.tool-versions`; `scripts/check-fixture-pins.sh` (exit 0 = consistent). Task 6 depends on the pins existing.

Existing `.tool-versions` files (`legacy-tuist`, `modular`, `version-mismatch`) already match the matrix (4.206.0 / 4.206.0 / 4.62.0) — leave them.

- [ ] **Step 1: Write the check script** `scripts/check-fixture-pins.sh` (chmod +x):

```bash
#!/bin/bash
# Fails when a fixture's .tool-versions tuist pin differs from the
# validate-fixtures.yml matrix. Fixtures are copied out of the repo for
# isolated benchmarks, so the pin must live inside each fixture, and CI
# must not drift from it.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOW_FILE="$REPO_ROOT/.github/workflows/validate-fixtures.yml"
status=0

while IFS=$'\t' read -r fixture tuist; do
  pin_file="$REPO_ROOT/tests/fixtures/$fixture/.tool-versions"
  if [ ! -f "$pin_file" ]; then
    echo "MISSING  $fixture: no .tool-versions"
    status=1
    continue
  fi
  pinned="$(awk '$1 == "tuist" { print $2 }' "$pin_file")"
  if [ "$pinned" != "$tuist" ]; then
    echo "MISMATCH $fixture: matrix=$tuist .tool-versions=${pinned:-none}"
    status=1
  fi
done < <(ruby -ryaml -e '
  YAML.load_file(ARGV[0]).fetch("jobs").fetch("validate").fetch("strategy")
      .fetch("matrix").fetch("include").each do |e|
    puts [e.fetch("fixture"), e.fetch("tuist").to_s].join("\t")
  end
' "$WORKFLOW_FILE")

[ "$status" -eq 0 ] && echo "All fixture pins match the CI matrix."
exit "$status"
```

- [ ] **Step 2: Run it, expect FAIL** (7 MISSING lines)

```bash
chmod +x scripts/check-fixture-pins.sh && ./scripts/check-fixture-pins.sh; echo "exit=$?"
```

- [ ] **Step 3: Create the 7 pin files** (match the style of `tests/fixtures/modular/.tool-versions`: run `cat -A tests/fixtures/modular/.tool-versions` first and copy its line ending):

```bash
for f in architecture-smells ci-gaps extract-candidate restyle-candidate scaffold-candidate test-target-candidate; do
  cp tests/fixtures/modular/.tool-versions "tests/fixtures/$f/.tool-versions"
done
printf 'tuist 3.42.2\n' > tests/fixtures/migrate-candidate/.tool-versions
```

- [ ] **Step 4: Run both checks, expect PASS**

```bash
./scripts/check-fixture-pins.sh   # "All fixture pins match…", exit 0
for d in tests/fixtures/*/; do [ "$d" = "tests/fixtures/new-project/" ] && continue; test -f "$d/.tool-versions" || echo "MISSING $d"; done   # no output
```

- [ ] **Step 5: Add CI job** to `.github/workflows/validate-fixtures.yml` (sibling of `validate:`; same indentation as `validate:`):

```yaml
  check-pins:
    name: fixture pins match matrix
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - name: Compare .tool-versions with matrix
        run: ./scripts/check-fixture-pins.sh
```
Validate YAML: `ruby -ryaml -e 'YAML.load_file(".github/workflows/validate-fixtures.yml")'` (no error).

- [ ] **Step 6: Update `migrate-candidate/EXPECTATIONS.md:53`** so the sentence names the in-fixture `.tool-versions` as the pin source to update. Read L50-58 first and edit only that clause. Then re-read `ci-gaps/EXPECTATIONS.md` "What must NOT happen" ("version pin (4.206.0) changed"): now `.tool-versions` also holds 4.206.0, so add "(in `ci.yml` or `.tool-versions`)".

- [ ] **Step 7: Hand off for local validation** (needs mise/tuist): `./scripts/validate-fixtures-locally.sh` for all fixtures — expect the same pass set as before. Specifically confirm `migrate-candidate` (3.42.2) and one 4.206.0 fixture still generate/build/test. Paste results in the PR.

- [ ] **Step 8: Commit**

```bash
git add tests/fixtures scripts/check-fixture-pins.sh .github/workflows/validate-fixtures.yml
git commit -m "test: pin Tuist inside every fixture and check against CI matrix"
```

---

### Task 4: WS4 — description routing and official-plugin coexistence

Branch: `feature/v0.8-ws4`

**Files:**
- Modify: `skills/*/SKILL.md` frontmatter `description:` (all 10)
- Modify: `skills/ios-tuist-feature/SKILL.md`, `skills/ios-tuist-dependency/SKILL.md`, `skills/ios-tuist-restyle/SKILL.md` (coexistence rule)
- Modify: `README.md` (new section "Relationship to the official Tuist plugin")

**Interfaces:**
- Consumes: nothing.
- Produces: a length-limit number from the Agent Skills spec, recorded in the PR.

- [ ] **Step 1: Research gates**
  1. Max `description` length in the Agent Skills spec (agentskills.io / Anthropic docs). Record URL + number. **Do not guess**; if unconfirmable, keep every description ≤ 500 characters and flag "Unverified".
  2. Re-read `tuist/agent-plugin` skill descriptions (https://github.com/tuist/agent-plugin) to confirm the quoted `generated-projects`/`migrate` triggers still hold at the time of work.

- [ ] **Step 2: Failing check**

```bash
for f in skills/*/SKILL.md; do awk '/^description:/,/^---/' "$f" | grep -qi "not for\|do not use" || echo "NO-NEGATIVE $f"; done   # currently 9 lines (test-target passes)
```
(Note: the awk range runs to the closing `---` of the frontmatter; confirm it does not leak into the body by running it on one file.)

- [ ] **Step 3: Rewrite each description** as three parts in the folded style of `skills/ios-tuist-test-target/SKILL.md` (read it first as the template): *what it does*; "Use when …"; "Not for …". Required content per skill:

| Skill | "Not for" must say |
|---|---|
| `ios-tuist-bootstrap` | existing Tuist project (→ feature); existing Xcode project (→ official Tuist `migrate`) |
| `ios-tuist-feature` | new project; dependency-only changes; extracting a module |
| `ios-tuist-dependency` | feature code; version upgrades |
| `ios-tuist-migrate` | **"Tuist version migration only; not for converting an Xcode project to Tuist"** (verbatim phrase from PRD) |
| `ios-tuist-module` | splitting code without a concrete checklist benefit (it refuses) |
| `ios-tuist-restyle` | sweeping a whole project; bundling a version bump |
| `ios-tuist-scaffold` | more than one template; running scaffold on the real tree |
| `ios-tuist-test-target` | (already has it — keep as is, only verify length) |
| `ios-tuist-ci` | authoring CI from scratch for a project with none |
| `ios-tuist-architecture-review` | making any edits |
Keep each description within the length found in Step 1.

- [ ] **Step 4: Coexistence rule.** In `ios-tuist-feature`, `ios-tuist-dependency` and `ios-tuist-restyle` bodies, add (under each skill's Decision Rules or Version Safety section; read to find the best spot) this paragraph:

```markdown
**Coexisting guidance.** If another Tuist guide (for example the
official Tuist plugin) recommends a current practice such as
`buildableFolders`, the existing project's conventions still win unless
the user explicitly asked for that change (folder-integration conversion
is `ios-tuist-restyle` only, on explicitly named targets).
```
In `restyle` word it as: "…an explicit restyle request is what authorises the conversion".

- [ ] **Step 5: README section.** Add "## Relationship to the official Tuist plugin" after the install section, containing: role split (official = current best practice, platform data, Xcode→Tuist `migrate`; this plugin = safe manifest changes that preserve an existing project's Tuist version and conventions); a note that both can be installed together and that conflicting advice resolves to project conventions; and this table:

| Request | Use |
|---|---|
| Convert this Xcode project to Tuist | official `migrate` |
| Upgrade Tuist 3 → 4 in this project | `ios-tuist-migrate` |
| Add `LoginFeature` | `ios-tuist-feature` |
| Convert named target to `buildableFolders` | `ios-tuist-restyle` |
| Debug a generated project / flaky tests | official skills |
Verify the sentence "does not replace Tuist's official…" in Non-goals (grep README) is still true and not contradicted.

- [ ] **Step 6: Run checks, expect pass**

```bash
for f in skills/*/SKILL.md; do awk '/^description:/,/^---/' "$f" | grep -qi "not for\|do not use" || echo "NO-NEGATIVE $f"; done   # none
for f in skills/*/SKILL.md; do awk '/^description:/{f=1} f&&/^---/{exit} f' "$f" | wc -c | xargs echo "$f"; done   # all ≤ limit
```

- [ ] **Step 7: Manual routing record (Unverified unless run).** With this plugin and the official `tuist` plugin installed in Claude Code, ask the three PRD prompts ("migrate this project from Tuist 3 to 4", "migrate this Xcode project to Tuist", "add LoginFeature") and write which skill was chosen into the PR. Codex cannot do this; hand off to the user.

- [ ] **Step 8: Commit**

```bash
git add skills README.md
git commit -m "docs: add negative routing to skill descriptions and official-plugin guidance"
```

---

### Task 5: WS5 — bootstrap refuses existing Xcode projects

Branch: `feature/v0.8-ws5`

**Files:**
- Modify: `skills/ios-tuist-bootstrap/SKILL.md` (Core Rule L12-16, Non-Trigger L32-37, Preconditions L39-44)
- Create (optional, in PRD): `tests/fixtures/existing-xcode/EXPECTATIONS.md` — no project files, not in the CI matrix

**Interfaces:** none cross-task.

- [ ] **Step 1: Failing check**: `grep -n "xcodeproj" skills/ios-tuist-bootstrap/SKILL.md` → no hits.

- [ ] **Step 2: Preconditions item 1** — append:

```markdown
   Also stop if the target path, or any directory one level below it,
   contains a `*.xcodeproj` or `*.xcworkspace`: this is an existing Xcode
   project, not a new one. Report what was found and that converting an
   Xcode project to Tuist is the official Tuist `migrate` skill's job;
   generate nothing.
```

- [ ] **Step 3: Core Rule** (L14-16): extend the parenthetical to "(no existing `Project.swift`, `Tuist.swift`, `Workspace.swift`, `*.xcodeproj` or `*.xcworkspace` at the target path)". **Non-Trigger Conditions**: add a bullet "The target contains an existing Xcode project (`*.xcodeproj`/`*.xcworkspace`) — Xcode→Tuist conversion belongs to the official Tuist `migrate` skill, not this one."

- [ ] **Step 4 (optional): Create `tests/fixtures/existing-xcode/EXPECTATIONS.md`** following another fixture's EXPECTATIONS layout (read `tests/fixtures/new-project/EXPECTATIONS.md` first): scenario = a directory with `Foo.xcodeproj/` (empty dir is enough), prompt "Create a new iOS app using Tuist here"; expected = stops, reports the Xcode project, names official `migrate`, creates no file; must-not = any `Project.swift` written. State at the top that it is a manual scenario, not in the CI matrix. Do not add it to `validate-fixtures.yml`. Because `check-fixture-pins.sh` reads the matrix only, no `.tool-versions` is required.

- [ ] **Step 5: Run check, expect pass**: `grep -n "xcodeproj" skills/ios-tuist-bootstrap/SKILL.md` → ≥ 1 hit. Also re-run Task 4's description check for bootstrap (its description should already mention existing Xcode projects).

- [ ] **Step 6: Commit**

```bash
git add skills/ios-tuist-bootstrap/SKILL.md tests/fixtures/existing-xcode
git commit -m "feat: stop bootstrap when an Xcode project already exists"
```

---

### Task 6: WS6 — isolated benchmark harness (after Task 3 is merged)

Branch: `feature/v0.8-ws6`

**Files:**
- Create: `scripts/benchmark-isolated-run.sh`
- Modify: `scripts/benchmark-prep-run.sh:22,106` (hard-coded `/Users/dave/...`)
- Modify: `docs/superpowers/benchmarks/2026-09-20-skill-effectiveness/EXECUTION-GUIDE.md`
- Modify: `docs/superpowers/benchmarks/2026-09-20-skill-effectiveness/AGGREGATE-SUMMARY.md` — only in Task 8 (footnote)

**Interfaces:**
- Consumes: Task 3 (every fixture has `.tool-versions`, so a copy outside the repo keeps its pin).
- Produces: `benchmark-isolated-run.sh prep|collect` CLI used in the Task 6 acceptance run.

Design: two subcommands, so no unverified `claude` CLI flags are baked in (the existing `benchmark-prep-run.sh` is also prep-then-manual).

```text
benchmark-isolated-run.sh prep    <fixture> <baseline|with-skill> <run-N> [--plugin-dir DIR]
benchmark-isolated-run.sh collect <fixture> <baseline|with-skill> <run-N>
```

- [ ] **Step 1: Read `scripts/benchmark-prep-run.sh` and `EXECUTION-GUIDE.md`** fully; mirror the former's style (shebang, `set -uo pipefail`, `REPO_ROOT` derivation, usage text). Failing check first: `grep -rn "/Users/" scripts/` → 2 hits.

- [ ] **Step 2: Fix hard-coded paths** in `benchmark-prep-run.sh`: replace both `claude --plugin-dir /Users/dave/...` occurrences with `claude --plugin-dir "${PLUGIN_DIR:-$REPO_ROOT}"` (comment line L22: describe `PLUGIN_DIR` env var; the echo at L106 must print the resolved path). Re-run `grep -rn "/Users/" scripts/` → none.

- [ ] **Step 3: Write `scripts/benchmark-isolated-run.sh`** (`prep`):
  1. Validate args; `SRC="$REPO_ROOT/tests/fixtures/$fixture"` must exist.
  2. `WORKDIR="$(mktemp -d -t tuist-bench)/$fixture"`; `cp -R "$SRC" "$WORKDIR"`.
  3. **Isolation guard:** walk from `$WORKDIR` upward to `/`; if any ancestor contains `skills/` together with `references/`, or a `CLAUDE.md`, print `ISOLATION VIOLATION: <path>` and `exit 1`. (Also fail if `$WORKDIR` resolves, via `realpath`, to a path under `$REPO_ROOT`.)
  4. `git -C "$WORKDIR" init -q && git -C "$WORKDIR" add -A && git -C "$WORKDIR" -c user.name=bench -c user.email=bench@example.invalid commit -qm baseline`.
  5. Snapshot dependency edges: `grep -n "dependencies\|\.target(\|\.project(\|\.external(" -r "$WORKDIR" --include=Project.swift --include=Tuist.swift --include=Package.swift > "$WORKDIR/../edges-before.txt"` (outside the repo copy so it's not in the diff).
  6. Print the exact manual command: baseline → `cd "$WORKDIR" && claude`; with-skill → `cd "$WORKDIR" && claude --plugin-dir "$PLUGIN_DIR"`; where `PLUGIN_DIR` comes from `--plugin-dir` or env `PLUGIN_DIR`, and is required for `with-skill` (exit 2 with usage if missing). Also print the workdir path and the matching `collect` command. Save workdir path to `<tmp>/state-<fixture>-<condition>-run<N>`.
  7. Before relying on the flag, run `claude --help | grep -- --plugin-dir` once and note the result in the PR (Unverified if `claude` unavailable).

- [ ] **Step 4: Write `collect`**: read the state file; run inside `$WORKDIR`: `git diff --stat HEAD`, `git status --porcelain | wc -l` (changed-file count incl. untracked), edge snapshot diff (`diff edges-before.txt edges-after.txt`), then `mise exec -- tuist generate --no-open`, `xcodebuild … build`/`test` **using the fixture's workspace and schemes from the CI matrix** (read them with the same ruby snippet as `validate-fixtures-locally.sh`; to avoid duplicating its build logic, factor nothing — instead call the same commands that script uses; read it L30-end and copy only the build/test invocation lines). Record `generate`/`build`/`test` as `pass|fail|skipped`. Write everything to `docs/superpowers/benchmarks/<date>-<name>/raw/<fixture>-<condition>-run<N>.md` where `<date>-<name>` comes from env `BENCH_DIR` (required; exit 2 if unset). Include header lines: date, condition, `claude --version` output (model version is recorded by the human — add a `Model:` line from env `BENCH_MODEL`, default `unrecorded`), workdir path, `git rev-parse HEAD` of the plugin repo.

- [ ] **Step 5: Static checks**

```bash
bash -n scripts/benchmark-isolated-run.sh scripts/benchmark-prep-run.sh
grep -rn "/Users/" scripts/          # none
./scripts/benchmark-isolated-run.sh prep extract-candidate baseline 1   # prints a path under $TMPDIR, no violation
```
Negative test of the guard: `TMPDIR="$PWD/.tmp-bench" mkdir -p "$TMPDIR"` then run prep → must print `ISOLATION VIOLATION` and exit 1; delete `.tmp-bench` afterwards (look at it before `rm`; it's your own scratch dir).

- [ ] **Step 6: Docs.** Append to `EXECUTION-GUIDE.md` a section "Isolated runs" with: the prep/run/collect procedure; policy (PR smoke N=1, release evaluation N≥3, record model version via `BENCH_MODEL`); and scoring principles (grader blind to condition; deterministic metrics take precedence over LLM scoring) labelled "documented, not implemented in v0.8".

- [ ] **Step 7: Acceptance run (hand off to Claude/user; needs `claude`, mise, Xcode).** Run `extract-candidate` networking prompt once with `baseline` and once with `with-skill`, then `collect` both. Attach the two raw `.md` files and show the workdirs were outside the repo. If it cannot be executed, say "Unverified" in the PR.

- [ ] **Step 8: Commit**

```bash
git add scripts docs/superpowers/benchmarks/2026-09-20-skill-effectiveness/EXECUTION-GUIDE.md
git commit -m "feat: add isolated benchmark harness and remove hard-coded paths"
```

---

### Task 7: WS7 — Codex manifest (conditional; may slip to v0.8.x)

Branch: `feature/v0.8-ws7`

**Files (exact contents depend on the research gate):**
- Create: `.agents/plugins/marketplace.json`, `.codex-plugin/plugin.json`, `scripts/sync-codex-manifest.sh`
- Modify: `.github/workflows/validate-fixtures.yml` (sync check job) or a new small workflow
- Modify: `README.md` Codex install instructions

**Interfaces:** Consumes `.claude-plugin/plugin.json` (source of truth: name, description, version).

- [ ] **Step 1: Research gate.** Read the current official Codex docs for plugins/marketplaces and openai/codex#19372. Record the exact required fields and file locations. **Do not write manifest field names from memory or from this plan.** If the docs don't define a stable spec, stop and report; defer WS7 to v0.8.x.
- [ ] **Step 2: Failing check.** `ls .agents/plugins/marketplace.json .codex-plugin/plugin.json` → missing.
- [ ] **Step 3: Write `scripts/sync-codex-manifest.sh`**: generates `.codex-plugin/plugin.json` from `.claude-plugin/plugin.json` using fields confirmed in Step 1 (use `ruby -rjson` as the repo already depends on ruby; avoid adding `jq` unless confirmed present in CI). Add a `--check` flag that regenerates to a temp file and `diff`s against the committed file, exiting non-zero on drift.
- [ ] **Step 4: Generate files, run** `./scripts/sync-codex-manifest.sh && ./scripts/sync-codex-manifest.sh --check` (expect exit 0). Mutate the version in a temp copy of `.claude-plugin/plugin.json` to confirm `--check` fails, then restore.
- [ ] **Step 5: CI**: add a job running `./scripts/sync-codex-manifest.sh --check`.
- [ ] **Step 6: Acceptance (user-run).** `codex plugin marketplace add doulos76/ios-tuist-skills` → install → enable; paste output in the PR. (Only possible after the branch is on GitHub.) Otherwise "Unverified".
- [ ] **Step 7: Commit**

```bash
git add .agents .codex-plugin scripts/sync-codex-manifest.sh .github/workflows README.md
git commit -m "feat: add Codex plugin manifest generated from the Claude manifest"
```

---

### Task 8: Release v0.8.0

Branch: `chore/release-0.8.0`

**Files:**
- Modify: `CHANGELOG.md`, `.claude-plugin/plugin.json` (version), `docs/superpowers/benchmarks/2026-09-20-skill-effectiveness/AGGREGATE-SUMMARY.md` (footnote)
- Check: `.claude-plugin/marketplace.json` (does it carry a version? grep first)

- [ ] **Step 1: Confirm Tasks 1–5 merged to `develop`** (6/7 included only if merged); `./scripts/validate-fixtures-locally.sh` passes for all fixtures (hand-off); `./scripts/check-fixture-pins.sh` exit 0.
- [ ] **Step 2: CHANGELOG** — one entry per merged WS, in the file's existing format (read the 0.7.1 entry first). The WS1 entry states the corrected diagnosis: "the `App -> NetworkingKit` defect was a spec contradiction across SKILL.md, EXPECTATIONS.md and the rubric, not an agent rule violation."
- [ ] **Step 3: Version** — `.claude-plugin/plugin.json` `"version": "0.8.0"`; `grep -rn "0\.7\.1" .claude-plugin README.md` and update only version strings tied to the plugin version (mirror what commit `8cc6c51` changed: `git show 8cc6c51 --stat`).
- [ ] **Step 4: AGGREGATE-SUMMARY footnote** — add at the end of the extract-candidate-networking row/section: "† Expected result corrected in v0.8 (WS1): `App` should not gain an edge to `NetworkingKit`. Scores above are unchanged." Do not alter any score.
- [ ] **Step 5: Commit and PR** (PR body ends with the attribution line from the session's system reminder; commit message ends with its Co-Authored-By line).

```bash
git add CHANGELOG.md .claude-plugin docs/superpowers/benchmarks/2026-09-20-skill-effectiveness/AGGREGATE-SUMMARY.md
git commit -m "chore: bump version to 0.8.0"
```

---

## Self-review (writer's)

- **Spec coverage:** WS1→Task 1, WS2→2, WS3→3, WS4→4, WS5→5, WS6→6, WS7→7, release checklist→8. All six PRD WS1 changes map to Steps 2-7 of Task 1; WS2 changes 1-9 map to Steps 1-6 of Task 2 (changes 5 and 7 are the research gate); WS3 changes 1-4 → Task 3 Steps 3, 6, 5, 6.
- **Known judgment calls:** Task 6 uses prep/collect rather than a single-shot runner so that no `claude` non-interactive flags are assumed; Task 3 puts the pin check in its own ubuntu job instead of the macOS matrix.
- **Open questions left to research gates:** PRD Q1 and Q2 (Task 2 Step 1, Task 4 Step 1). Q3 resolved; Q4 defaulted to "report only".
