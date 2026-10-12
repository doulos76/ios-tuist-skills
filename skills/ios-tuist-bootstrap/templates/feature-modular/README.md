# Feature-modular template

A thin SwiftUI application target depends on a self-contained
`ExampleFeature` static framework. Each production target has its own Swift
Testing target. The graph is deliberately one-way: `App → ExampleFeature`.
The static framework keeps this small example's linkage explicit and avoids
runtime embedding overhead; consumers should reevaluate linkage against
their own graph rather than treating it as a universal default.

This template was authored and verified with Tuist `4.206.0`. The version
is provenance for maintainers, not a consumer pin. `ios-tuist-bootstrap`
must establish the consumer's Tuist Context before copying or adapting it.

The generated workspace is `App.xcworkspace`, and the application scheme is
`App`. The named test destination records the authoring environment; select
an available simulator when using another Xcode installation.

```sh
tuist install
tuist generate --no-open
xcodebuild -workspace App.xcworkspace -scheme App \
  -destination 'generic/platform=iOS Simulator' build
xcodebuild test -workspace App.xcworkspace -scheme App \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5'
xcodebuild test -workspace App.xcworkspace -scheme ExampleFeature \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5'
```
