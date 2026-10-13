Version Context
Tuist: 4.206.0 (project-pinned)

Findings
- FeatureA depends on CoreKit without importing it.

```ios-tuist-result
skill: ios-tuist-architecture-review
outcome: completed
version_evidence:
  effective: 4.206.0
  source: .tool-versions
  conflicts: []
  collected_by: script
files_changed: []
dependency_edges_added: []
dependency_edges_removed: []
validation: {generate: not-run, build: not-run, test: not-run}
unverified:
  - FeatureA -> CoreKit usage via @_exported import not checked
```
