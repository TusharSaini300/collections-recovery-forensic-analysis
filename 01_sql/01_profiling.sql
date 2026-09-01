USE collections_recovery;

-- P0: Golden-layer row/grain checks
SELECT 'dim_account' AS table_name, COUNT(*) AS rows,
       COUNT(DISTINCT account_id) AS distinct_keys,
       COUNT(*) - COUNT(DISTINCT account_id) AS duplicate_key_rows
FROM dim_account
UNION ALL
SELECT 'fact_payments_golden', COUNT(*), COUNT(DISTINCT payment_id),
       COUNT(*) - COUNT(DISTINCT payment_id)
FROM fact_payments_golden
UNION ALL
SELECT 'dim_agent', COUNT(*), COUNT(DISTINCT agent_id),
       COUNT(*) - COUNT(DISTINCT agent_id)
FROM dim_agent;

-- Calls are intentionally NOT required to be unique on call_id because the
-- source contains 79 non-identical repeated IDs after exact duplicate removal.
SELECT COUNT(*) AS rows,
       COUNT(DISTINCT call_id) AS distinct_call_ids,
       COUNT(*) - COUNT(DISTINCT call_id) AS repeated_id_rows
FROM fact_calls_golden;

-- Timestamp integrity
SELECT COUNT(*) AS status_rows,
       SUM(recorded_at < event_at) AS recorded_before_event,
       ROUND(100 * SUM(recorded_at < event_at) / COUNT(*), 2) AS pct_flagged
FROM fact_account_status_history;

-- Payment reference collision audit
SELECT payment_reference,
       COUNT(*) AS rows,
       COUNT(DISTINCT account_id) AS accounts,
       COUNT(DISTINCT amount) AS amounts
FROM fact_payments_golden
WHERE payment_reference IS NOT NULL
GROUP BY payment_reference
HAVING COUNT(*) > 1
ORDER BY rows DESC
LIMIT 25;
