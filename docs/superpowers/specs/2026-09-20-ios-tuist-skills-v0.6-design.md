# ios-tuist-skills v0.6 — Design Spec

- **Status:** Approved for planning
- **Date:** 2026-09-20
- **Source:** Defined in-conversation (no external PRD). User asked
  about three possible directions (a docs-Q&A skill, a "show me an
  official Tuist example when bootstrapping" skill, and a Stencil
  scaffold-template-authoring skill); only the third was judged to have
  a scope distinct enough from existing skills and existing tool access
  (Context7) to justify a new skill.
- **Scope:** One new skill — `ios-tuist-scaffold` — scoped to
  **authoring one explicitly user-named `tuist scaffold` template**
  (its `Tuist/Templates/<name>/<name>.swift` manifest plus the
  `.stencil` file(s) it references) and verifying it by actually
  running `tuist scaffold` in a scratch location.
- **Planning/review owner:** Claude

## 0. Why not the other two ideas

The user's request named three possible skills. Two were considered and
explicitly rejected for v0.6:

1. **"Answer Tuist questions from the docs, with examples and links."**
   Not built as a skill. This session already has Context7 MCP tool
   access (`mcp__plugin_context7_context7__query-docs` /
   `resolve-library-id`) wired in, which queries Tuist's real,
   current documentation on demand — the same source a dedicated
   "docs Q&A" skill would have to re-implement. A `SKILL.md` here would
   at best be a thin instruction to "use Context7 and cite it," which
   duplicates this repo's existing repo-wide fact-verification
   discipline (every skill already must confirm real API shapes before
   generating manifest code — see `references/version-safety.md`) without
   adding new behavior. Trigger conditions for "someone is asking a
   question" also overlap heavily with normal conversation, unlike
   every other skill in this repository, which triggers on a concrete
   file-changing task.
2. **"When bootstrapping a new project, show an official Tuist example."**
   This is a workflow addition to `ios-tuist-bootstrap`, not a new
   skill — `ios-tuist-bootstrap` already owns "create a new Tuist
   project," and pointing at `tuist/tuist`'s own `Examples/` directory
   as a reference during that workflow is a same-skill enhancement, not
   a new capability with its own trigger/non-trigger boundary. Out of
   scope for v0.6; revisit as a small follow-up edit to
   `ios-tuist-bootstrap`'s Workflow section if the user wants it, not as
   its own milestone.

The third idea — authoring `tuist scaffold` templates — has neither of
these problems: it is a concrete, file-producing operation
(`Tuist/Templates/`, `.stencil` files) that no existing skill touches,
with a clear trigger ("make a template for X") distinct from every
other skill's trigger.

## 1. Purpose

