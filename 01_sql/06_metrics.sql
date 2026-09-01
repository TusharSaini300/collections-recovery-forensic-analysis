USE collections_recovery;

-- P3: independent KPI reconstruction.
-- The primary like-for-like metric is recovery from accounts that were
-- working at month-start divided by that same working population.

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
        SELECT m.month_start,
               a.account_id,
               COALESCE(h.status, a.status) AS status_asof,
               ROW_NUMBER() OVER (
                   PARTITION BY m.month_start, a.account_id
                   ORDER BY h.event_at DESC, h.history_id DESC
               ) AS rn
        FROM months m
        JOIN dim_account a
          ON a.opened_at < m.month_start
        LEFT JOIN fact_account_status_history h
          ON h.account_id = a.account_id
         AND h.event_at < m.month_start
    ) x
    WHERE rn = 1
),
working AS (
    SELECT month_start, account_id
    FROM latest_status
    WHERE status_asof NOT IN ('PAID','CLOSED','WRITEOFF')
),
monthly_payments AS (
    SELECT payment_id, account_id, event_at, amount
    FROM fact_payments_golden
    WHERE payment_status = 'SUCCESS'
)
SELECT w.month_start,
       COUNT(DISTINCT w.account_id) AS working_population,
       COALESCE(SUM(p.amount), 0) AS working_population_recovery,
       (
           SELECT COALESCE(SUM(p2.amount),0)
           FROM monthly_payments p2
           WHERE p2.event_at >= w.month_start
             AND p2.event_at < DATE_ADD(w.month_start, INTERVAL 1 MONTH)
       ) AS gross_recovery,
       ROUND(
           COALESCE(SUM(p.amount),0) / COUNT(DISTINCT w.account_id), 2
       ) AS working_recovery_per_account,
       ROUND(
           (
             SELECT COALESCE(SUM(p2.amount),0)
             FROM monthly_payments p2
             WHERE p2.event_at >= w.month_start
               AND p2.event_at < DATE_ADD(w.month_start, INTERVAL 1 MONTH)
           ) / COUNT(DISTINCT w.account_id), 2
       ) AS gross_recovery_per_working_account
FROM working w
LEFT JOIN monthly_payments p
  ON p.account_id = w.account_id
 AND p.event_at >= w.month_start
 AND p.event_at < DATE_ADD(w.month_start, INTERVAL 1 MONTH)
GROUP BY w.month_start
ORDER BY w.month_start;
