# Sample minimal app

This example starts from [`templates/minimal`](../../templates/minimal/) and
replaces the greeting-only content with a small counter. `Counter` contains
real state transitions, `CounterView` presents them, and the test verifies both
increment and reset behavior.

It is reading context for people and coding agents, not part of fixture CI.
From this directory, run `tuist generate --no-open` and build the generated
`App.xcworkspace` to explore it. It was authored and verified with the Tuist
version recorded in `TUIST_VERSION_USED_TO_AUTHOR.txt`; that record is
provenance, not a consumer pin.