Tuist ships a template system (`tuist scaffold`) for generating
boilerplate files/directories from a named template — a `Template.swift`
manifest plus optional `.stencil` files it renders. `ios-tuist-feature`
already references this mechanism (its Workflow step 1 asks "does a
Tuist scaffold/template already exist for features in this repo?") but
only *consumes* an existing template; nothing in this repository creates
one. A user who has hand-written the same feature-module shape three
times, and now wants that shape captured as a reusable `tuist scaffold`
template, has no skill to help — they would have to write
`Template.swift` and `.stencil` files from memory or by copying Tuist's
own docs by hand.

v0.6 closes that gap: `ios-tuist-scaffold` authors one new, explicitly
user-named scaffold template — the manifest and its `.stencil` file(s) —
matching a shape the user describes or that already exists as
hand-written files in the project, and proves it works by actually
running `tuist scaffold <name> --name <value>` in a scratch location and
inspecting (and, for Swift output, compiling) what comes out.

This is a different axis from every existing skill:

- `ios-tuist-feature` *consumes* an existing scaffold template to add a
  feature; it never authors one. When `ios-tuist-feature`'s "no
  existing scaffold, but this is the Nth repetition" branch fires, it
  states that creating a scaffold "may be justified" but does not
  create it — that is this skill, on explicit request.
- `ios-tuist-module` extracts existing code into a new non-test
  *target*; it does not produce a reusable *template* for generating
  future targets.
- `ios-tuist-test-target` creates one concrete test target in
  `Project.swift`; it does not produce a `tuist scaffold` template for
  generating test targets repeatedly.
- No skill touches `Tuist/Templates/` or `.stencil` files at all today.

Explicitly out of scope for v0.6 (deferred or never): authoring more
than one template per invocation; a project-wide "templatize
everything" sweep; using a template once it's created (that remains a
plain `tuist scaffold` invocation, or `ios-tuist-feature`'s existing
"reuse the scaffold" branch); `Template.Item.string` or
`Template.Item.directory` as first-class generation targets (see §3.4 —
`.stencil`-backed `.file` items are this skill's focus); resource
accessor template plugins (`Plugin.swift` + `ResourceSynthesizers/` for
Strings/Assets/Plists) — a related but distinct Tuist feature with a
different manifest shape and trigger, not covered here.

## 2. Repository layout additions

```text
ios-tuist-skills/
├── skills/
│   └── ios-tuist-scaffold/
│       └── SKILL.md
├── tests/fixtures/
│   └── scaffold-candidate/     # ios-tuist-scaffold
```

No new shared reference file — `ios-tuist-scaffold` reads
`references/source-of-truth.md` (existing conventions win: an
already-hand-written feature shape is the source of truth for what the
template should produce) and `references/version-safety.md`. It does
not need `references/testing.md` (it does not create test targets) or
`references/dependencies.md` (a template manifest declares no
`ProjectDescription` target dependencies).

## 3. `ios-tuist-scaffold`

**Purpose:** Author one new, explicitly user-named `tuist scaffold`
template — its `Tuist/Templates/<name>/<name>.swift` manifest plus the
`.stencil` file(s) it references — matching a file/content shape the
user describes or that already exists as hand-written files elsewhere
in the project, and verify it by actually generating output with `tuist
scaffold` in a scratch location.

**Trigger conditions:** "Make a scaffold template for creating new
features", "Turn this LoginFeature folder into a `tuist scaffold`
template named `feature`", "Add a template so `tuist scaffold
viewmodel --name X` generates a ViewModel + its test file." The request
must name (or unambiguously imply) one specific template name and
describe or point at one concrete file/content shape to generate.

**Non-trigger conditions:**

- The request names no template shape at all ("set up scaffolding for
  this project") — out of scope for this pass; ask what the template
  should generate rather than inventing a shape.
- The request asks to *use* an existing template to generate actual
  project files right now — that's a plain `tuist scaffold` invocation
  (or `ios-tuist-feature`'s existing "reuse the scaffold" branch when a
  new feature is being added); this skill only authors templates, it
  does not run them against the real project tree.
- The request is to add real feature code/targets directly to
  `Project.swift` — that's `ios-tuist-feature`.
- The request is to extract existing code into a new build target
  (`.framework`, `.staticFramework`, etc.) — that's `ios-tuist-module`.
- The request is to create a resource-accessor-synthesis template
  (`Plugin.swift` + `ResourceSynthesizers/Strings.stencil` etc. for
  `tuist generate`'s resource synthesis) — a distinct Tuist mechanism
  with a different manifest shape and trigger; out of scope for this
  skill.
- No existing Tuist project, or the project has no `Tuist/` directory to
  place `Templates/` under (bootstrap first — that's
  `ios-tuist-bootstrap`).

**Preconditions:** An existing Tuist project is present and readable;
one specific template name is given or unambiguous; the shape to
generate is either described explicitly by the user or points at
concrete existing files in the project to model the template on.

**Version Safety:** Full
[version-safety](../../references/version-safety.md) procedure,
Existing Project Mode. `Template`/`Template.Item`/`Template.Attribute`
are long-stable `ProjectDescription` API (verified against the current
API surface — see §3.1); still confirm the pinned version so generated
manifest syntax is one the pinned version actually accepts, per the
repo-wide rule.

**Workflow:**

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
   `Template.Attribute.required(_:)` or `.optional(_:default:)` (see
   §3.1); every other value is fixed template content.
3. **Write the `.stencil` file(s)** under
   `Tuist/Templates/<name>/` (or a subdirectory referenced by
   `templatePath`, matching the project's own layout preference if one
   is already established) — plain file content with `{{ attributeName
   }}` substitutions only (see §3.3 for the syntax boundary this skill
   stays inside).
4. **Write the template manifest** at
   `Tuist/Templates/<name>/<name>.swift`:
   - `Template(description:attributes:items:)`.
   - One `Template.Item.file(path:templatePath:)` per `.stencil` file
     (see §3.4 for why this skill's generated items are `.file`-only).
   - `description` states in plain language what the template produces,
     for `tuist scaffold`'s own `--help` output.
5. **Validate (§3.5)** — run `tuist scaffold <name> --name <value>` (and
   any other required attributes) in a scratch location; inspect the
   generated file(s) for correct attribute substitution; if the
   generated output is Swift, confirm it is syntactically valid /
   compiles standalone; clean up the scratch location afterward. No
   files are generated inside the real project tree by this skill
   itself — only the template definition is committed.

### 3.1 Verified `Template` API surface

`ProjectDescription`'s template API (verified against Tuist's current
documented surface, not assumed from memory):

- `Template(description: String, attributes: [Template.Attribute] = [],
  items: [Template.Item] = [])`.
- `Template.Attribute.required(_ name: String)` and
  `.optional(_ name: String, default: <string literal>)` (e.g.
  `.optional("platform", default: "ios")`, per Tuist's own documented
  example) — an attribute referenced in `.stencil` files as `{{ name
  }}`, and, if referenced directly inside the manifest's own
  `Template.Item.string(contents:)`, via ordinary Swift string
  interpolation of the attribute value (a mechanism this skill does not
  generate — see §3.4).
- `Template.Item.file(path: String, templatePath: Path)` — renders the
  `.stencil` file at `templatePath` through Stencil and writes the
  result to `path` relative to the invocation directory.
- `Template.Item.string(path: String, contents: String)` and
  `Template.Item.directory(path: String, sourcePath: Path)` also exist,
  but are not this skill's generated output — see §3.4.
- Manifest location convention: `Tuist/Templates/<name>/<name>.swift`
  (e.g. a template named `feature` lives at
  `Tuist/Templates/feature/feature.swift`) — this is a directory-naming
  convention Tuist discovers, not a `ProjectDescription` type.
- Invocation: `tuist scaffold <name> --<attribute> <value>` for each
  required attribute; optional attributes may be omitted to use their
  default.

### 3.2 Confirm the shape before generating, not after

When modeling a template on existing hand-written files (the common
case — a project that has already hand-written the same feature/module
shape more than once), read those files fully before writing the
`.stencil` equivalents. Silently guessing at what varies versus what's
fixed produces a template that generates subtly wrong output the first
time someone actually uses it; confirm the attribute list with the user
before writing files when the boilerplate/variable boundary is
ambiguous (e.g. a hardcoded string that might be meant to vary per
target, or might genuinely be fixed across every use of this template).

### 3.3 Stencil syntax boundary: substitution only

This skill's `.stencil` files use only attribute substitution
(`{{ attributeName }}`) — the syntax Tuist's own template-authoring
documentation demonstrates and this repository has verified. Stencil's
broader templating-language features (`{% for %}` loops, `{% if %}`
conditionals, filters, etc.) are conventional Stencil syntax but are
**not independently verified against Tuist's specific Stencil
integration** in this spec, and are out of scope for what this skill
generates: every `.stencil` file this skill writes must be a
straight-line file with attribute substitutions only, never a
control-flow template. This keeps every claim this skill makes about
"what the template will produce" backed by verified, tested behavior
rather than assumed Stencil-engine behavior. If a user's request
requires conditional or repeated content, state that this skill's
verified scope is substitution-only and the more complex template would
need to be authored (and tested) by hand.

### 3.4 Why `.file` (`.stencil`), not `.string` or `.directory`

`Template.Item` has three cases (§3.1), but this skill only ever
generates `.file(path:templatePath:)` items backed by a `.stencil` file:

- `.string(path:contents:)` embeds file content as a literal Swift
  string directly in the manifest, using Swift string interpolation
  (not Stencil substitution) for dynamic parts. It works for
  single-line or trivial content but produces an unreadable,
  hard-to-maintain manifest for anything resembling a real source file,
  and mixes two different substitution mechanisms (Swift interpolation
  in the manifest vs. Stencil in `.stencil` files) in one template,
  which this skill avoids for consistency.
- `.directory(path:sourcePath:)` copies an existing directory verbatim,
  with no substitution at all — useful for copying fixed assets, but it
  cannot parameterize a name or value anywhere in the copied content,
  which defeats the purpose of a request like "make a template for
  creating new features" where the feature name must vary.
- `.file(path:templatePath:)` with a `.stencil` file is the only one of
  the three that both (a) keeps generated-file content in its own
  readable file rather than a Swift string literal, and (b) supports
  per-invocation attribute substitution. This matches the shape of
  every trigger example in §"Trigger conditions" above (a name must
  vary per use).

If a user's request is better served by `.string` or `.directory` (e.g.
copying a fixed set of non-templated fixture assets with no
substitution needed), state that explicitly and explain why `.file`
isn't the right fit, rather than forcing a `.stencil` file that has
nothing to substitute.

### 3.5 Validation is a real `tuist scaffold` run, not a manifest read-through

Per this repository's standing validation bar (every skill's Output
Contract requires evidence, not "files look right" — see
`ios-tuist-test-target`'s and `ios-tuist-restyle`'s Validation
sections), authoring a template manifest and its `.stencil` files is not
sufficient on its own:

1. Copy (or `cd` into, if already inside the real project checkout) the
   project to a scratch location, or use a scratch subdirectory that is
   not part of the committed project tree.
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
  ambiguous (§3.2) — confirm with the user before writing files.
- Never write a `.stencil` file using Stencil control-flow syntax
  (`{% for %}` / `{% if %}` / filters) — substitution-only, per §3.3.
- Never generate `Template.Item.string` or `.directory` items as this
  skill's own output — `.file` + `.stencil` only, per §3.4, unless
  explicitly stated why a specific request doesn't fit that shape.
- Never run `tuist scaffold` against the real project tree as part of
  "validating" a template — validation happens in a scratch location
  only (§3.5); the only files this skill commits are the template
  definition itself.
- Never create a resource-accessor-synthesis template
  (`Plugin.swift`/`ResourceSynthesizers/`) under this skill — a distinct
  mechanism, out of scope (see Non-Trigger Conditions).
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
- Generated Sources/SampleViewModel.swift: {{ name }} substitutions
  resolved correctly ("Sample" appears where expected)
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

## 4. Fixtures and CI validation

### 4.1 `tests/fixtures/scaffold-candidate/`

A real, buildable Tuist project, pinned at Tuist 4.206.0, with:

- A minimal `App` target (same minimal shape as other fixtures) so the
  fixture is independently generatable/buildable — proving the
  project's baseline state is real, same as every other fixture in this
  repository.
- One committed template at `Tuist/Templates/feature/feature.swift` +
  `Tuist/Templates/feature/source.stencil`, authored the way this skill
  is expected to author one: a `required("name")` attribute, one
  `.file` item rendering a simple Swift source file with a `{{ name }}`
  substitution.

### 4.2 CI (self-hosted validation matrix)

Extend the fixture-validation matrix with one more entry:
`scaffold-candidate`, pinned at Tuist 4.206.0. CI validates only that
the fixture's baseline `App` project still resolves/generates/builds/
tests with the template files present alongside it (a `Tuist/Templates/`
directory must never break `tuist generate` for the rest of the
project) — it does **not** run `tuist scaffold` itself, since scaffold
output is written outside the generated Xcode project and isn't
something `xcodebuild` exercises. The actual `tuist scaffold` run and
generated-file inspection (§3.5) is this skill's own Validation step,
exercised when the skill runs, and is documented as a manual procedure
in the fixture's `EXPECTATIONS.md` — same pattern as every prior
milestone's fixture (e.g. `test-target-candidate`'s probe-conversion
cycle).

