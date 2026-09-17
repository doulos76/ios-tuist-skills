# Minimal template

A single SwiftUI application target (`App`) and its Swift Testing target
(`AppTests`). The manifest uses Buildable Folders and does not create a
custom workspace because a single-project app does not require one.

This template was authored and verified with Tuist `4.206.0`. The version
is provenance for maintainers, not a consumer pin; the
`ios-tuist-bootstrap` skill must establish the consumer's Tuist Context
before adapting or copying this structure.

`ios-tuist-bootstrap` copies this deterministic scaffold instead of
reconstructing a minimal project from memory. The generated workspace is
`App.xcworkspace`, and the application scheme is `App`.

Validation commands:

```sh
tuist install
tuist generate --no-open
xcodebuild -workspace App.xcworkspace -scheme App \
  -destination 'generic/platform=iOS Simulator' build
xcodebuild test -workspace App.xcworkspace -scheme App \
  -destination 'platform=iOS Simulator,name=iPhone 16e,OS=26.0'
```

The named test destination records the simulator used for authoring.
Consumers and CI should select an available simulator for their installed
Xcode rather than assuming that exact runtime exists.
