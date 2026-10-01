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

**Spec:** `docs/superpowers/specs/2026-10-01-ios-tuist-skills-v0.8-design.md` (PRD §3 WS1–WS7 is authoritative for rationale and acceptance criteria), **amended by** `docs/superpowers/specs/2026-10-01-ios-tuist-skills-v0.8-design-addendum-1.md` ("Addendum 1", A1–A7). On any conflict the addendum wins; the PRD §0 working rules still apply. Read both before starting.

## Global Constraints

- Order (Addendum A1): WS1 → WS2 → WS3 → WS4 coexistence (README + body rules) → WS4 descriptions → WS5 → WS6 → WS7. Priorities: P0 = WS1–WS5 (WS5 raised from P1; description routing is its own P0 item), P1 = WS6, WS7. WS6 requires WS3 merged. WS4's two parts may share one branch but **must be separate commits** (Task 4).
- Both models reading the same PRD agreeing is not verification (Addendum §0.4): every piece of evidence is re-checked against real files and command output.
- **[미검증] items** (Addendum §9) are checked before implementing; if unconfirmed, the item is not implemented and is reported as "Unverified" in the PR (exact fallbacks are in each task).
- One workstream per branch; branch name `feature/v0.8-ws<N>`, cut from `develop`. Never mix workstreams.
- No new skills (`ios-tuist-adopt` is explicitly out of scope).
- Do not relax `ios-tuist-ci`'s "Never remove a validation step".
- No refactors, rewording or manifest modernization outside the PRD.
- Commit messages: Conventional Commits + Jira key if the project rule requires one; follow the style of `git log` on `develop`.
- Every verification command is actually run and its output pasted in the PR description. A command that cannot run is reported as "Unverified".
- Items marked **검증 필요** in the PRD are research gates: if the official source contradicts the PRD, stop and report instead of improvising.
- Do not edit scores in `docs/superpowers/benchmarks/**` (footnote only).
- Do **not** change `ios-tuist-ci`'s rule "Never remove a validation step (build, test, lint) to make CI faster." in v0.8 (Addendum A6). The v0.9+ rewrite idea is recorded in the spec addendum only.
- Jev / external decision models: not integrated, not documented in v0.8 (Addendum A7).
- Existing prohibition/limit phrases in skill descriptions ("Never sweeps…", "never edits code or manifests", "only skill … permitted to change a version pin", …) are never deleted or weakened when routing text is added (Addendum A4/§5.5).

## Review Focus

