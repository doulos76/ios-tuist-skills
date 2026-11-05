Done. RetryKit is now attached to SearchFeature, and both the feature and the app build successfully.

**Version Context**
- Tuist: 4.206.0 pinned in `.tool-versions`; active `tuist version` matches (4.206.0). Xcode 27.1, Swift 6.4 active. Manifest syntax is Tuist-native SPM integration (`Tuist/Package.swift` + `.external(name:)`), compatible with the pinned version — no syntax changes needed.

**Changes Made**
- Attached RetryKit (local Swift package at `Packages/RetryKit`, already declared in `Tuist/Package.swift` with a `.staticFramework` product type) to the SearchFeature target only, using the repo's existing `.external(name:)` convention.

**Files Changed**
- `Project.swift:70` — added `.external(name: "RetryKit")` to SearchFeature's dependencies (one line; nothing else touched).

**Dependency Changes**
- Package: RetryKit — local package, path `../Packages/RetryKit` (declaration already existed in `Tuist/Package.swift`, unchanged)
- Attached to: SearchFeature only (explicit in the request; App, other features, and core targets untouched)
- Integration mechanism: Tuist/Package.swift external-package integration (existing repo convention, unchanged)
- Edge check: not applicable — package product dependency, not a `.target`/`.project` edge

**Validation Performed**
- `tuist install`: success
- `tuist generate`: success (one pre-existing, unrelated warning about CoreUtilities being statically linked from both App and LegacyHelpers)
- `tuist build SearchFeature`: success
- `tuist build App`: success

**Test Result**
- Not run — no test target depends on this change (SearchFeature has no test target in the manifest).

**Unverified Items**
- None.

**Risks / Follow-up**
- No file in `SearchFeature/Sources` imports RetryKit yet — the wiring is in place, but the retry behavior itself (e.g. in `SearchViewModel.swift`) still needs to be written to actually use it.

```ios-tuist-result
skill: ios-tuist-dependency
status: success
tuist_pinned: 4.206.0
tuist_active: 4.206.0
dependency: RetryKit
dependency_kind: local-swift-package
attached_to: SearchFeature
integration: tuist-package-swift
files_changed:
  - Project.swift
validation:
  install: success
  generate: success
  build_consumer: success
  build_app: success
  tests: not-run
```