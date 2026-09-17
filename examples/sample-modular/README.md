# Sample modular app

This example starts from
[`templates/feature-modular`](../../templates/feature-modular/) and turns its
placeholder feature into a small weekly-reading flow. The app target owns only
launch configuration and delegates the UI and progress rules to
`ExampleFeature`, whose tests cover meaningful domain behavior.

It is reading context for people and coding agents, not part of fixture CI.
From this directory, run `tuist generate --no-open` and build the generated
`App.xcworkspace` to explore it. It was authored and verified with the Tuist
version recorded in `TUIST_VERSION_USED_TO_AUTHOR.txt`; that record is
provenance, not a consumer pin.
