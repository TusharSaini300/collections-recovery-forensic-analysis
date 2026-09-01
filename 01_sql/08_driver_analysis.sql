USE collections_recovery;

-- P4: descriptive driver screening.
-- These are associations, not causal effects.

WITH recovery AS (
    SELECT account_id, SUM(amount) AS recovery
    FROM fact_payments_golden
    WHERE payment_status = 'SUCCESS'
      AND event_at >= '2026-01-01'
      AND event_at < '2026-08-01'
    GROUP BY account_id
),
account_base AS (
    SELECT a.account_id,
           CASE
             WHEN a.dpd <= 30 THEN '0-30'
             WHEN a.dpd <= 60 THEN '31-60'
             WHEN a.dpd <= 90 THEN '61-90'
             ELSE '90+'
           END AS dpd_bucket,
           a.risk_segment,
           b.state,
           a.loan_type,
           COALESCE(r.recovery,0) AS recovery
    FROM dim_account a
    LEFT JOIN dim_borrower b ON b.borrower_id = a.borrower_id
    LEFT JOIN recovery r ON r.account_id = a.account_id
)
SELECT 'DPD' AS dimension, dpd_bucket AS category,
       COUNT(*) AS accounts, SUM(recovery) AS total_recovery,
       AVG(recovery) AS recovery_per_account
FROM account_base
GROUP BY dpd_bucket
UNION ALL
SELECT 'RISK', risk_segment, COUNT(*), SUM(recovery), AVG(recovery)
FROM account_base
GROUP BY risk_segment
UNION ALL
SELECT 'GEOGRAPHY', state, COUNT(*), SUM(recovery), AVG(recovery)
FROM account_base
GROUP BY state
UNION ALL
SELECT 'LOAN_TYPE', loan_type, COUNT(*), SUM(recovery), AVG(recovery)
FROM account_base
GROUP BY loan_type
ORDER BY dimension, recovery_per_account DESC;

-- Simple observational exposure comparison.
WITH exposure AS (
    SELECT DISTINCT account_id FROM fact_calls_golden
),
recovery AS (
    SELECT account_id, SUM(amount) AS recovery
    FROM fact_payments_golden
    WHERE payment_status='SUCCESS'
      AND event_at >= '2026-01-01'
      AND event_at < '2026-08-01'
    GROUP BY account_id
)
SELECT CASE WHEN e.account_id IS NULL THEN 'NO_CALL' ELSE 'CALL_EXPOSED' END AS exposure,
       COUNT(*) AS accounts,
       AVG(COALESCE(r.recovery,0)) AS recovery_per_account
FROM dim_account a
LEFT JOIN exposure e ON e.account_id = a.account_id
LEFT JOIN recovery r ON r.account_id = a.account_id
GROUP BY exposure
ORDER BY exposure;