- Fixture dir with a **dotfile name collision**: `.tool-versions` added to a fixture must not change which Tuist `validate-fixtures-locally.sh` / mise selects for *other* fixtures (mise walks up from cwd; fixtures are siblings, so only the fixture's own file applies). Test by running the local validator for 2 fixtures with different pins.
- `migrate-candidate` pins 3.42.2 while repo-root mise config (if any) may pin 4.x: `mise exec -- tuist version` inside the fixture must print `3.42.2`.
- `version-safety.md` rewrite: a project with **no** pin anywhere must still produce "none detected" (not a crash/blank table row).
- Conflict case: `.mise.toml` says X, CI says Y → output reports a conflict and does not edit either (`version-mismatch` fixture).
- WS5: a **new empty dir that contains an unrelated `*.xcodeproj` one level down** is refused; an empty dir is not.
- Evidence-table input where **`Package.swift` says tools 5.9 while the pin is a Tuist version**: output must put it under Swift Evidence and never use it for the effective Tuist version.
- `.xcode-version`/`.swift-version` present but unverified as Tuist-consumed: they appear with the "Tuist does not consume" label, not silently dropped or treated as authoritative.
- Description rewrite for a skill already near the length cap (`ios-tuist-scaffold`): the existing "Never…" limits survive; routing text is what gets shortened.
- Benchmark harness run from a temp dir under the repo (e.g. `$TMPDIR` symlinked into the repo) must fail the "no repo `skills/` in ancestors" check.

## Execution notes

- Before each task, re-verify the **Evidence** block against the files. If the file differs from what is quoted, stop and report; don't edit.
- Pre-verified on 2026-10-02 against `492fd7e`: all WS1–WS6 evidence matched, with one nuance: `skills/ios-tuist-module/SKILL.md` step 5 already says "Move the extracted code's existing tests with it", so WS1-3 is only a clarification about the emptied source test target.
- Resolved open question 3: `tests/fixtures/ci-gaps/EXPECTATIONS.md` states the embedded workflow pins 4.206.0 "matching this fixture's project (no version mismatch to find here)". Adding `.tool-versions` `tuist 4.206.0` preserves the intent.
- Default for open question 4 (emptied original test target): **report only**, never delete; deletion is the user's decision (matches PRD WS1-3).
- Addendum A3 resolves open question 1: `Package.swift`/`Tuist/Package.swift` are **not** Tuist CLI version sources (Swift Evidence instead). Pre-check on 2026-10-02: no skill body, fixture or EXPECTATIONS uses them as Tuist-version evidence — only the lines of `references/version-safety.md` that WS2 removes.
- Addendum A6 (CI rule rewrite) and A7 (Jev) change nothing in this plan beyond the two Global Constraints above.
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

### Task 2: WS2 — version-safety: evidence collection, per-axis classification, conflict reporting

Branch: `feature/v0.8-ws2`. Governing text: PRD WS2 **as amended by Addendum 1 §A2/§A3** (the addendum wins on conflict).

**Files:**
- Modify: `references/version-safety.md` (replace "Detection order" L12-L38; update "Authority rule", "Mismatch handling" wording; put the evidence tables **before** the existing "Tuist Context" block)
- Modify: `skills/ios-tuist-migrate/SKILL.md:21,60,69` (they say "detection order" / "detection"); re-read L46-70 and reword only those phrases
- Modify (if contradicting): `tests/fixtures/version-mismatch/EXPECTATIONS.md`
- Modify (minimally, only if they contradict the new format): the Output Contract examples in `skills/*/SKILL.md`
- Check only: other `skills/*/SKILL.md`, fixture EXPECTATIONS (grep below)

**Interfaces:**
- Consumes: nothing.
- Produces: terms "Evidence collection", "Tool Version Evidence", "Xcode Evidence", "Swift Evidence", "Manifest Compatibility Evidence", "Effective project version", "Conflicts" used by Tasks 3, 5, 6.

Classification principle (Addendum §3.1): **only the Tool Version axis decides the effective Tuist version.** The other axes are compatibility-risk reporting only. Every piece of evidence records its source (file path or command), its value, and for commands the **cwd**.

- [ ] **Step 1: Research gates and decisions already made**
  - **Decided (Addendum §A3), no research needed:** `Package.swift` and `Tuist/Package.swift` are removed from the Tuist CLI version sources; their `// swift-tools-version:` lines become Swift Evidence. Pre-check run on 2026-10-02: `grep -rn "Package.swift" skills/ references/ tests/fixtures/*/EXPECTATIONS.md | grep -i "version"` found only `references/version-safety.md:21-22` (the lines being removed) plus an unrelated "Dependency Integration" line (`:84`). If your re-run finds any skill body, fixture or EXPECTATIONS using Package.swift as Tuist-version evidence, **do not edit it — report the location**.
  - **[미검증] `.xcode-version` / `.swift-version`:** search the official Tuist docs for whether Tuist consumes them. Not confirmed → keep them in the tables, labelled "Tuist does not consume this — evidence of project intent". If confirmed, update the label and cite the doc.
  - **Still a gate:** additional mise config paths (`mise.local.toml`, `.config/mise.toml`, …) per the mise docs: include only what the docs confirm.
  - Confirm `Tuist.swift` has no Tuist-version field (`compatibleXcodeVersions`, `swiftVersion` only): https://docs.tuist.dev/en/references/project-description/enums/tuistproject
  Record each as: question → source URL → answer, in the PR.

- [ ] **Step 2: Failing checks**

```bash
grep -n "stopping as soon as" references/version-safety.md       # 1 hit (FAIL)
grep -n "compatible version range" references/version-safety.md  # 1 hit (FAIL)
grep -n "Xcode Evidence\|Swift Evidence\|Tool Version Evidence\|Manifest Compatibility" references/version-safety.md   # 0 hits (FAIL; expect 4 after)
grep -rln "version-safety" skills/ | xargs grep -n -i "detection order"   # hits in migrate (FAIL)
```

- [ ] **Step 3: Replace "## Detection order" through the "none detected" paragraph** (keep the live-commands list and the "Core rule") with:

````markdown
## Evidence collection

Inspect **every** source below to the end — never stop at the first
pin. Record each value found with its source (file path or command) and,
for commands, the working directory they ran in. Evidence is classified
by axis; **only the Tool Version axis decides the effective Tuist
version.** The other axes exist to report compatibility risk.

### Tool Version axis (Tuist CLI)

Sources, highest authority first:

1. `mise.toml` / `.mise.toml` (plus any additional mise config paths
   confirmed by the mise docs)
2. `.tool-versions`
3. CI workflow files (e.g. `.github/workflows/*.yml`) that pin or install
   a specific Tuist version
4. Repository scripts (`Scripts/`, `Makefile`, `Brewfile`, bootstrap
   scripts) that install or reference a specific Tuist version

The highest-authority source that has a value gives the **effective
project version**. Any lower-authority source with a different value is
a **conflict**: list it under `Conflicts` (both values, both file
paths). Never resolve a conflict by editing — see Mismatch handling.

### Xcode axis (compatibility risk only)

`Tuist.swift` `compatibleXcodeVersions`; `.xcode-version` (Tuist does
not consume it — evidence of project intent); the active Xcode. If the
active Xcode is outside the declared range, report a risk.

### Swift axis (compatibility risk only)

`Tuist.swift` `swiftVersion`; `// swift-tools-version:` in
`Package.swift` and `Tuist/Package.swift`; `.swift-version` (Tuist does
not consume it — evidence of project intent); the active Swift.

### Manifest compatibility axis

Existing manifest syntax: if the syntax used is only valid for a version
range, record that range and the API/syntax it came from. This is
evidence of compatibility, not a version pin.

If the Tool Version axis yields nothing, record "none detected"
explicitly rather than defaulting to "latest."

### Live commands

Run from the project root and record the cwd with each result:

- `tuist version` (plain — what the user's shell resolves)
- `mise exec -- tuist version` (only when a mise config was found; the
  two can differ because mise switches versions per directory)
- `xcodebuild -version`
- `swift --version`
````

- [ ] **Step 4: Update "Authority rule"**: change "(found via steps 1–8 above)" to "(the effective project version from the Tool Version axis of Evidence collection)". Then, **immediately before** the existing "Tuist Context" block, add the evidence tables (Addendum §3.2):

````markdown
```text
Tool Version Evidence (Tuist CLI — decides the effective version)
-----------------------------------------------------------------
mise.toml / .mise.toml      <ver|none>   PRIMARY candidate #1
.tool-versions              <ver|none>   PRIMARY candidate #2
CI workflows                <ver|none>   (file path)
Scripts / Makefile          <ver|none>   (file path)
Active (plain)              <ver>        cmd: tuist version               cwd: <path>
Active (mise exec)          <ver|n/a>    cmd: mise exec -- tuist version  cwd: <path>
Effective project version:  <ver | none detected>
Conflicts:                  <list | none>

Xcode Evidence (compatibility risk only)
----------------------------------------
Tuist.swift compatibleXcodeVersions   <range|none>
.xcode-version                         <ver|none>   (Tuist does not consume; project intent)
Active                                  <ver>        cmd: xcodebuild -version   cwd: <path>

Swift Evidence (compatibility risk only)
----------------------------------------
Tuist.swift swiftVersion               <ver|none>
Package.swift swift-tools-version      <ver|none>
Tuist/Package.swift swift-tools-version<ver|none>
.swift-version                          <ver|none>   (Tuist does not consume; project intent)
Active                                  <ver>        cmd: swift --version       cwd: <path>

Manifest Compatibility Evidence
-------------------------------
Existing manifest syntax               <range|unknown>  (the API/syntax it came from)
```

`PRIMARY` marks whichever source supplied the effective version (not
always `.mise.toml`). Within an axis, differing values follow the
priority rule for the effective version **and** are listed under
`Conflicts`; conflicts are reported, never fixed. In the Tuist Context
block that follows, `Project Tuist:` is taken from `Effective project
version`.
````
Keep the existing "Tuist Context" block unchanged otherwise.

- [ ] **Step 5: Fix citing skills.** `skills/ios-tuist-migrate/SKILL.md` L21, L60, L69: replace "detection order" / "detection" phrasing with "evidence collection". Re-read each surrounding sentence so meaning survives (e.g. any "stop at the first pin" assumption). Then grep every `skills/*/SKILL.md` Output Contract example for `Tuist:` / version-context lines and update **only** those that contradict the new format (Addendum §3.3: minimal edits).

- [ ] **Step 6: Check `tests/fixtures/version-mismatch/EXPECTATIONS.md`**: it must describe pin 4.62.0 as the effective project version and the active version as the mismatch/conflict. Edit only if it names "detection order", `Tuist.swift` or `Package.swift` as a version source.

- [ ] **Step 7: Run checks, expect pass**

```bash
grep -n "stopping as soon as" references/version-safety.md        # none
grep -n "compatible version range" references/version-safety.md   # none
grep -n "Xcode Evidence\|Swift Evidence\|Tool Version Evidence\|Manifest Compatibility" references/version-safety.md   # 4 hits (headings; the table blocks add more — check the 4 axis names are all present)
grep -n "cwd" references/version-safety.md                        # >= 1
grep -rln "version-safety" skills/ | xargs grep -n -i "detection order"   # none
grep -n "Package.swift" references/version-safety.md              # only Swift-axis / Dependency-Integration mentions
```
Also read the finished file once and confirm no sentence says a non-Tool-axis item decides the effective version.

- [ ] **Step 8: Commit**

```bash
git add references/version-safety.md skills/ tests/fixtures/version-mismatch/EXPECTATIONS.md
git commit -m "feat: classify version evidence by axis and report conflicts"
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

### Task 4: WS4 — official-plugin coexistence (Part A) and description routing (Part B)

Branch: `feature/v0.8-ws4` — one branch, **two separate commits** (Addendum A1: items 4 and 5 are distinct P0 items). Governing text: PRD WS4 as amended by Addendum A4 (§5).

**Files:**
- Part A: `skills/ios-tuist-feature/SKILL.md`, `skills/ios-tuist-dependency/SKILL.md`, `skills/ios-tuist-restyle/SKILL.md` (coexistence rule); `README.md` (new section "Relationship to the official Tuist plugin")
- Part B: `skills/*/SKILL.md` frontmatter `description:` (all 10)

**Interfaces:**
- Consumes: nothing.
- Produces: the description length ceiling used, recorded in the PR (Part B).

## Part A — coexistence (commit 1)

- [ ] **Step A1: Re-check official-plugin facts.** Re-read `tuist/agent-plugin` skill descriptions (https://github.com/tuist/agent-plugin) to confirm the quoted `generated-projects` ("Use `buildableFolders` instead of `sources`…") and `migrate` (Xcode → Tuist) behavior still holds. If not, adjust the README wording to what is true and say so in the PR.

- [ ] **Step A2: Coexistence rule.** In `ios-tuist-feature`, `ios-tuist-dependency` and `ios-tuist-restyle` bodies, add (under each skill's Decision Rules or Version Safety section; read the file to find the best spot) this paragraph:

```markdown
**Coexisting guidance.** If another Tuist guide (for example the
official Tuist plugin) recommends a current practice such as
`buildableFolders`, the existing project's conventions still win unless
the user explicitly asked for that change (folder-integration conversion
is `ios-tuist-restyle` only, on explicitly named targets).
```
In `restyle` word it as: "…an explicit restyle request is what authorises the conversion".

- [ ] **Step A3: README section.** Add "## Relationship to the official Tuist plugin" after the install section, containing: role split (official = current best practice, platform data, Xcode→Tuist `migrate`; this plugin = safe manifest changes that preserve an existing project's Tuist version and conventions); a note that both can be installed together and that conflicting advice resolves to project conventions; and this table:

| Request | Use |
|---|---|
| Convert this Xcode project to Tuist | official `migrate` |
| Upgrade Tuist 3 → 4 in this project | `ios-tuist-migrate` |
| Add `LoginFeature` | `ios-tuist-feature` |
| Convert named target to `buildableFolders` | `ios-tuist-restyle` |
| Debug a generated project / flaky tests | official skills |
Verify the sentence "does not replace Tuist's official…" in Non-goals (grep README) is still true and not contradicted.

- [ ] **Step A4: Check and commit**

```bash
grep -n "Relationship to the official Tuist plugin" README.md      # 1 hit
grep -ln "Coexisting guidance" skills/*/SKILL.md                   # feature, dependency, restyle
git add skills README.md
git commit -m "docs: add official-plugin coexistence rules and README section"
```

## Part B — descriptions (commit 2)

- [ ] **Step B1: Length ceiling (research gate, Addendum §9).** Find the maximum `description` length in the official Agent Skills spec (agentskills.io / Anthropic docs). Record URL + number. **Do not guess.** If unconfirmable, the ceiling is the **longest existing description**, measured on 2026-10-02 as **493 characters** (`ios-tuist-scaffold`; folded text, whitespace collapsed, via the command in Step B5), and the PR says "Unverified: spec limit". Note: Addendum §5.3's example for `ios-tuist-migrate` is ~560 characters, i.e. **over** that fallback ceiling — shorten it (Step B3) rather than copy it.

- [ ] **Step B2: Failing checks**

```bash
for f in skills/*/SKILL.md; do awk '/^description:/,/^---/' "$f" | grep -qi "not for\|do not use" || echo "NO-NEGATIVE $f"; done   # currently 9 lines (test-target passes)
awk '/^description:/,/^---/' skills/ios-tuist-migrate/SKILL.md | grep -i "xcode project"      # 0 hits now (FAIL; expect >=1 after)
```
(The awk range runs to the closing `---` of the frontmatter; confirm it does not leak into the body by running it on one file.)

- [ ] **Step B3: Rewrite each description** as three parts in the folded style of `skills/ios-tuist-test-target/SKILL.md` (read it first as the template): *what it does*; "Use when …"; "Not for …" — **while preserving every existing prohibition/limit phrase** (Addendum §5.5). If the ceiling forces cuts, cut routing text before existing limits.

Existing phrases that must survive (verbatim meaning), measured today:

| Skill | Must keep | "Not for" must add |
|---|---|---|
| `ios-tuist-architecture-review` | "never edits code or manifests" | making edits (→ other skills) |
| `ios-tuist-bootstrap` | (new-project, minimum manifests, validate generate/build/test) | existing Tuist project (→ feature); existing Xcode project (→ official Tuist `migrate`). Do **not** mention `tuist init` (Addendum §9: unverified) |
| `ios-tuist-ci` | "Does not author a net-new CI pipeline for a project with none"; "applies improvements the user approves" | (already has the negative; add an explicit "Not for" phrase) |
| `ios-tuist-dependency` | "scoped to the narrowest target that actually requires the dependency" | feature code; version upgrades |
| `ios-tuist-feature` | "preserving project architecture, dependency conventions, Tuist version compatibility" | new project; dependency-only changes; module extraction |
| `ios-tuist-migrate` | **"The only skill in this repository permitted to change a project's Tuist version pin"** and **"only on an explicit, version-specific request"** — neither may be deleted or weakened | "Tuist **version** migration only; not for converting an Xcode project to Tuist (Tuist's official migration workflow)"; not for vague "update/modernize" requests with no target version |
| `ios-tuist-module` | "refusing the extraction … rather than splitting code on request alone" | splitting code without a concrete checklist benefit |
| `ios-tuist-restyle` | "Never sweeps a whole project, never bundles a version bump, never silently drops an exclusion"; "explicitly user-named targets" | (covered by the kept limits; add a "Not for" lead-in) |
| `ios-tuist-scaffold` | "Never authors more than one template per invocation, never generates Stencil control-flow syntax, never runs tuist scaffold against the real project tree" (already 493 chars: **shorten the routing/descriptive text, never these limits**) | (covered by the kept limits; add a "Not for" lead-in if length allows, otherwise reuse the existing "Never…" as the negative and note it) |
| `ios-tuist-test-target` | whole current text | already has it — only verify length |

Suggested `ios-tuist-migrate` shape (Addendum §5.3, **not to be copied blindly**; shorten to the ceiling):

```yaml
description: >
  Moves a project's pinned Tuist version to a user-specified target
  version, updating pin sources and only the manifest syntax that version
  requires. The only skill here permitted to change a Tuist version pin,
  and only on an explicit, version-specific request. Not for converting
  an Xcode project to Tuist (use Tuist's official migration workflow) or
  for vague "update/modernize" requests with no target version.
```
Check its length with the Step B5 command; if still over the ceiling, trim the first sentence, never the "only skill" / "explicit" clauses.

- [ ] **Step B4: Run checks, expect pass**

```bash
for f in skills/*/SKILL.md; do awk '/^description:/,/^---/' "$f" | grep -qi "not for\|do not use" || echo "NO-NEGATIVE $f"; done   # none
awk '/^description:/,/^---/' skills/ios-tuist-migrate/SKILL.md | grep -c -i "only skill\|explicit"   # >= 2
awk '/^description:/,/^---/' skills/ios-tuist-migrate/SKILL.md | grep -i "xcode project"            # >= 1
awk '/^description:/,/^---/' skills/ios-tuist-restyle/SKILL.md | grep -ci "never sweeps"            # 1
awk '/^description:/,/^---/' skills/ios-tuist-scaffold/SKILL.md | grep -ci "never runs tuist scaffold against the real project tree"   # 1 (phrase may wrap lines: if 0, check by eye with the folded text)
awk '/^description:/,/^---/' skills/ios-tuist-architecture-review/SKILL.md | grep -ci "never edits"   # 1 (same wrap caveat)
```

- [ ] **Step B5: Length check** (all ≤ ceiling from Step B1):

```bash
for f in skills/*/SKILL.md; do n=$(awk '/^description:/{f=1;next} f&&/^---/{exit} f' "$f" | tr '\n' ' ' | sed 's/  */ /g;s/^ //;s/ $//' | wc -c); echo "$n $f"; done | sort -rn
```

- [ ] **Step B6: Manual routing record (Unverified unless run).** With this plugin and the official `tuist` plugin installed in Claude Code, ask the three PRD prompts ("migrate this project from Tuist 3 to 4", "migrate this Xcode project to Tuist", "add LoginFeature") and write which skill was chosen into the PR. Codex cannot do this; hand off to the user. Also record in the PR whether the vague prompt "modernize this project's Tuist setup" is routed away from `ios-tuist-migrate`.

- [ ] **Step B7: Commit**

```bash
git add skills
git commit -m "docs: add Use/Not-for routing to skill descriptions without dropping existing limits"
```

---

### Task 5: WS5 — bootstrap refuses existing Xcode projects (P0 since Addendum A1)

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
Guidance text points **only** to the official Tuist `migrate` skill. Do not mention `tuist init` or any "integrate into an existing project" option: whether `tuist init` supports existing projects is unverified (Addendum §9). Optional check: `tuist init --help` (needs tuist; hand off). If it clearly documents existing-project support, still do not add it in v0.8 — report the finding in the PR.

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

Phase placement (Addendum A5): Phase 0 = fixture self-containment (Task 3, done before this task); **Phase 1 = this task** (isolation harness + one trial run). Phase 2 (repeated measurement, release evaluation N≥3, model version recorded) and Phase 3 (blind scoring, deterministic metrics first) are **documented only**, not implemented.

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

- [ ] **Step 6: Docs.** Append to `EXECUTION-GUIDE.md` a section "Isolated runs" with the Phase 0–3 table from Addendum §6 (Phases 2–3 marked "documented only, not implemented in v0.8") and: the prep/run/collect procedure; policy (PR smoke N=1, release evaluation N≥3, record model version via `BENCH_MODEL`); and scoring principles (grader blind to condition; deterministic metrics take precedence over LLM scoring) labelled "documented, not implemented in v0.8".

- [ ] **Step 7: Acceptance run (hand off to Claude/user; needs `claude`, mise, Xcode).** Run `extract-candidate` networking prompt once with `baseline` and once with `with-skill`, then `collect` both. Attach the two raw `.md` files and show the workdirs were outside the repo. If it cannot be executed, say "Unverified" in the PR.

- [ ] **Step 7b: Phase 0 acceptance (Addendum A5).** In the copied fixture, the with-skill run's version-safety **Tool Version Evidence** table must be fillable from **in-fixture pins alone** (`.tool-versions`, in-fixture CI files). If the run cites the repository-root CI matrix (`.github/workflows/validate-fixtures.yml` of this repo) as evidence, treat Phase 0 as incomplete and mark the acceptance **failed** (go back to Task 3). Record the finding in the raw result file. Depends on Task 2 (table format) and Task 3 (pins) being merged.

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

- [ ] **Step 0 (Addendum §10): Verify merge order** matched A1 (WS1, WS2, WS3, WS4 coexistence, WS4 descriptions, WS5, then WS6/WS7): `git log --merges --oneline develop` — report any deviation.
- [ ] **Step 1: Confirm Tasks 1–5 merged to `develop`** (6/7 included only if merged); `./scripts/validate-fixtures-locally.sh` passes for all fixtures (hand-off); `./scripts/check-fixture-pins.sh` exit 0.
- [ ] **Step 2: CHANGELOG** — one entry per merged WS, in the file's existing format (read the 0.7.1 entry first). The WS1 entry states the corrected diagnosis: "the `App -> NetworkingKit` defect was a spec contradiction across SKILL.md, EXPECTATIONS.md and the rubric, not an agent rule violation."
- [ ] **Step 3: Version** — `.claude-plugin/plugin.json` `"version": "0.8.0"`; `grep -rn "0\.7\.1" .claude-plugin README.md` and update only version strings tied to the plugin version (mirror what commit `8cc6c51` changed: `git show 8cc6c51 --stat`).
- [ ] **Step 3b (Addendum §10): CHANGELOG additions.** (a) State the version-safety output format change (per-axis evidence tables, Conflicts line, cwd recording) as a **breaking change** — user workflows that parse skill output may be affected. (b) Add a short "Verification gates" list with the result of each Addendum §9 item: `.xcode-version`/`.swift-version` Tuist consumption (confirmed / unconfirmed → "Tuist does not consume" labels kept), Agent Skills description max length (number + URL, or "unconfirmed → 493-char ceiling"), `tuist init` existing-project support (not mentioned in bootstrap either way), Codex plugin spec (confirmed / WS7 deferred to v0.8.x). Put the same list in the release PR.
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
- **Open questions left to research gates:** Q2 (Task 4 Part B Step B1) and the mise config paths (Task 2 Step 1). Q1 resolved by Addendum A3; Q3 resolved; Q4 defaulted to "report only".
- **Addendum 1 coverage:** A1 → Global Constraints order + Task 4 two commits + Task 5 priority; A2/A3 → Task 2; A4/§5.5 → Task 4 Part B (+ Global Constraints); A5 → Task 6 (phases, Step 7b); A6/A7 → Global Constraints + Execution notes (no code change); §9 → each task's gate + Task 8 Step 3b; §10 → Task 8 Steps 0, 3b.
