# SQL Repository Change Log

## v3 — MySQL 8.0+ rebuild

- Replaced DuckDB-specific syntax with MySQL 8.0+ syntax.
- Added `00_schema.sql` for the committed Golden Dataset.
- Added explicit MySQL database/table definitions.
- Replaced `generate_series()` with recursive CTEs.
- Replaced DuckDB timestamp functions with MySQL `TIMESTAMPDIFF`.
- Replaced abstract `raw.*` / `golden.*` references with actual Golden table names.
- Added explicit KPI definitions and execution order.
- Preserved the corrected point-in-time working-population logic.
- Preserved payment deduplication and near-duplicate audit.
- Preserved attribution, mix-standardization, fixed-cohort, driver and targeting diagnostics.
- Kept causal claims separate from observational associations.

## Validation

The SQL references the actual tables and columns in the committed `03_golden_dataset` CSVs. The queries use MySQL 8.0+ CTE/window-function syntax.

A live MySQL server is not available in this runtime, so no claim of database-engine execution is made here. The remaining local validation step is to import the Golden CSVs into MySQL 8.0+ and run the scripts in the documented order.

## v3.1 — package consistency

- Removed the obsolete DuckDB `00_setup.sql` file.
- Aligned README and execution order with the MySQL schema/import workflow.


## v3.2 — headline claim bridge

- Added `10_headline_claim_bridge.sql`.
- Explicitly reproduces the Feb→Mar gross-recovery increase of 11.03%.
- Documents the parallel Feb→Mar +11.73% movement in corrected recovery/account.
- Keeps the exact leadership KPI definition classified as UNVERIFIED because its numerator/denominator/attribution rule is not supplied.
