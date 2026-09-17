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

## Applying this checklist

This checklist is written once and used two ways, by two different
skills. Neither skill restates it — both link here.

### As an extraction gate (`ios-tuist-module`)

Every item in the pre-module checklist above must have a concrete,
stated answer before an extraction proceeds. An item answered "no
benefit," "hypothetical only," or "not yet, but maybe later" is a reason
to refuse the extraction and report why — it is not a box to check past.
A refusal is a complete, valid outcome of `ios-tuist-module`, not a
failure to work around.

### As a diagnostic score (`ios-tuist-architecture-review`)

Apply the same checklist per existing target to produce a finding, not a
code change. Example findings:

- "Target `X` has no distinct ownership boundary and no reuse beyond its
  single consumer — candidate to merge back into that consumer."
- "Target `Y` uses static linkage and shares a dependency already
  statically linked into `Z` — duplicate-symbol risk; investigate
  linkage."

Findings from this checklist are always reported, never acted on, by
`ios-tuist-architecture-review` itself. Acting on a finding is a separate,
explicit task for `ios-tuist-module`, `ios-tuist-feature`, or
`ios-tuist-dependency`.
