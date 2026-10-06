# Version Safety

Every skill that reads, generates, or modifies Tuist manifests MUST run
this procedure before writing any Tuist code, and MUST NOT assume the
latest Tuist version.

## Core rule

> Never assume the Tuist version. Establish a version context before
> touching Tuist manifests.

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

## Authority rule

The **effective project version** (from the Tool Version axis of
Evidence collection) is authoritative. The **active** version (from the
live commands) is compared against it — never substituted for it, and
never treated as a reason to change the project's pin.

If no effective project version exists (new project, nothing found), the
active version becomes the working version for this session, and the
skill must say so explicitly in its output rather than silently treating
"whatever is installed" as "the correct version."

## Mismatch handling

If the active version differs from the effective project version:

- Treat this as a **risk to report**, not a problem to silently fix.
- Do NOT upgrade the pinned version.
- Do NOT downgrade the active toolchain.
- Do NOT adapt generated manifest syntax to the active version instead of
  the effective project version — always generate for that version.
- Surface the mismatch clearly in the skill's output (see each skill's
  Output Contract) so the human can decide what to do.
- The only exception: an explicit, user-requested Tuist migration
  workflow (out of scope for `bootstrap`/`feature`/`dependency` — see PRD
  §26). No skill in this repository silently upgrades Tuist.

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

## The Tuist Context block

Before generating or modifying any manifest, establish and state this
context:

```text
Tuist Context
-------------
Project Tuist:         <effective project version, or "none detected">
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