`scripts/validate-fixtures-locally.sh` picks up the new matrix entry
automatically, same as before.

## 5. CHANGELOG.md and plugin version

- `.claude-plugin/plugin.json` `version` bumps to `0.6.0`; `description`
  gains a mention of scaffold-template authoring alongside the existing
  nine capabilities.
- `CHANGELOG.md` gets a `[0.6.0]` entry listing `ios-tuist-scaffold` and
  the `scaffold-candidate` fixture, following the same Keep-a-Changelog
  style as prior entries.
- `README.md`'s skills list gains an `ios-tuist-scaffold` entry
  alongside the existing nine.

## 6. Explicit non-goals (v0.6)

- No authoring of more than one template per invocation.
- No project-wide "templatize everything" sweep.
- No use of a template once authored — that's a plain `tuist scaffold`
  invocation or `ios-tuist-feature`'s existing reuse branch, not this
  skill.
- No `Template.Item.string` or `.directory` generation as this skill's
  own output (§3.4), except with an explicit stated reason a specific
  request doesn't fit `.file`/`.stencil`.
- No Stencil control-flow syntax (`{% for %}`/`{% if %}`/filters) in
  generated `.stencil` files (§3.3) — substitution-only.
- No resource-accessor-synthesis template authoring
  (`Plugin.swift`/`ResourceSynthesizers/`) — a distinct Tuist mechanism,
  deferred to a possible future milestone if ever requested.
