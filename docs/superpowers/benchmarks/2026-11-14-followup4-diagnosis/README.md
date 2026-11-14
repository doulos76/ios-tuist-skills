# Follow-up 4 diagnosis: name-mismatch caveat and the missed SearchFeature finding (2026-11-14)

Read-only analysis of existing evidence. **No paid runs, no skill changes.** Sources: the 2026-11-05 trial, the dependency reruns of 2026-11-07 and 2026-11-14 (runs 4-6, 22-27), `skills/ios-tuist-dependency/SKILL.md`, `skills/ios-tuist-dependency/scripts/check-consumer-edges.sh`, `skills/ios-tuist-architecture-review/SKILL.md`, `tests/fixtures/large-graph/EXPECTATIONS.md`.

## A. Name-mismatch caveat appears rarely

**Facts.** Across the nine Claude dependency runs on `large-graph` scenario 2 (runs 4-6 and 22-24 checked in the repo, 25-27 final messages), the caveat "product name may differ from the module name" appears in the final message once (run 5). The expectation (`EXPECTATIONS.md:106-108`) says "the report states that the product name may differ". The skill text (`SKILL.md:102-105`) tells the agent that external usage is searched by product name only and that the product name may differ, and to "report unresolved usage under Risks / Follow-up". The script prints the caveat itself only in its own output (`check-consumer-edges.sh:155`: `no usage found (external: product name may differ from module name)`).

**Reading (inference).** The skill never requires the caveat sentence in the report; it requires reporting the unresolved usage. All nine reports do report the no-usage edge, so they follow the skill. The expectation asks for more than the skill's wording. The miss is an expectation/skill mismatch, not agent drift.

**Options (not done).** (1) Relax the expectation to "reports the no-usage edge and does not call it unnecessary" (matches the skill; fixture-only change). (2) Add to step 9 "state in Risks / Follow-up that the product name may differ from the module name" (skill change, then a small N=3 rerun, about $0.8 equivalent). Recommendation: (2) only if the caveat is wanted for users; otherwise (1).

## B. `SearchFeature` -> `CoreNetworking` finding is missed by both agents

**Facts.** In the 2026-11-05 trial both Claude and Codex missed it (trial README, scenario 3 table). The expected finding (`EXPECTATIONS.md:119-123`): `SearchFeature` depends on `CoreNetworking` directly and `SearchViewModel.requestDescription(for:)` builds an `HTTPRequest` itself, "bypassing `CatalogDomain`". In `SearchFeature/Sources/SearchViewModel.swift` the same view model imports `CatalogDomain`, `CoreNetworking` and `CoreUI`, calls `HTTPClient` directly in `requestDescription`, and uses `CatalogService` in `catalogRequest`. The review skill's graph-level checks (`SKILL.md:75-81`) are: cycles, duplicate-symbol risk from static fan-out, targets with no owner or reuse, and dependency-direction violations "e.g. a shared/core target depending back on a feature target".

**Reading (inference).** The expected finding is a downward layer-skip plus a code-level overlap (the view model does itself what a domain already owns). The skill detects upward direction violations from the manifest graph and has no rule for layer skipping or for comparing what a consumer's source does with what a sibling dependency owns. `Project.swift` alone shows only a normal feature -> core edge (the same shape as `HomeFeature`'s). So the miss follows from the skill's scope, not from a one-off. This is a hypothesis; no run isolated it.

**Options (not done).** (1) Add a graph rule: a feature depends both on a domain target and directly on a core target; confirm by `import` plus call sites whether the feature re-implements what the domain owns, and report it as a candidate with evidence (skill change, then N=3 review reruns; review output was the least stable result in the trial, so expect noise). (2) Drop or soften the expectation to "reported if noticed". Recommendation: decide first whether layer-skipping belongs in this skill's scope; it is a design decision, not a bug fix.

## Limits

- A rests on nine final messages from one scenario, one agent and mixed model/CLI versions; B rests on one trial (N=1 per agent).
- I did not read Codex's transcripts again for A; only Claude runs were counted.

## Needs a decision

For each of A and B: change the expectation or change the skill. Neither change is made here.
