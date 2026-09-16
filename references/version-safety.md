# Version Safety

Every skill that reads, generates, or modifies Tuist manifests MUST run
this procedure before writing any Tuist code, and MUST NOT assume the
latest Tuist version.

## Core rule

> Never assume the Tuist version. Establish a version context before
> touching Tuist manifests.

## Detection order

Inspect these sources, in this order, stopping as soon as a pinned
project version is found. Earlier sources win.

1. `mise.toml` / `.mise.toml`
2. `.tool-versions`
3. `Tuist.swift` (its `Tuist` configuration may declare a compatible
   version range)
4. `Tuist/Package.swift`
5. `Package.swift`
6. CI workflow files (e.g. `.github/workflows/*.yml`) that pin or install
   a specific Tuist version
7. Repository scripts (`Scripts/`, `Makefile`, `Brewfile`, bootstrap
   scripts) that install or reference a specific Tuist version
8. Existing manifest syntax (if the syntax used is only valid for a
   version range, that range is evidence)

If none of the above yields a pinned version, there is no project-pinned
version — record that explicitly rather than silently defaulting to
"latest."

Then, always, run the live commands to determine what's actually
available:

- `tuist version`
- `xcodebuild -version`
- `swift --version`

## Authority rule

The **project-pinned** version (found via steps 1–8 above) is
authoritative. The **active** version (from the live commands) is
compared against it — never substituted for it, and never treated as a
reason to change the project's pin.

If no project-pinned version exists (new project, nothing found), the
active version becomes the working version for this session, and the
skill must say so explicitly in its output rather than silently treating
"whatever is installed" as "the correct version."

## Mismatch handling

If the active version differs from the project-pinned version:

- Treat this as a **risk to report**, not a problem to silently fix.
- Do NOT upgrade the pinned version.
- Do NOT downgrade the active toolchain.
- Do NOT adapt generated manifest syntax to the active version instead of
  the pinned version — always generate for the **pinned** version.
- Surface the mismatch clearly in the skill's output (see each skill's
  Output Contract) so the human can decide what to do.
- The only exception: an explicit, user-requested Tuist migration
  workflow (out of scope for `bootstrap`/`feature`/`dependency` — see PRD
  §26). No skill in this repository silently upgrades Tuist.

## The Tuist Context block

Before generating or modifying any manifest, establish and state this
context:

```text
Tuist Context
-------------
Project Tuist:         <pinned version, or "none detected">
Active Tuist:          <version from `tuist version`>
Xcode:                 <version from `xcodebuild -version`>
Swift:                 <version from `swift --version`>
Platform:              <iOS / macOS / multiplatform, from manifests>
Deployment Target:     <from existing manifests, or user-specified for new projects>
Manifest Style:        <e.g. Target.target(...), sources/resources arrays, buildableFolders>
Folder Integration:    <sources/resources | buildableFolders>
Dependency Integration:<Tuist Package.swift | Xcode-native SwiftPM>
Architecture:          <minimal | feature-modular | clean | tca | custom>
```

Every field must come from actual inspection (file contents, command
output), never assumed. If a field cannot be determined, write
"unknown" — do not guess.

## Why this matters

Tuist's `ProjectDescription` API, manifest syntax, dependency
integration, and generated-project behavior all change across releases.
Generating code for the wrong version produces manifests that fail to
evaluate or produce a broken project graph. This procedure exists so
every skill in this repository fails safe (reports risk) instead of
failing silent (guesses and moves on).
