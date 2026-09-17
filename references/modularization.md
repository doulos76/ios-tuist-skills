# Modularization Policy

## Core rule

Do not create a module simply because a feature exists. Modularization
has real costs (build graph complexity, boilerplate, indirection) and
must be justified by a concrete benefit.

## Pre-module checklist

Before creating, splitting, or merging a module, inspect all of:

- Ownership boundary — does this code have a clear, distinct owner/team
  or responsibility?
- Dependency direction — would the module introduce or resolve a
  direction problem in the graph?
- Reusability — is this code actually reused, or reusable in a concrete,
  near-term sense (not hypothetically)?
- Compile-time isolation benefit — does isolating this code meaningfully
  reduce incremental build time for other targets?
- Test boundary — does this code have tests that benefit from being
  isolated?
- Resource ownership — does this code own resources (assets, strings,
  storyboards) that are cleanly separable?
- Public API surface — is there a small, stable public surface this
  module would expose?
- Cyclic-dependency risk — would this split introduce a cycle, or resolve
  one?
- Build cost — does the split's ongoing build/maintenance cost outweigh
  its benefit?

Reject modularization proposed only because "this feels like it should
be its own module" with no concrete answer to the above.

## Linkage is a graph decision, not a default

Never make `.staticFramework`, `.framework`, `.staticLibrary`, or
`.dynamicLibrary` a universal default across a project. Before choosing
linkage for a target, inspect:

- The existing project's linkage convention.
- The transitive dependency graph (duplicate-symbol risk grows with
  static linkage across many targets that share dependencies).
- Resources owned by the target.
- App extension / widget extension constraints, if any.
- External binary requirements.
- Build iteration impact (incremental build time).
- App startup behavior.
- Xcode Previews / debug-build behavior.

Document which of these drove the linkage choice in the skill's output
when linkage is set explicitly.