- No running `tuist scaffold` against the real project tree — scratch
  location only (§3.5).
- Same restated non-goals as prior milestones continue to apply
  repo-wide (no silent version changes, no forced architecture, no
  side-effect modernization, no changes to targets other than what the
  template authorship itself requires).

## 7. Acceptance criteria for this v0.6 implementation pass

- `ios-tuist-scaffold` exists with a complete `SKILL.md` following the
  same section structure as the other nine skills (Purpose, Trigger
  Conditions, Non-Trigger Conditions, Preconditions, Version Safety,
  Workflow, Decision Rules, Validation, Failure Handling, Output
  Contract).
- `tests/fixtures/scaffold-candidate/` exists as a real, independently
  buildable Tuist project pinned at Tuist 4.206.0, with a minimal `App`
  target and one committed `feature` scaffold template
  (`Tuist/Templates/feature/feature.swift` +
  `Tuist/Templates/feature/source.stencil`) — plus an `EXPECTATIONS.md`
  documenting the manual `tuist scaffold` verification procedure.
- The fixture-validation workflow is extended to resolve/generate/
  build/test the new fixture's baseline project (not the scaffold
  output) at its pinned version alongside the existing nine.
- `.claude-plugin/plugin.json` version is `0.6.0` and its description
  mentions scaffold-template authoring.
- `README.md` lists `ios-tuist-scaffold` alongside the existing nine
  skills.
- `CHANGELOG.md` has a `[0.6.0]` entry.
