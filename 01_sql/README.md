# SQL Repository — MySQL 8.0+

## Why MySQL?

This is the SQL environment used for the assignment work and is intentionally kept to **MySQL 8.0+** so the queries remain familiar and defensible in an interview/assignment review.

## Execution order

1. `00_schema.sql` — creates the database and Golden-table schemas.
2. Import the CSVs from `03_golden_dataset/` into the corresponding MySQL tables.
3. `01_profiling.sql` — validate grains and source anomalies.
4. `02_entity_resolution.sql` — identity-quality checks.
5. `03_payment_dedup.sql` — payment duplicate/near-duplicate audit.
6. `04_status_population.sql` — point-in-time working population.
7. `05_attribution.sql` — attribution-window sensitivity.
8. `06_metrics.sql` — independent recovery KPI reconstruction.
9. `07_mix_cohort.sql` — January mix standardization + fixed cohort.
10. `08_driver_analysis.sql` — descriptive driver screening.
11. `09_targeting_diagnostics.sql` — determine whether a historical counterfactual is identifiable.

## Importing the Golden CSVs

The easiest route in MySQL Workbench is:

**Navigator → Tables → right-click table → Table Data Import Wizard → select the corresponding CSV.**

Map the CSV columns to the already-created table columns. Keep the data unchanged; the Golden CSVs are the analytical source of record.

## Core KPI definitions

### Gross recovery
Sum of `amount` for `payment_status = 'SUCCESS'` during the month.

### Working-population recovery
Successful payment amount during the month from accounts whose latest status **strictly before month-start** is not `PAID`, `CLOSED`, or `WRITEOFF`.

### Recovery/account
`working-population recovery ÷ month-start working population`.

This is the primary like-for-like KPI.

### Working population
Point-in-time population at the start of each month. Historical terminal status does not permanently remove an account because later activity/reactivation exists in the data.

### Attribution
Last collection touch before payment under a specified lookback window. Attribution is a sensitivity analysis, not a causal estimate.

### Mix standardization
Direct standardization to January's DPD × risk segment × geography distribution.

### Fixed cohort
The same January working accounts are followed through July.

## Reproducibility note

The analytical SQL is designed to run against the committed Golden tables. MySQL 8.0+ is required for CTEs and window functions.

The notebook independently reconstructs the headline KPIs from the same Golden Dataset. The dashboard and executive memo should be treated as presentation layers over those reconciled results.

## Evidence discipline

- **FACT:** directly observed or mechanically reconstructed.
- **STRONG EVIDENCE:** survives relevant robustness checks.
- **CORRELATION:** observational association without causal identification.
- **HYPOTHESIS:** unresolved explanation.

The repository deliberately does not manufacture a historical Difference-in-Differences result when the supplied targeting data does not identify a clean intervention/control design.
