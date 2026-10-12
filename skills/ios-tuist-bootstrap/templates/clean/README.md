# Clean template

A single SwiftUI application target keeps Presentation, Domain, and Data in
separate source folders. This profile demonstrates dependency boundaries
without multiplying targets before a concrete modularization benefit exists.
The tests exercise each layer's testable behavior and inject the Domain
protocol into Presentation.

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
```
