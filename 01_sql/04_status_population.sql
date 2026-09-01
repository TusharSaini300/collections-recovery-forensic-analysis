USE collections_recovery;

-- P2G: point-in-time working population.
-- MySQL 8 recursive CTE generates Jan-Jul month starts.
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
)
SELECT month_start,
       COUNT(DISTINCT account_id) AS working_population
FROM latest_status
WHERE status_asof NOT IN ('PAID','CLOSED','WRITEOFF')
GROUP BY month_start
ORDER BY month_start;

-- Reactivation diagnostic
WITH first_terminal AS (
    SELECT account_id, MIN(event_at) AS first_terminal_at
    FROM fact_account_status_history
    WHERE status IN ('PAID','CLOSED','WRITEOFF')
    GROUP BY account_id
),
later_activity AS (
    SELECT DISTINCT h.account_id
    FROM fact_account_status_history h
    JOIN first_terminal f
      ON f.account_id = h.account_id
    WHERE h.event_at > f.first_terminal_at
)
SELECT
    (SELECT COUNT(*) FROM first_terminal) AS terminal_accounts,
    COUNT(*) AS accounts_with_later_activity,
    ROUND(100 * COUNT(*) /
          NULLIF((SELECT COUNT(*) FROM first_terminal), 0), 2) AS pct_reactivated
FROM later_activity;
