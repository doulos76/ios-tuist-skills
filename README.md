# ios-tuist-skills

`ios-tuist-skills` is a Claude Code plugin for safe, version-aware work on
Tuist-based iOS projects. Its skills inspect the project's real Tuist, Xcode,
and Swift context; preserve established repository conventions; generate
compatible manifests; and verify meaningful changes with generate, build, and
test commands instead of silently assuming the latest syntax.

## Load the plugin

Clone this repository, then load it directly for local use or development:

```sh
claude --plugin-dir /path/to/ios-tuist-skills
```

Claude Code discovers the plugin through
[`.claude-plugin/plugin.json`](.claude-plugin/plugin.json). Direct loading is
session-scoped; run `/reload-plugins` after editing the plugin. For persistent
team distribution, publish it through a Claude Code plugin marketplace and use
`/plugin install`. See the official
[Claude Code plugin documentation](https://code.claude.com/docs/en/plugins)
for the current marketplace flow.

## Skills

### `ios-tuist-bootstrap`

Creates a new Tuist iOS project from one of the repository's architecture
templates after inspecting the active toolchain. Example: “Create a new
SwiftUI iOS app using Tuist with a feature-modular structure.”

### `ios-tuist-feature`

Adds a feature to an existing Tuist project while preserving its manifest,
folder-integration, architecture, dependency, and testing conventions.
Example: “Add LoginFeature to this project.”

### `ios-tuist-dependency`

Adds, removes, or relocates a package, binary, framework, or local dependency
at the narrowest target that actually consumes it. Example: “Add Kingfisher
only to ProfileFeature.”

### `ios-tuist-module`

Extracts existing code from a target into a new module, applying the
modularization justification checklist before acting — refusing the
extraction and reporting why when the checklist isn't concretely met.
Example: "Extract the networking code into its own module called
NetworkingKit."

### `ios-tuist-architecture-review`

Diagnoses an existing project's target graph, dependency direction, and
linkage choices, and reports findings with concrete evidence — makes no
code changes. Example: "Review this project's architecture."

### `ios-tuist-ci`

Audits an existing CI workflow for a Tuist project — version-pin
consistency, caching, redundant steps, parallelization — and applies
improvements the user approves. Example: "Check our CI workflow for
efficiency."

### `ios-tuist-migrate`

Moves a project's pinned Tuist version forward to a user-specified
target version, updating version-pin sources and the minimum manifest
syntax the target version actually requires — the only skill in this
repository permitted to change a project's Tuist version pin, and only
on explicit request. Example: "Migrate this project from Tuist 3 to
Tuist 4."

### `ios-tuist-restyle`

Converts explicitly user-named targets' folder integration from
array-based sources/resources declarations to buildableFolders, gated by
a per-target safety checklist — refuses any named target where an
exclusion pattern, cross-target file reference, or other real risk would
be silently lost. Example: "Convert FeatureA to buildableFolders."

### `ios-tuist-test-target`

Creates a new unit, integration, or UI test target for one explicitly
user-named existing target, following the project's own testing and
naming conventions, and enrolls the new target in the relevant scheme's
test action. Refuses when a test target of the requested kind already
exists. Generates a single labeled placeholder test only — never real
coverage. Example: "Add a unit test target for FeatureA."

### `ios-tuist-scaffold`

Authors one explicitly user-named `tuist scaffold` template — its
`Tuist/Templates/<name>/<name>.swift` manifest plus the `.stencil`
file(s) it references — matching a shape the user describes or points
at in existing files, and verifies it by actually running `tuist
scaffold` in a scratch location. Never runs the template against the
real project tree. Example: "Turn this LoginFeature folder into a
scaffold template named `feature`."

When invoking skills explicitly, Claude Code namespaces them with the plugin
name, for example `/ios-tuist-skills:ios-tuist-bootstrap`.

## Repository layout

```text
.claude-plugin/       Plugin manifest
skills/               Bootstrap, feature, dependency, module,
                      architecture-review, CI, migration, restyle,
                      test-target, and scaffold skills
references/           Shared version and engineering decision procedures
templates/            Minimal, feature-modular, and clean scaffolds
examples/             Worked minimal and modular projects
tests/fixtures/       Version- and convention-sensitive test projects
.github/workflows/    Fixture generation, build, and test validation
```

## Fixtures and CI

The macOS workflow installs each fixture's pinned Tuist version, generates the
workspace, builds it, and runs its tests. The fixtures cover:

- [new project](tests/fixtures/new-project/EXPECTATIONS.md): human-in-the-loop
  bootstrap behavior from an empty directory
- [legacy conventions](tests/fixtures/legacy-tuist/EXPECTATIONS.md): preserving
  array-based source and resource declarations
- [version mismatch](tests/fixtures/version-mismatch/EXPECTATIONS.md): reporting
  a real project-pin/active-tool mismatch without silently changing either
- [modular graph](tests/fixtures/modular/EXPECTATIONS.md): attaching a
  dependency only to its intended feature target
- [extract candidate](tests/fixtures/extract-candidate/EXPECTATIONS.md):
  proving both the extraction-proceeds and extraction-refused paths of
  `ios-tuist-module`
- [architecture smells](tests/fixtures/architecture-smells/EXPECTATIONS.md):
  a source-level coupling smell `ios-tuist-architecture-review` must
  name with concrete evidence, without editing anything
- [CI gaps](tests/fixtures/ci-gaps/EXPECTATIONS.md): a redundant,
  uncached embedded workflow `ios-tuist-ci` must find and improve
- [migrate candidate](tests/fixtures/migrate-candidate/EXPECTATIONS.md):
  a real Tuist 3.42.2 project with a genuine breaking-change surface
  `ios-tuist-migrate` must detect and fix moving to Tuist 4.206.0
- [restyle candidate](tests/fixtures/restyle-candidate/EXPECTATIONS.md):
  a checklist-clear target and a checklist-failing target (real
  exclusion pattern) `ios-tuist-restyle` must tell apart correctly
- [test-target candidate](tests/fixtures/test-target-candidate/EXPECTATIONS.md):
  a target that already has a unit test target and a target that
  doesn't, plus a custom scheme `ios-tuist-test-target` must enroll the
  new target into correctly
- [scaffold candidate](tests/fixtures/scaffold-candidate/EXPECTATIONS.md):
  a minimal buildable project with a committed `tuist scaffold`
  template `ios-tuist-scaffold` must be able to author and run
  correctly

CI proves the committed fixture projects remain buildable. The expectation
documents define the separate manual checks for a skill's behavior when it is
run against each scenario. Workflow runs use GitHub-hosted `macos-15` runners.

## Skill effectiveness benchmark

A baseline-vs-with-skill comparison across all 14 fixture scenarios — real
`tuist generate`/build/test verification and independent rubric scoring, not
just fixture CI — lives in
[`docs/superpowers/benchmarks/2026-09-20-skill-effectiveness/`](docs/superpowers/benchmarks/2026-09-20-skill-effectiveness/AGGREGATE-SUMMARY.md).
It also documents a real methodology finding about baseline isolation inside
this repository, worth reading before re-running or extending the benchmark.

## Non-goals

This plugin does not replace Tuist's official documentation, skills, MCP, or
CLI. It does not maintain a hard-coded compatibility table, automatically
upgrade Tuist, modernize unrelated manifests, redesign an existing
architecture, or force a single linkage, modularization, dependency, UI, or
test strategy.

The complete scope and design decisions are in the
[v0.1 design specification](docs/superpowers/specs/2026-09-17-ios-tuist-skills-v0.1-design.md).

The v0.2 milestone (module extraction, architecture review, and CI
auditing) is specified in the
[v0.2 design specification](docs/superpowers/specs/2026-09-17-ios-tuist-skills-v0.2-design.md).

The v0.3 milestone (Tuist version migration) is specified in the
[v0.3 design specification](docs/superpowers/specs/2026-09-18-ios-tuist-skills-v0.3-design.md).

The v0.4 milestone (folder-integration restyle to buildableFolders) is
specified in the
[v0.4 design specification](docs/superpowers/specs/2026-09-19-ios-tuist-skills-v0.4-design.md).

The v0.5 milestone (test-target creation and scheme enrollment) is
specified in the
[v0.5 design specification](docs/superpowers/specs/2026-09-20-ios-tuist-skills-v0.5-design.md).

The v0.6 milestone (tuist scaffold template authoring) is specified in
the
[v0.6 design specification](docs/superpowers/specs/2026-09-20-ios-tuist-skills-v0.6-design.md).
