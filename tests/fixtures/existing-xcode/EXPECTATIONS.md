# Fixture: existing-xcode

**Manual scenario only:** NOT in the CI matrix and NOT added to
`validate-fixtures.yml` or `ci-matrix.json`. No `.tool-versions` is
required.

**Exercises:** `ios-tuist-bootstrap` (v0.8 WS5 refusal)

## Starting state

Use a separate target directory containing an empty `Foo.xcodeproj/`
directory. No `Project.swift`, `Tuist.swift`, or `Workspace.swift` exists
there. The empty project directory is described here rather than tracked;
do not add placeholder files.

Also exercise a target whose child directory contains the unrelated empty
`Foo.xcodeproj/`: the target itself has no project files, but a directory
one level below it contains an Xcode project. Repeat both layouts with an
empty `Foo.xcworkspace/` instead.

## Prompt to exercise this fixture

> Create a new iOS app using Tuist here.

## Expected behavior

- The skill checks the target path and every directory one level below
  it before writing any files.
- It stops, reports the discovered Xcode project or workspace and its
  path, and names the official Tuist `migrate` skill for Xcode→Tuist
  conversion.
- It creates no files.
- As a control, a separate empty target directory with no Tuist manifests,
  `*.xcodeproj`, or `*.xcworkspace` is not refused by this precondition.

## What must NOT happen

- Any `Project.swift`, `Tuist.swift`, `Workspace.swift`, source file, or
  other generated file is written in a refusal scenario.
- An unrelated project one level below the target is ignored.
- A genuinely empty target directory is refused by this precondition.

## How to check

1. Prepare each starting-state layout in a separate temporary directory
   and run the prompt with that directory as the target.
2. Read the report: it must name the discovered path, state that bootstrap
   stopped, and point to the official Tuist `migrate` skill.
3. Compare the directory contents before and after: no file is created
   or changed.
4. Run the empty-directory control and confirm this precondition permits
   bootstrap to continue.
