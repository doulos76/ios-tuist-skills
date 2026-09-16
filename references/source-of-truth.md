# Source of Truth Precedence

When two sources of guidance conflict, resolve using this order. A
lower-priority source must never override a higher-priority source
without explicit, stated justification in the skill's output.

1. Project-pinned Tuist version
2. Existing repository manifests and conventions
3. Version-compatible Tuist documentation / `ProjectDescription` reference
4. Tuist migration and release notes relevant to the detected version
5. Active Xcode and Swift versions
6. Project deployment target and platform constraints
7. Existing project architecture
8. Apple platform guidance
9. Swift / Swift Package Manager guidance
10. This skill repository's reference material (`references/*.md`,
    `templates/`)

`references/*.md` in this repository is deliberately last: it encodes
stable principles, not authoritative facts about any specific project.
When this repository's guidance and the actual project disagree, the
project wins.

## New Project Mode vs Existing Project Mode

Determine which mode applies before making any structural decision.

```text
Does a Tuist project already exist at the target path?
    |
    +-- Yes -> Existing Project Mode
    |
    +-- No  -> New Project Mode
```

### Existing Project Mode

> Existing conventions are more authoritative than generic best practices
> unless the user explicitly requests a migration or architectural change.

Before generating anything:

1. Inspect neighboring manifests.
2. Inspect module/folder layout.
3. Inspect test layout and framework (XCTest vs Swift Testing).
4. Inspect dependency conventions (Tuist-native `Package.swift` vs
   Xcode-native SwiftPM integration).
5. Inspect folder integration strategy (`sources`/`resources` arrays vs
   `buildableFolders`).
6. Reuse existing `ProjectDescriptionHelpers` where they already cover the
   need.
7. Minimize graph changes — the smallest change that accomplishes the
   task wins over a "more correct" larger change.

Example: if the project uses `sources: ["Sources/**"]` throughout, do not
introduce `buildableFolders` into one new feature. That is a migration,
and migrations are only performed when explicitly requested.

### New Project Mode

For a genuinely new repository (no existing Tuist project), current
supported practice may be preferred as the default, subject to the
version actually detected in [version-safety](version-safety.md):

- Minimal `Project.swift`.
- `Tuist.swift` only where global configuration is actually needed.
- No `Workspace.swift` unless justified (see below).
- Buildable Folders on toolchains that support them; `sources`/
  `resources` arrays when compatibility requires it.
- Swift Testing for new unit/integration tests when compatible with the
  detected Swift version; XCTest for UI tests.
- Explicit dependencies, scoped to the narrowest target.

## Workspace.swift decision rule

```text
Need custom workspace behavior (custom composition, custom schemes,
explicit multi-project organization not handled by default generation)?
    |
    +-- No  -> omit Workspace.swift
    |
    +-- Yes -> create Workspace.swift, and state the justification
```

## Configuration file rule

Never generate `Config.swift` as a default. Use `Tuist.swift` for
project-wide Tuist configuration. Do not create either file based solely
on an old example found in documentation or training data — verify
against the detected project version first.
