Version Context: Tuist pinned to 4.206.0; active version check blocked. Xcode 27.1, Swift 6.4.

Changes Made: Added RetryKit to SearchFeature’s dependencies.

Files Changed: [Project.swift](Project.swift:67).

Dependency Changes: SearchFeature → RetryKit, using the existing local package integration.

Validation Performed: `git diff --check` passed. `tuist install` and generation failed because Tuist cannot write its session directory.

Build Result: SearchFeature and App builds blocked by the missing generated workspace.

Test Result: Not run.

Unverified Items: Package resolution, generation, builds, and tests.

Risks / Follow-up: RetryKit is available through the manifest declaration; request behavior is unchanged.

```ios-tuist-result
skill: ios-tuist-dependency
outcome: partial
version_evidence:
  effective: 4.206.0
  source: .tool-versions
  conflicts: []
  collected_by: script
files_changed: [Project.swift]
dependency_edges_added:
  - {from: SearchFeature, to: RetryKit, usage: none-found}
dependency_edges_removed: []
validation: {generate: fail, build: fail, test: not-run}
unverified:
  - Package resolution
  - Generation
  - SearchFeature and App builds
  - Tests
```