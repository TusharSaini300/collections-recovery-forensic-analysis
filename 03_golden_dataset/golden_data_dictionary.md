# Golden Dataset Data Dictionary

- `dim_account`: one row per account_id; clean analytical anchor.
- `dim_borrower`: best-effort current borrower state; conflicted IDs flagged LOW confidence.
- `dim_agent`: one row per source agent_id; identity is imperfect and first_seen_active_at is only an activity proxy.
- `fact_payments_golden`: deduplicated payment events; payment_id is the primary dedup key.
- `fact_calls_golden`: call events after documented normalization.
- `fact_dispositions`: raw code/version retained plus canonical mapping.
- `fact_account_status_history`: lifecycle events sequenced by event_at.
- `dim_monthly_working_population`: latest-status-as-of-month-start population.


## Operational fact tables required by the notebook

| Golden file | Source | Grain | Primary event key |
|---|---|---|---|
| fact_agent_sessions_golden.csv | agent_sessions.csv | one agent session | session_id |
| fact_daily_targeting_golden.csv | daily_targeting.csv | one targeting record | target_id |
| fact_field_visits_golden.csv | field_visits.csv | one field visit | visit_id |
| fact_promises_to_pay_golden.csv | promises_to_pay.csv | one PTP event | ptp_id |
| fact_sms_golden.csv | sms_events.csv | one SMS event | sms_event_id |
| fact_whatsapp_golden.csv | whatsapp_events.csv | one WhatsApp event | whatsapp_event_id |

WhatsApp is deduplicated only on exact duplicate event IDs/rows; the 600 duplicate rows are ingestion duplicates.
