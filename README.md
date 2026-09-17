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

When invoking skills explicitly, Claude Code namespaces them with the plugin
name, for example `/ios-tuist-skills:ios-tuist-bootstrap`.

## Repository layout

```text
.claude-plugin/       Plugin manifest
skills/               Bootstrap, feature, and dependency skills
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

CI proves the committed fixture projects remain buildable. The expectation
documents define the separate manual checks for a skill's behavior when it is
run against each scenario.

## Non-goals

This plugin does not replace Tuist's official documentation, skills, MCP, or
CLI. It does not maintain a hard-coded compatibility table, automatically
upgrade Tuist, modernize unrelated manifests, redesign an existing
architecture, or force a single linkage, modularization, dependency, UI, or
test strategy.

The complete scope and design decisions are in the
[v0.1 design specification](docs/superpowers/specs/2026-09-17-ios-tuist-skills-v0.1-design.md).
