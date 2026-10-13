# Routing evaluation — plugin-only

Date: 2026-10-12T17:15:21Z | Claude Code: 2.1.296 | Plugin version: 0.8.1 | Budget/case: $0.3

Accuracy: 42/45 (93.3%)

| Category | Correct | Rate |
|---|---|---|
| adjacent | 6/7 | 85.7% |
| ambiguous | 4/4 | 100.0% |
| negative | 8/8 | 100.0% |
| official-conflict | 6/6 | 100.0% |
| positive | 18/20 | 90.0% |

## Forbidden-skill violations
- none

## Per skill
| Skill | TP | FP | FN | Precision | Recall |
|---|---|---|---|---|---|
| architecture-review | 3 | 0 | 0 | 1.0 | 1.0 |
| bootstrap | 2 | 0 | 0 | 1.0 | 1.0 |
| ci | 2 | 0 | 0 | 1.0 | 1.0 |
| dependency | 3 | 0 | 0 | 1.0 | 1.0 |
| feature | 1 | 0 | 2 | 1.0 | 0.333 |
| migrate | 3 | 0 | 0 | 1.0 | 1.0 |
| module | 3 | 0 | 0 | 1.0 | 1.0 |
| restyle | 3 | 0 | 0 | 1.0 | 1.0 |
| scaffold | 2 | 0 | 0 | 1.0 | 1.0 |
| test-target | 2 | 0 | 1 | 1.0 | 0.667 |

## Confusion matrix (rows = expected, columns = selected)
| expected \ selected | architecture-review | bootstrap | ci | dependency | feature | migrate | module | restyle | scaffold | test-target | none |
|---|---|---|---|---|---|---|---|---|---|---|---|
| architecture-review | 3 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| bootstrap | 0 | 2 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| ci | 0 | 0 | 2 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| dependency | 0 | 0 | 0 | 3 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| feature | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 2 |
| migrate | 0 | 0 | 0 | 0 | 0 | 3 | 0 | 0 | 0 | 0 | 0 |
| module | 0 | 0 | 0 | 0 | 0 | 0 | 3 | 0 | 0 | 0 | 0 |
| restyle | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 3 | 0 | 0 | 0 |
| scaffold | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 2 | 0 | 0 |
| test-target | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 2 | 1 |
| none | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 18 |

## Anomalies
- none

Known cost: $3.43 over 14 cases; 31 cases stopped before a result (cost unknown)
