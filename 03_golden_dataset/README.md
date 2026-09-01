# Golden Dataset / Pipeline

`build_golden.py` builds the analytical Golden layer from the raw source tables.

## Core principles
- `account_id` is the primary clean natural key.
- Borrower and agent identities are explicitly treated as lower-confidence source dimensions.
- Payment duplicates are removed conservatively.
- Account status is reconstructed point-in-time at month-start.
- Operational event facts used by attribution, PTP integrity and targeting diagnostics are included in the Golden layer.

## Operational facts included
- `fact_agent_sessions_golden.csv`
- `fact_daily_targeting_golden.csv`
- `fact_field_visits_golden.csv`
- `fact_promises_to_pay_golden.csv`
- `fact_sms_golden.csv`
- `fact_whatsapp_golden.csv`

WhatsApp contains 600 exact duplicate event-ID rows; these are removed in the Golden layer. No non-exact duplicate WhatsApp event IDs were found.

## Reproducibility
Run from the submission root and set `COLLECTIONS_RAW` to the directory containing the 17 raw CSVs. Optionally set `COLLECTIONS_GOLDEN` to the desired output directory.

Example:

`COLLECTIONS_RAW=../raw COLLECTIONS_GOLDEN=03_golden_dataset python 03_golden_dataset/build_golden.py`

The committed Golden CSVs are the source of record for the notebook and presentation-layer artifacts.
