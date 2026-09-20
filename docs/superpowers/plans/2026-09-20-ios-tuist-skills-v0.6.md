# ios-tuist-skills v0.6 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Implementation owner: Codex.** The Claude session in this repository
> produces spec + plan only (brainstorming through writing-plans) and
> must not execute this plan — not even if later asked to "proceed" or
> "실행해주세요." Stop after this plan is saved and committed; hand off
> to Codex for execution.

**Goal:** Ship the v0.6 milestone of `ios-tuist-skills`: one new skill,
`ios-tuist-scaffold`, that authors one explicitly user-named `tuist
scaffold` template (a `Tuist/Templates/<name>/<name>.swift` manifest
plus the `.stencil` file(s) it references), verified by actually
running `tuist scaffold` in a scratch location. Includes one new real,
buildable fixture proving the template manifest doesn't break the
fixture's own `tuist generate`/build/test cycle, plus a documented
manual procedure for running `tuist scaffold` itself.

**Architecture:** Same flat plugin repo shape as prior milestones — no
new top-level directories. One self-contained `SKILL.md` lands in
`skills/ios-tuist-scaffold/`. No shared reference file changes — this
skill reads `references/source-of-truth.md` (existing conventions win:
an already-hand-written feature shape is the source of truth for what a
template should produce) and `references/version-safety.md`. It does
not read `references/testing.md` (creates no test targets) or
`references/dependencies.md` (a template manifest declares no
`ProjectDescription` target dependencies). One new fixture extends the
existing `.github/workflows/validate-fixtures.yml` matrix job — no new
workflow file, and no change needed to
`scripts/validate-fixtures-locally.sh` (it reads the matrix directly, so
a new entry is picked up automatically).

