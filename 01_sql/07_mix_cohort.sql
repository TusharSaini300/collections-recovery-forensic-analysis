USE collections_recovery;

-- P3A: January mix-standardized recovery
-- Reference mix = January DPD bucket x risk segment x geography.

WITH RECURSIVE months AS (
    SELECT DATE('2026-01-01') AS month_start
    UNION ALL
    SELECT DATE_ADD(month_start, INTERVAL 1 MONTH)
    FROM months
    WHERE month_start < DATE('2026-07-01')
),
latest_status AS (
    SELECT month_start, account_id, status_asof
    FROM (
        SELECT m.month_start, a.account_id,
               COALESCE(h.status, a.status) AS status_asof,
               ROW_NUMBER() OVER (
                   PARTITION BY m.month_start, a.account_id
                   ORDER BY h.event_at DESC, h.history_id DESC
               ) AS rn
        FROM months m
        JOIN dim_account a ON a.opened_at < m.month_start
        LEFT JOIN fact_account_status_history h
          ON h.account_id = a.account_id
         AND h.event_at < m.month_start
    ) x
    WHERE rn = 1
),
working AS (
    SELECT l.month_start, a.account_id,
           CASE
             WHEN a.dpd <= 30 THEN '0-30'
             WHEN a.dpd <= 60 THEN '31-60'
             WHEN a.dpd <= 90 THEN '61-90'
             ELSE '90+'
           END AS dpd_bucket,
           a.risk_segment,
           b.state
    FROM latest_status l
    JOIN dim_account a ON a.account_id = l.account_id
    LEFT JOIN dim_borrower b ON b.borrower_id = a.borrower_id
    WHERE l.status_asof NOT IN ('PAID','CLOSED','WRITEOFF')
),
cells AS (
    SELECT w.month_start, w.dpd_bucket, w.risk_segment, w.state,
           COUNT(DISTINCT w.account_id) AS accounts,
           COALESCE(SUM(p.amount),0) AS recovery
    FROM working w
    LEFT JOIN fact_payments_golden p
      ON p.account_id = w.account_id
     AND p.payment_status = 'SUCCESS'
     AND p.event_at >= w.month_start
     AND p.event_at < DATE_ADD(w.month_start, INTERVAL 1 MONTH)
    GROUP BY w.month_start, w.dpd_bucket, w.risk_segment, w.state
),
jan_mix AS (
    SELECT dpd_bucket, risk_segment, state,
           accounts / SUM(accounts) OVER () AS jan_share
    FROM cells
    WHERE month_start = DATE('2026-01-01')
)
SELECT c.month_start,
       SUM(
           CASE
             WHEN j.jan_share IS NULL OR c.accounts = 0 THEN 0
             ELSE j.jan_share * c.recovery / c.accounts
           END
       ) AS jan_mix_standardized_recovery_per_account
FROM cells c
LEFT JOIN jan_mix j
  ON j.dpd_bucket = c.dpd_bucket
 AND j.risk_segment = c.risk_segment
 AND (j.state <=> c.state)
GROUP BY c.month_start
ORDER BY c.month_start;


-- P3B: fixed January cohort
WITH RECURSIVE months AS (
    SELECT DATE('2026-01-01') AS month_start
    UNION ALL
    SELECT DATE_ADD(month_start, INTERVAL 1 MONTH)
    FROM months
    WHERE month_start < DATE('2026-07-01')
),
jan_status AS (
    SELECT account_id, status_asof
    FROM (
        SELECT a.account_id,
               COALESCE(h.status, a.status) AS status_asof,
               ROW_NUMBER() OVER (
                   PARTITION BY a.account_id
                   ORDER BY h.event_at DESC, h.history_id DESC
               ) AS rn
        FROM dim_account a
        LEFT JOIN fact_account_status_history h
          ON h.account_id = a.account_id
         AND h.event_at < DATE('2026-01-01')
        WHERE a.opened_at < DATE('2026-01-01')
    ) x
    WHERE rn = 1
),
jan_working AS (
    SELECT account_id
    FROM jan_status
    WHERE status_asof NOT IN ('PAID','CLOSED','WRITEOFF')
)
SELECT m.month_start,
       COUNT(DISTINCT j.account_id) AS original_jan_accounts,
       COALESCE(SUM(p.amount),0) AS recovery,
       ROUND(
           COALESCE(SUM(p.amount),0) / COUNT(DISTINCT j.account_id), 2
       ) AS recovery_per_original_jan_account
FROM months m
CROSS JOIN jan_working j
LEFT JOIN fact_payments_golden p
  ON p.account_id = j.account_id
 AND p.payment_status = 'SUCCESS'
 AND p.event_at >= m.month_start
 AND p.event_at < DATE_ADD(m.month_start, INTERVAL 1 MONTH)
GROUP BY m.month_start
ORDER BY m.month_start;
