# Routing evaluation — plugin-only

Date: 2026-11-07T03:01:53Z | Claude Code: 2.1.319 | Plugin version: 0.9.1 | Budget/case: $1.2

Accuracy: 3/3 (100.0%)

| Category | Correct | Rate |
|---|---|---|
| adjacent | 1/1 | 100.0% |
| positive | 2/2 | 100.0% |

## Forbidden-skill violations
- none

## Per skill
| Skill | TP | FP | FN | Precision | Recall |
|---|---|---|---|---|---|
| feature | 2 | 0 | 0 | 1.0 | 1.0 |
| scaffold | 1 | 0 | 0 | 1.0 | 1.0 |

## Confusion matrix (rows = expected, columns = selected)
| expected \ selected | feature | scaffold | none |
|---|---|---|---|
| feature | 2 | 0 | 0 |
| scaffold | 0 | 1 | 0 |
| none | 0 | 0 | 0 |

## Anomalies
- none

## Plan-mode plan files (recorded, not a stop)
- none

Known cost: $0.00 over 0 cases; 3 cases stopped before a result (cost unknown)