**Tech Stack:** Tuist 4.206.0 (matches this repo's other fixtures),
Xcode 27 / Swift 6.4, GitHub Actions (currently routed to a self-hosted
macOS runner per the temporary CI-credit measure — see
`.github/workflows/validate-fixtures.yml`'s `runs-on:` comment).

**Spec:** `docs/superpowers/specs/2026-09-20-ios-tuist-skills-v0.6-design.md`

## Global Constraints

- `SKILL.md` follows the same section structure as the other nine
  skills: Purpose, Trigger Conditions, Non-Trigger Conditions,
  Preconditions, Version Safety, Workflow, Decision Rules, Validation,
  Failure Handling, Output Contract (spec §3).
- Never author more than one template per invocation — multiple
  distinct templates are multiple invocations, not one sweep (spec §3
  Decision Rules).
- Never generate `Template.Item.string` or `.directory` items as this
  skill's own output — `.file(path:templatePath:)` backed by a
  `.stencil` file only, unless explicitly stated why a specific request
  doesn't fit that shape (spec §3.4, Decision Rules).
- Never write `.stencil` files using Stencil control-flow syntax
  (`{% for %}` / `{% if %}` / filters) — attribute substitution
  (`{{ attributeName }}`) only. This is a deliberately narrower claim
  than "Stencil supports more than this": this plan and the skill it
  documents only assert behavior that is verified against Tuist's own
  documented example, not the full Stencil templating language (spec
  §3.3).
- Never run `tuist scaffold` against the real project tree as
  validation — only in a scratch location, deleted afterward. The only
  files this skill commits are the template definition itself (spec
  §3.5, Decision Rules).
- Never author a resource-accessor-synthesis template
  (`Plugin.swift`/`ResourceSynthesizers/`) under this skill — a distinct
  Tuist mechanism with a different manifest shape, out of scope (spec
  Non-Trigger Conditions).
- Fixtures under `tests/fixtures/` must be real, independently buildable
  Tuist projects — not structure-only stand-ins (spec §4.1).
- The new fixture joins the existing `validate-fixtures.yml` matrix (one
  job, extended) — do not create a second CI workflow file. CI validates
  only that the fixture's baseline project still resolves/generates/
  builds/tests with the template files present — it does not run `tuist
  scaffold` itself, since scaffold output isn't something `xcodebuild`
  exercises (spec §4.2).
- The verified, real Tuist API shapes used throughout this plan
  (confirmed live via Context7 `/tuist/tuist` docs during plan
  authoring — the same verification discipline as prior milestones):
  - `Template(description: String, attributes: [Template.Attribute] =
    [], items: [Template.Item] = [])`.
  - `Template.Attribute.required(_ name: String)` and
    `.optional(_ name: String, default: <string literal>)` (e.g.
    `.optional("platform", default: "ios")`, per Tuist's own documented
    example).
  - `Template.Item.file(path: String, templatePath: Path)` — this
    plan's only generated `Template.Item` case. `.string(path:
    contents:)` and `.directory(path: sourcePath:)` also exist on
    `Template.Item` but are not used by this plan's generated output
    (spec §3.4).
  - **`path:` is a plain Swift `String`, not itself rendered through
    Stencil.** Tuist's own documented pattern for a dynamic file name
    is ordinary Swift string interpolation of the attribute value in
    the manifest — `"Sources/\(nameAttribute)Label.swift"` — not
    `{{ name }}` syntax inside the `path:` argument. `{{ name }}`
    substitution is verified only for **file contents** rendered
    through a `.stencil` file (the `templatePath:` target), never for
    `path:` itself. Every `path:` in this plan that needs to vary by
    attribute uses `\(attributeName)` string interpolation directly in
    the manifest; every `{{ attributeName }}` in this plan appears only
    inside `.stencil` file bodies.
  - Manifest location convention: `Tuist/Templates/<name>/<name>.swift`
    (a directory-naming convention Tuist discovers by scanning
    `Tuist/Templates/`, not a `ProjectDescription` type or a value
    passed to any API call).
  - Invocation: `tuist scaffold <name> --<attribute> <value>` for each
    required attribute; optional attributes may be omitted to use their
    default.
  - Do not substitute any other shape if improvising beyond what's
    written in this plan (e.g. inventing additional `Template.Item`
    cases, or a `Template.Attribute` form other than `.required`/
    `.optional` shown above).
- MIT license header style is not required per-file; `LICENSE` at repo
  root already covers the whole repo.

---

### Task 1: `ios-tuist-scaffold` skill

**Files:**
- Create: `skills/ios-tuist-scaffold/SKILL.md`
- Create: `skills/ios-tuist-scaffold/references/.gitkeep`

**Interfaces:**
- Consumes: `references/source-of-truth.md` (existing conventions win),
  `references/version-safety.md` (detection order).
- Produces: nothing later tasks import structurally — Task 2's fixture
  is validated independently against this skill's Output Contract
  shape, not linked to it in code.

- [ ] **Step 1: Create the skill directory and empty references folder**

```bash
mkdir -p skills/ios-tuist-scaffold/references
touch skills/ios-tuist-scaffold/references/.gitkeep
```

- [ ] **Step 2: Write `skills/ios-tuist-scaffold/SKILL.md`**

Create with this exact content:

```markdown
---
name: ios-tuist-scaffold
description: >
  Authors one explicitly user-named tuist scaffold template — its
  Tuist/Templates/<name>/<name>.swift manifest plus the .stencil
  file(s) it references — matching a file/content shape the user
  describes or that already exists as hand-written files in the
  project, and verifies it by actually running tuist scaffold in a
  scratch location. Never authors more than one template per
  invocation, never generates Stencil control-flow syntax, never runs
  tuist scaffold against the real project tree.
---

# Core Rule

Author exactly one template per invocation, matching a shape the user
explicitly describes or points at in existing files — never guess the
boilerplate/variable boundary silently when it's ambiguous. This
skill's only generated `Template.Item` output is `.file` backed by a
`.stencil` file using attribute substitution only. Validation always
means an actual `tuist scaffold` run in a scratch location, never a
manifest read-through.

## Purpose

Author one new, explicitly user-named `tuist scaffold` template — its
`Tuist/Templates/<name>/<name>.swift` manifest plus the `.stencil`
file(s) it references — matching a file/content shape the user
describes or that already exists as hand-written files elsewhere in the
project, and verify it by actually generating output with `tuist
scaffold` in a scratch location.

## Trigger Conditions

- "Make a scaffold template for creating new features"
- "Turn this LoginFeature folder into a `tuist scaffold` template named
  `feature`"
- "Add a template so `tuist scaffold viewmodel --name X` generates a
  ViewModel + its test file"

The request must name (or unambiguously imply) one specific template
name and describe or point at one concrete file/content shape to
generate.

## Non-Trigger Conditions

- The request names no template shape at all ("set up scaffolding for
  this project") — out of scope for this pass; ask what the template
  should generate rather than inventing a shape.
- The request asks to *use* an existing template to generate actual
  project files right now — that's a plain `tuist scaffold` invocation
  (or [`ios-tuist-feature`](../ios-tuist-feature/SKILL.md)'s existing
  "reuse the scaffold" branch when a new feature is being added); this
  skill only authors templates, it does not run them against the real
  project tree.
- The request is to add real feature code/targets directly to
  `Project.swift` — that's
  [`ios-tuist-feature`](../ios-tuist-feature/SKILL.md).
- The request is to extract existing code into a new build target
  (`.framework`, `.staticFramework`, etc.) — that's
  [`ios-tuist-module`](../ios-tuist-module/SKILL.md).
- The request is to create a resource-accessor-synthesis template
  (`Plugin.swift` + `ResourceSynthesizers/Strings.stencil` etc. for
  `tuist generate`'s resource synthesis) — a distinct Tuist mechanism
  with a different manifest shape and trigger; out of scope for this
  skill.
- No existing Tuist project, or the project has no `Tuist/` directory to
  place `Templates/` under (bootstrap first — that's
  [`ios-tuist-bootstrap`](../ios-tuist-bootstrap/SKILL.md)).

## Preconditions

An existing Tuist project is present and readable; one specific
template name is given or unambiguous; the shape to generate is either
described explicitly by the user or points at concrete existing files
in the project to model the template on.

## Version Safety

Full [version-safety](../../references/version-safety.md) procedure,
Existing Project Mode. `Template`/`Template.Item`/`Template.Attribute`
are long-stable `ProjectDescription` API; still confirm the pinned
version so generated manifest syntax is one the pinned version actually
accepts, per the repo-wide rule.

## Workflow

1. **Resolve the template name and target shape.**
   - If the user points at existing hand-written files ("turn
     LoginFeature into a template"), read those files to determine
     which parts are boilerplate (become `.stencil` content) versus
     which parts are the one-off names/values to parameterize (become
     `Template.Attribute` substitutions).
   - If the user describes the shape from scratch, confirm the concrete
     file list and their relative paths before writing anything.
2. **Resolve attributes.** Identify which values the template consumer
   will supply at `tuist scaffold` time (e.g. a feature/module name) as
   `Template.Attribute.required(_:)` or `.optional(_:default:)`; every
   other value is fixed template content.
3. **Write the `.stencil` file(s)** under `Tuist/Templates/<name>/` (or
   a subdirectory referenced by `templatePath`, matching the project's
   own layout preference if one is already established) — plain file
   content with `{{ attributeName }}` substitutions only (see below for
   the syntax boundary this skill stays inside).
4. **Write the template manifest** at
   `Tuist/Templates/<name>/<name>.swift`:
   - `Template(description:attributes:items:)`.
   - One `Template.Item.file(path:templatePath:)` per `.stencil` file
     (see below for why this skill's generated items are `.file`-only).
     When the output file's own name/path must vary by attribute (the
     common case — e.g. a feature name in the file name), use ordinary
     Swift string interpolation of the attribute in `path:` (e.g.
     `path: "Sources/\(nameAttribute)Label.swift"`), never `{{ }}`
     syntax in `path:` — `{{ attributeName }}` substitution is only
     verified for `.stencil` file *contents*, not for `path:` itself.
   - `description` states in plain language what the template produces,
     for `tuist scaffold`'s own `--help` output.
5. **Validate** — run `tuist scaffold <name> --name <value>` (and any
   other required attributes) in a scratch location; inspect the
   generated file(s) for correct attribute substitution; if the
   generated output is Swift, confirm it is syntactically valid /
   compiles standalone; clean up the scratch location afterward. No
   files are generated inside the real project tree by this skill
   itself — only the template definition is committed.

### Confirm the shape before generating, not after

When modeling a template on existing hand-written files (the common
case — a project that has already hand-written the same feature/module
shape more than once), read those files fully before writing the
`.stencil` equivalents. Silently guessing at what varies versus what's
fixed produces a template that generates subtly wrong output the first
time someone actually uses it; confirm the attribute list with the user
before writing files when the boilerplate/variable boundary is
ambiguous (e.g. a hardcoded string that might be meant to vary per
target, or might genuinely be fixed across every use of this template).

### Stencil syntax boundary: substitution only

This skill's `.stencil` files use only attribute substitution
(`{{ attributeName }}`) — the syntax Tuist's own template-authoring
documentation demonstrates and this repository has verified. Stencil's
broader templating-language features (`{% for %}` loops, `{% if %}`
conditionals, filters, etc.) are conventional Stencil syntax but are
**not independently verified against Tuist's specific Stencil
integration**: every `.stencil` file this skill writes must be a
straight-line file with attribute substitutions only, never a
control-flow template. If a user's request requires conditional or
repeated content, state that this skill's verified scope is
substitution-only and the more complex template would need to be
authored (and tested) by hand.

### Why `.file` (`.stencil`), not `.string` or `.directory`

`Template.Item` has three cases, but this skill only ever generates
`.file(path:templatePath:)` items backed by a `.stencil` file:

- `.string(path:contents:)` embeds file content as a literal Swift
  string directly in the manifest, using Swift string interpolation
  (not Stencil substitution) for dynamic parts. It produces an
  unreadable, hard-to-maintain manifest for anything resembling a real
  source file, and mixes two different substitution mechanisms (Swift
  interpolation in the manifest vs. Stencil in `.stencil` files) in one
  template.
- `.directory(path:sourcePath:)` copies an existing directory verbatim,
  with no substitution at all — it cannot parameterize a name or value
  anywhere in the copied content, which defeats the purpose of a
  request where a name must vary per invocation.
- `.file(path:templatePath:)` with a `.stencil` file is the only one of
  the three that both keeps generated-file content in its own readable
  file rather than a Swift string literal, and supports per-invocation
  attribute substitution.

If a user's request is better served by `.string` or `.directory` (e.g.
copying a fixed set of non-templated fixture assets with no
substitution needed), state that explicitly and explain why `.file`
isn't the right fit, rather than forcing a `.stencil` file that has
nothing to substitute.

### Validation is a real `tuist scaffold` run, not a manifest read-through

Authoring a template manifest and its `.stencil` files is not
sufficient on its own:

1. Copy (or work from a scratch subdirectory that is not part of the
   committed project tree).
2. Run `tuist scaffold <name> --<attribute> <value>` for every required
   attribute, using a representative value.
3. Inspect the generated file(s): confirm every `{{ attributeName }}`
   substitution resolved to the expected value, and confirm the file
   landed at the expected `path`.
4. If the generated output is a `.swift` file, confirm it is
   syntactically valid — at minimum `swiftc -parse` succeeds, and (if it
   plausibly belongs in the project's existing target graph) confirm it
   compiles in that context.
5. Delete the scratch location afterward. Nothing generated by this
   validation step is committed — only the template definition
   (`Tuist/Templates/<name>/`) is.

## Decision Rules

- Never author more than one template per invocation — a request for
  multiple distinct templates is multiple invocations, not one sweep.
- Never guess the boilerplate/variable boundary silently when it's
  ambiguous — confirm with the user before writing files.
- Never write a `.stencil` file using Stencil control-flow syntax
  (`{% for %}` / `{% if %}` / filters) — substitution-only.
- Never generate `Template.Item.string` or `.directory` items as this
  skill's own output — `.file` + `.stencil` only, unless explicitly
  stated why a specific request doesn't fit that shape.
- Never run `tuist scaffold` against the real project tree as part of
  "validating" a template — validation happens in a scratch location
  only; the only files this skill commits are the template definition
  itself.
- Never create a resource-accessor-synthesis template
  (`Plugin.swift`/`ResourceSynthesizers/`) under this skill — a distinct
  mechanism, out of scope.
- A refusal (no concrete shape given, ambiguous boilerplate/variable
  boundary left unconfirmed, request is actually for template *usage*
  not authorship) is a valid, complete outcome.

## Validation

Required before declaring success: the manifest and `.stencil` file(s)
exist under `Tuist/Templates/<name>/`; `tuist scaffold <name>
--<attribute> <value>` run in a scratch location succeeds and produces
the expected file(s) with correct substitutions; generated Swift output
parses/compiles; the scratch location is cleaned up; no files were
generated inside the real project tree by this skill.

## Failure Handling

Evidence-Driven Debugging, same procedure as the other skills. First
hypothesis to consider here specifically: a `{{ attributeName }}`
placeholder that doesn't match the attribute's declared name exactly
(case or spelling) renders as literal, unsubstituted text rather than
failing loudly — inspect the generated file's actual content
character-for-character against the expected value, don't assume a
successful `tuist scaffold` exit code means substitution worked
correctly.

## Output Contract

```text
Version Context
Template Name
Shape Modeled On (existing files, or user description)
Attributes Defined (required / optional with defaults)
Files Written (manifest path, .stencil path(s))
Validation Performed (scratch-location scaffold run, substitution
check, compile check if applicable)
Unverified Items
Risks / Follow-up
```

Example (template authored from an existing hand-written feature):

```text
Version Context: Tuist 4.206.0 (project-pinned, matches active)

Template Name: feature

Shape Modeled On: existing LoginFeature/ folder (Project.swift target
declaration + Sources/LoginFeatureViewModel.swift + one Swift Testing
test file) — the user pointed at this as the pattern to templatize.

Attributes Defined:
- name (required) — the feature name, e.g. "Login" -> LoginFeature
- includeTests (optional, default: "true")

Files Written:
- Tuist/Templates/feature/feature.swift
- Tuist/Templates/feature/viewmodel.stencil
- Tuist/Templates/feature/test.stencil

Validation:
- Scratch run: `tuist scaffold feature --name Sample` in
  /tmp/scaffold-verify — succeeded
- Generated file name resolved correctly to Sources/SampleViewModel.swift
  (path: uses \(nameAttribute) string interpolation in the manifest)
- Generated file's {{ name }} content substitutions resolved correctly
  ("Sample" appears where expected)
- Generated file compiles standalone (`swiftc -parse`): success
- Scratch location deleted after verification

Risks / Follow-up:
- This template only covers the single-file ViewModel shape observed in
  LoginFeature; if the project's feature shape later grows a second
  file type, the template will need a matching update.
```

Example (refused — ambiguous boilerplate/variable boundary):

```text
Version Context: Tuist 4.206.0 (project-pinned, matches active)

Template Name: viewmodel

Shape Modeled On: user description ("a ViewModel file like the ones we
already have").

Files Written: none — refused.

Risks / Follow-up:
- The existing ViewModel files disagree on whether the associated
  Combine import is always present or feature-specific; before writing
  the template, confirm whether that import should be fixed content or
  a templated attribute.
```
```

- [ ] **Step 3: Verify the frontmatter and section structure**

```bash
head -12 skills/ios-tuist-scaffold/SKILL.md
grep -c "^## " skills/ios-tuist-scaffold/SKILL.md
```

Expected: frontmatter block with `name: ios-tuist-scaffold` and a
`description`; 10 `##`-level sections matching the other skills'
pattern (Purpose, Trigger Conditions, Non-Trigger Conditions,
Preconditions, Version Safety, Workflow, Decision Rules, Validation,
Failure Handling, Output Contract).

- [ ] **Step 4: Verify the relative reference links resolve**

```bash
test -f references/source-of-truth.md && echo "OK: source-of-truth.md exists"
test -f references/version-safety.md && echo "OK: version-safety.md exists"
test -f skills/ios-tuist-feature/SKILL.md && echo "OK: ios-tuist-feature SKILL.md exists"
test -f skills/ios-tuist-module/SKILL.md && echo "OK: ios-tuist-module SKILL.md exists"
test -f skills/ios-tuist-bootstrap/SKILL.md && echo "OK: ios-tuist-bootstrap SKILL.md exists"
```

Expected: all five `OK:` lines print.

- [ ] **Step 5: Verify no Stencil control-flow syntax and no
  `.string`/`.directory` items are shown as this skill's own generated
  output**

```bash
grep -n "{% for\|{% if" skills/ios-tuist-scaffold/SKILL.md || echo "OK: no control-flow Stencil syntax in the skill doc"
grep -n "Template.Item.string(\|Template.Item.directory(\|\.string(\s*path:\|\.directory(\s*path:" skills/ios-tuist-scaffold/SKILL.md || echo "OK: no .string/.directory item generation shown as this skill's output"
grep -n 'path: "[^"]*{{' skills/ios-tuist-scaffold/SKILL.md || echo "OK: no {{ }} syntax used inside a path: string"
```

Expected: all three `OK:` lines print (the skill doc *talks about*
`.string` and `.directory` existing and explains why they're not used,
but never shows them as this skill's own generated `Template.Item`
output; and `path:` values shown in the doc use `\(attributeName)`
string interpolation, never `{{ }}` syntax, per the Global Constraints
fact about `path:` not being Stencil-rendered).

- [ ] **Step 6: Commit**

```bash
git add skills/ios-tuist-scaffold/
git commit -m "docs: add ios-tuist-scaffold skill"
```

---

### Task 2: Fixture — `tests/fixtures/scaffold-candidate/`

**Files:**
- Create: `tests/fixtures/scaffold-candidate/Tuist.swift`
- Create: `tests/fixtures/scaffold-candidate/Project.swift`
- Create: `tests/fixtures/scaffold-candidate/App/Sources/ScaffoldCandidateApp.swift`
- Create: `tests/fixtures/scaffold-candidate/Tuist/Templates/feature/feature.swift`
- Create: `tests/fixtures/scaffold-candidate/Tuist/Templates/feature/source.stencil`
- Create: `tests/fixtures/scaffold-candidate/EXPECTATIONS.md`

**Interfaces:**
- Consumes: nothing from Task 1 structurally (the fixture is plain Tuist
  project content plus one committed template, not skill code).
- Produces: a real Tuist 4.206.0 project that Task 3's CI matrix entry
  validates as-committed (the baseline `App` project resolves,
  generates, builds, and tests with the `Tuist/Templates/feature/`
  directory present alongside it), and that a human (or an agent
  invoking `ios-tuist-scaffold`) can exercise the actual `tuist
  scaffold feature --name <value>` run as a manual procedure
  documented in `EXPECTATIONS.md`.

This fixture is deliberately minimal on the project side (one `App`
target, matching the minimal shape of other single-target fixtures in
this repo) — its purpose is to prove two things: (1) a
`Tuist/Templates/` directory with a real template inside it does not
break `tuist generate`/build/test for the rest of the project, and (2)
the committed `feature` template itself, when actually run via `tuist
scaffold`, produces correct output. (1) is what CI checks automatically
(Task 3); (2) is a manual procedure this task performs once during
authoring and documents in `EXPECTATIONS.md` for future re-verification
(same "CI proves the buildable baseline; the skill's own Validation
step proves the behavior" split used by every fixture since v0.2).

- [ ] **Step 1: Create `Tuist.swift`**

```swift
import ProjectDescription

let tuist = Tuist()
```

- [ ] **Step 2: Create `Project.swift`**

```swift
import ProjectDescription

let project = Project(
    name: "ScaffoldCandidate",
    targets: [
        .target(
            name: "App",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.ios-tuist-skills.scaffold-candidate",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["App/Sources/**"]
        )
    ]
)
```

- [ ] **Step 3: Create the app source**

```bash
mkdir -p tests/fixtures/scaffold-candidate/App/Sources
```

`tests/fixtures/scaffold-candidate/App/Sources/ScaffoldCandidateApp.swift`:

```swift
import SwiftUI

@main
struct ScaffoldCandidateApp: App {
    var body: some Scene {
        WindowGroup {
            Text("ScaffoldCandidate")
        }
    }
}
```

- [ ] **Step 4: Create the committed `feature` template's `.stencil`
  file**

```bash
mkdir -p tests/fixtures/scaffold-candidate/Tuist/Templates/feature
```

`tests/fixtures/scaffold-candidate/Tuist/Templates/feature/source.stencil`:

```text
public enum {{ name }}Label {
    public static let text = "{{ name }}"
}
```

(A single attribute substitution, `{{ name }}`, used twice — proves
multi-occurrence substitution within one file, not just a single
`{{ }}` per file.)

- [ ] **Step 5: Create the template manifest**

`tests/fixtures/scaffold-candidate/Tuist/Templates/feature/feature.swift`:

```swift
import ProjectDescription

let nameAttribute: Template.Attribute = .required("name")

let template = Template(
    description: "Generates a single Swift source file declaring a "
        + "public enum named <name>Label with a static text property.",
    attributes: [
        nameAttribute
    ],
    items: [
        .file(
            path: "Sources/\(nameAttribute)Label.swift",
            templatePath: "source.stencil"
        )
    ]
)
```

`path:` uses ordinary Swift string interpolation (`\(nameAttribute)`)
to vary the output file name — **not** `{{ name }}` syntax, which is
only valid inside a `.stencil` file's contents (see Global Constraints;
Tuist's own documented example uses this exact `\(nameAttribute)`
interpolation pattern for dynamic paths/content in the manifest, versus
`{{ name }}` for `.stencil` file bodies). `source.stencil`'s own content
(Step 4) is the only place `{{ name }}` appears in this template.

- [ ] **Step 6: Write `EXPECTATIONS.md`**

```markdown
# scaffold-candidate

## Starting state

- Pinned Tuist version: **4.206.0** (matches this repository's other
  fixtures).
- One target (`App`) — minimal, matching the single-target shape of
  other fixtures whose purpose is proving a mechanism rather than
  exercising a target graph.
- One committed `tuist scaffold` template at
  `Tuist/Templates/feature/feature.swift`, backed by
  `Tuist/Templates/feature/source.stencil`:
  - `required("name")` attribute.
  - One `Template.Item.file(path: "Sources/\(nameAttribute)Label.swift",
    templatePath: "source.stencil")` item — `path:` varies by ordinary
    Swift string interpolation of the attribute, not `{{ }}` syntax.
  - `source.stencil` renders a single Swift file declaring
    `public enum <name>Label { public static let text = "<name>" }`.
- Verified live: `tuist generate --no-open` succeeds with the
  `Tuist/Templates/feature/` directory present; `xcodebuild build` for
  scheme `App` succeeds.

## What `ios-tuist-scaffold` is expected to do with this fixture

Given "add a scaffold template that generates a labeled-enum Swift file
from a name," `ios-tuist-scaffold` is expected to author exactly this
`Tuist/Templates/feature/` structure (or an equivalent one, if the
user's actual request differs in file shape) and then run `tuist
scaffold feature --name <value>` in a scratch location — never inside
this fixture's own committed tree — to prove it. This fixture's
committed template is the reference example of correct output; it is
not itself modified by any skill run (this skill authors *new*
templates on request, it does not edit an already-existing one as a
side effect).

## Manual validation (not run by the outer CI matrix)

1. `mise exec tuist@4.206.0 -- tuist install` and `tuist generate
   --no-open` succeed from this directory as committed, with
   `Tuist/Templates/feature/` present.
2. `xcodebuild -workspace ScaffoldCandidate.xcworkspace -scheme App
   -destination 'generic/platform=iOS Simulator' build` succeeds.
3. In a **scratch** copy of this directory (never the committed tree):
   `mise exec tuist@4.206.0 -- tuist scaffold feature --name Sample`
   succeeds and produces `Sources/SampleLabel.swift` containing:
   ```swift
   public enum SampleLabel {
       public static let text = "Sample"
   }
   ```
4. The generated file parses as valid Swift
   (`swiftc -parse Sources/SampleLabel.swift`).
5. The scratch copy is deleted after verification; nothing from step 3
   is committed.

CI (`validate-fixtures.yml`) only proves step 1–2's baseline state is
real and buildable at 4.206.0 with the template files present — step
3–5's actual `tuist scaffold` run is `ios-tuist-scaffold`'s own
Validation step, exercised when the skill runs, per the v0.6 spec §4.2.
```

- [ ] **Step 7: Validate the fixture generates and builds at its pinned
  version**

```bash
cd tests/fixtures/scaffold-candidate
mise install tuist@4.206.0
test "$(mise exec tuist@4.206.0 -- tuist version)" = "4.206.0"
mise exec tuist@4.206.0 -- tuist install
mise exec tuist@4.206.0 -- tuist generate --no-open
xcodebuild -workspace ScaffoldCandidate.xcworkspace -scheme App \
  -destination 'generic/platform=iOS Simulator' build
```

Expected: version check passes; `tuist install`/`tuist generate`
succeed; `** BUILD SUCCEEDED **`.

- [ ] **Step 8: Confirm the committed `feature` template actually works
  end-to-end, in a scratch copy (proves the fixture's template is real,
  not assumed)**

```bash
cd /Users/dave/Documents/GitHub/ios-tuist-skills
rm -rf /tmp/scaffold-candidate-verify
cp -R tests/fixtures/scaffold-candidate /tmp/scaffold-candidate-verify
cd /tmp/scaffold-candidate-verify
mise exec tuist@4.206.0 -- tuist scaffold feature --name Sample
cat Sources/SampleLabel.swift
swiftc -parse Sources/SampleLabel.swift
```

Expected: `tuist scaffold` succeeds; `Sources/SampleLabel.swift`
contains exactly:
```swift
public enum SampleLabel {
    public static let text = "Sample"
}
```
(both `{{ name }}` occurrences correctly resolved to `Sample`);
`swiftc -parse` exits 0 with no output. Do not proceed to Step 9 until
this is confirmed — an unexpected failure here means the fixture's
committed template isn't actually correct.

- [ ] **Step 9: Delete the scratch copy — nothing from Step 8 is
  committed**

```bash
rm -rf /tmp/scaffold-candidate-verify
```

- [ ] **Step 10: Clean generated artifacts before committing**

```bash
cd /Users/dave/Documents/GitHub/ios-tuist-skills
rm -rf tests/fixtures/scaffold-candidate/Derived
rm -rf tests/fixtures/scaffold-candidate/ScaffoldCandidate.xcworkspace
rm -rf tests/fixtures/scaffold-candidate/ScaffoldCandidate.xcodeproj
git status --short tests/fixtures/scaffold-candidate/
```

Expected: only the 6 authored files from Steps 1–6 show as untracked —
no generated project/workspace/Derived content.

- [ ] **Step 11: Commit**

```bash
git add tests/fixtures/scaffold-candidate/
git commit -m "test: add scaffold-candidate fixture with a committed feature template"
```

---

### Task 3: Extend `.github/workflows/validate-fixtures.yml` with the new fixture

**Files:**
- Modify: `.github/workflows/validate-fixtures.yml`

**Interfaces:**
- Consumes: `tests/fixtures/scaffold-candidate/` (must already exist and
  build at 4.206.0, from Task 2).
- Produces: the extended regression gate described in spec §4.2.
  `scripts/validate-fixtures-locally.sh` requires no change — it reads
  this file's matrix directly.

- [ ] **Step 1: Read the current workflow file**

```bash
cat .github/workflows/validate-fixtures.yml
```

Confirm the existing `matrix.include` list and its `workspace`/
`resolve_cmd`/`test_schemes` fields, and the current `runs-on:` value
(routed to the self-hosted runner as a temporary measure — see its
inline comment) before editing.

- [ ] **Step 2: Add one entry to the matrix**

Add this entry to the `matrix.include` list, alongside the nine
existing entries:

```yaml
          - fixture: scaffold-candidate
            tuist: 4.206.0
            workspace: ScaffoldCandidate
            resolve_cmd: install
            test_schemes: App
```

- [ ] **Step 3: Verify the workflow YAML is still syntactically valid**

```bash
ruby -ryaml -e "YAML.load_file('.github/workflows/validate-fixtures.yml'); puts 'OK: YAML valid'"
```

Expected: `OK: YAML valid`.

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/validate-fixtures.yml
git commit -m "ci: validate scaffold-candidate fixture"
```

- [ ] **Step 5: Validate locally via the committed script**

```bash
./scripts/validate-fixtures-locally.sh scaffold-candidate
```

Expected: `scaffold-candidate: PASS` in the summary. This script reads
the matrix straight from the workflow file, so it picks up the new
entry automatically.

Push to `origin` is a decision made with the user once the whole plan is
done, same as prior milestones' publish step. Branch protection on
`main`/`develop` requires a PR with all fixture CI jobs green — this
plan's own local validation is a prerequisite for that, not a
substitute.

---

### Task 4: README.md, CHANGELOG.md, and plugin version updates

**Files:**
- Modify: `README.md`
- Modify: `CHANGELOG.md`
- Modify: `.claude-plugin/plugin.json`

**Interfaces:**
- Consumes: everything built in Tasks 1–3 (this task documents the
  finished v0.6 state).
- Produces: the installation/usage doc and version marker a human reads
  first.

- [ ] **Step 1: Read the current README.md, CHANGELOG.md, and plugin.json**

```bash
cat README.md
cat CHANGELOG.md
cat .claude-plugin/plugin.json
```

(Confirm current content before editing so nothing existing is silently
dropped.)

- [ ] **Step 2: Update `README.md`'s Skills section**

Add one new subsection after the existing `ios-tuist-test-target` entry,
matching the existing style exactly (heading, one paragraph, one example
prompt):

```markdown
### `ios-tuist-scaffold`

Authors one explicitly user-named `tuist scaffold` template — its
`Tuist/Templates/<name>/<name>.swift` manifest plus the `.stencil`
file(s) it references — matching a shape the user describes or points
at in existing files, and verifies it by actually running `tuist
scaffold` in a scratch location. Never runs the template against the
real project tree. Example: "Turn this LoginFeature folder into a
scaffold template named `feature`."
```

- [ ] **Step 3: Update `README.md`'s Repository layout section**

Change:
```
skills/               Bootstrap, feature, dependency, module,
                      architecture-review, CI, migration, restyle, and
                      test-target skills
```
to:
```
skills/               Bootstrap, feature, dependency, module,
                      architecture-review, CI, migration, restyle,
                      test-target, and scaffold skills
```

- [ ] **Step 4: Update `README.md`'s Fixtures and CI section**

Add one bullet after the existing ten, matching the existing style:

```markdown
- [scaffold candidate](tests/fixtures/scaffold-candidate/EXPECTATIONS.md):
  a minimal buildable project with a committed `tuist scaffold`
  template `ios-tuist-scaffold` must be able to author and run
  correctly
```

- [ ] **Step 5: Update `README.md`'s spec link**

Add a line after the existing v0.5 spec link:

```markdown
The v0.6 milestone (tuist scaffold template authoring) is specified in
the
[v0.6 design specification](docs/superpowers/specs/2026-09-20-ios-tuist-skills-v0.6-design.md).
```

- [ ] **Step 6: Add the `[0.6.0]` entry to `CHANGELOG.md`**

Replace the `## [Unreleased]` line's empty body with:

```markdown
## [Unreleased]

## [0.6.0] - 2026-09-20

### Added

- `ios-tuist-scaffold`: authors one explicitly user-named `tuist
  scaffold` template — its `Tuist/Templates/<name>/<name>.swift`
  manifest plus the `.stencil` file(s) it references — matching a shape
  the user describes or points at in existing files. Generates
  `Template.Item.file` + `.stencil` (attribute-substitution-only)
  output; never `.string`/`.directory` items or Stencil control-flow
  syntax. Verifies every authored template by actually running `tuist
  scaffold` in a scratch location, never against the real project tree.
- `scaffold-candidate` fixture: a minimal real Tuist 4.206.0 project
  with a committed `feature` scaffold template, wired into the existing
  fixture-validation CI matrix.
```

- [ ] **Step 7: Bump the plugin version and description**

In `.claude-plugin/plugin.json`, change:
```json
  "description": "Version-aware iOS engineering skills for Tuist-based projects: safe bootstrap, feature addition, dependency management, module extraction, architecture review, CI auditing, explicit version migration, folder-integration restyling, and test-target creation that detect the project's real Tuist/Xcode/Swift versions and preserve existing conventions.",
  "version": "0.5.0",
```
to:
```json
  "description": "Version-aware iOS engineering skills for Tuist-based projects: safe bootstrap, feature addition, dependency management, module extraction, architecture review, CI auditing, explicit version migration, folder-integration restyling, test-target creation, and tuist scaffold template authoring that detect the project's real Tuist/Xcode/Swift versions and preserve existing conventions.",
  "version": "0.6.0",
```

- [ ] **Step 8: Verify plugin.json is still valid JSON**

```bash
python3 -m json.tool .claude-plugin/plugin.json
```

Expected: pretty-printed JSON output, no error.

- [ ] **Step 9: Commit**

```bash
git add README.md CHANGELOG.md .claude-plugin/plugin.json
git commit -m "docs: document v0.6 scaffold skill and bump plugin version"
```

---

### Task 5: Final spec-compliance sweep

**Files:**
- No new files — this task audits the whole repo against spec §7's
  acceptance criteria and fixes any gaps found.

**Interfaces:**
- Consumes: the entire repository state after Tasks 1–4.
- Produces: nothing new by default; only produces fixes if gaps are
  found.

- [ ] **Step 1: Run the acceptance checklist from spec §7**

```bash
# ios-tuist-scaffold SKILL.md exists and starts with valid frontmatter
head -1 skills/ios-tuist-scaffold/SKILL.md | grep -q '^---$' && echo "OK: SKILL.md frontmatter" || echo "MISSING/BROKEN: SKILL.md"

# scaffold-candidate fixture has EXPECTATIONS.md documenting the manual tuist scaffold procedure
test -f tests/fixtures/scaffold-candidate/EXPECTATIONS.md && echo "OK: EXPECTATIONS.md exists" || echo "MISSING: EXPECTATIONS.md"
grep -q "tuist scaffold feature --name" tests/fixtures/scaffold-candidate/EXPECTATIONS.md && echo "OK: documents the manual scaffold run" || echo "MISSING: manual scaffold procedure"

# The committed template exists at the documented path
test -f tests/fixtures/scaffold-candidate/Tuist/Templates/feature/feature.swift && echo "OK: template manifest exists" || echo "MISSING: template manifest"
test -f tests/fixtures/scaffold-candidate/Tuist/Templates/feature/source.stencil && echo "OK: .stencil file exists" || echo "MISSING: .stencil file"

# No new shared reference file was added
test $(ls references | wc -l) -eq 5 && echo "OK: still 5 shared reference files" || echo "UNEXPECTED: reference file count changed"

# CI matrix includes scaffold-candidate
grep -q "fixture: scaffold-candidate" .github/workflows/validate-fixtures.yml && echo "OK: CI matrix entry" || echo "MISSING: CI matrix entry"

# Plugin version bumped
grep -q '"version": "0.6.0"' .claude-plugin/plugin.json && echo "OK: plugin.json version" || echo "MISSING: plugin.json version bump"

# CHANGELOG has the 0.6.0 entry
grep -q '## \[0.6.0\]' CHANGELOG.md && echo "OK: CHANGELOG 0.6.0 entry" || echo "MISSING: CHANGELOG 0.6.0 entry"

# No Template.Item.string/.directory shown as this skill's own generated output, no Stencil control-flow syntax in the skill doc
grep -n "{% for\|{% if" skills/ios-tuist-scaffold/SKILL.md && echo "UNEXPECTED: control-flow Stencil syntax found" || echo "OK: no control-flow Stencil syntax"

# The fixture's .stencil file itself is substitution-only (no control-flow syntax)
grep -n "{% for\|{% if" tests/fixtures/scaffold-candidate/Tuist/Templates/feature/source.stencil && echo "UNEXPECTED: control-flow Stencil syntax in fixture .stencil file" || echo "OK: fixture .stencil is substitution-only"

# path: never uses {{ }} syntax (Stencil renders .stencil contents, not path: itself) — skill doc and fixture manifest
grep -n 'path: "[^"]*{{' skills/ios-tuist-scaffold/SKILL.md tests/fixtures/scaffold-candidate/Tuist/Templates/feature/feature.swift && echo "UNEXPECTED: {{ }} syntax used inside a path: string" || echo "OK: no {{ }} syntax inside any path: string"
```

Expected: every check prints `OK:` — fix any gap found before
proceeding.

- [ ] **Step 2: Confirm local validation evidence**

```bash
git status --short
./scripts/validate-fixtures-locally.sh
```

Expected: clean working tree (everything from Tasks 1–4 already
committed), and every fixture in the summary — including
`scaffold-candidate` — prints `PASS`.

- [ ] **Step 3: Confirm no leftover `.gitkeep` made obsolete**

`skills/ios-tuist-scaffold/references/` stays genuinely empty in v0.6
(no skill-specific reference content beyond root `references/` was
needed) — its `.gitkeep` remains; do not remove it.

- [ ] **Step 4: Final commit (only if Step 1 found and fixed a gap)**

```bash
git add -A
git commit -m "chore: v0.6 spec-compliance sweep"
```

If Step 1 found no gaps, skip this commit — an empty sweep commit is not
required (same precedent as v0.4/v0.5 Task 5, where no gaps meant no
sweep commit was made).

---

## Post-plan note

This plan covers exactly the v0.6 milestone (spec §1, §7):
`ios-tuist-scaffold` scoped to authoring one `tuist scaffold` template
per invocation, `.file`/`.stencil`-backed with substitution-only syntax,
verified by an actual scratch-location `tuist scaffold` run. Do not push
to `origin` as part of executing this plan — pushing is a decision made
with the user once the whole plan is done and locally validated,
consistent with how prior milestones were finished. Note also that
`main`/`develop` now have branch protection requiring a pull request
with all fixture CI jobs green (set up after v0.5 shipped) — a direct
`git push` to either branch will be rejected; work on a feature branch
and let the user open/merge the PR, same as v0.5's actual delivery
path (not this plan's own Task steps, which assume local commits on
whatever branch the implementer is using).
