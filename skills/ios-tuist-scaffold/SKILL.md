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
