# scaffold-candidate

## Starting state

- Pinned Tuist version: **4.206.0** (matches this repository's other
  fixtures).
- Two targets (`App` and `AppTests`) — the minimal app plus smoke-test
  shape used by the fixture CI matrix to exercise generate, build, and
  test.
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
  `Tuist/Templates/feature/` directory present; `xcodebuild build` and
  `xcodebuild test` for scheme `App` succeed.

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
3. `xcodebuild test -workspace ScaffoldCandidate.xcworkspace -scheme
   App -destination 'id=<available-simulator-udid>'` succeeds.
4. In a **scratch** copy of this directory (never the committed tree):
   `mise exec tuist@4.206.0 -- tuist scaffold feature --name Sample`
   succeeds and produces `Sources/SampleLabel.swift` containing:
   ```swift
   public enum SampleLabel {
       public static let text = "Sample"
   }
   ```
5. The generated file parses as valid Swift
   (`swiftc -parse Sources/SampleLabel.swift`).
6. The scratch copy is deleted after verification; nothing from step 4
   is committed.

CI (`validate-fixtures.yml`) only proves step 1–3's baseline state is
real and buildable at 4.206.0 with the template files present — step
4–6's actual `tuist scaffold` run is `ios-tuist-scaffold`'s own
Validation step, exercised when the skill runs, per the v0.6 spec §4.2.
