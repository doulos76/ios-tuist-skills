# Evidence-Driven Debugging

The shared failure-handling procedure. Each skill's `## Failure Handling`
section links here and adds the first hypothesis specific to that skill.

1. **Observed facts** — record: Tuist version (project + active), Xcode
   version, Swift version, the exact failing command, the exact error
   text, the affected manifest file.
2. **Hypotheses** — when the cause isn't immediately obvious from the
   error, generate at least two plausible hypotheses (e.g. "H1: active
   Tuist version doesn't support this ProjectDescription API"; "H2: the
   deployment target is incompatible with a dependency's minimum OS
   version").
3. **Contradiction search** — try to disprove the leading hypothesis
   before changing code (e.g. check the Tuist changelog/docs for the
   active version before assuming an API is unsupported).
4. **Minimal change** — apply the smallest change that explains the
   observed failure. Do not make speculative unrelated changes.
