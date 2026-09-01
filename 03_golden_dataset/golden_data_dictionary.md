# Golden Dataset Data Dictionary

- `dim_account`: one row per account_id; clean analytical anchor.
- `dim_borrower`: best-effort current borrower state; conflicted IDs flagged LOW confidence.
- `dim_agent`: one row per source agent_id; identity is imperfect and first_seen_active_at is only an activity proxy.
- `fact_payments_golden`: deduplicated payment events; payment_id is the primary dedup key.
- `fact_calls_golden`: call events after documented normalization.
- `fact_dispositions`: raw code/version retained plus canonical mapping.
- `fact_account_status_history`: lifecycle events sequenced by event_at.
- `dim_monthly_working_population`: latest-status-as-of-month-start population.
