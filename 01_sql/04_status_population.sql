-- P2G/P3: point-in-time working population.
-- Determine latest status as of month-start; historical terminal status does not permanently remove an account.
WITH status_asof AS (
 SELECT m.month_start,a.account_id,
 COALESCE((SELECT h.status FROM golden.fact_account_status_history h WHERE h.account_id=a.account_id AND h.event_at<m.month_start ORDER BY h.event_at DESC LIMIT 1),'ACTIVE') status_asof
 FROM analytics.month_spine m JOIN golden.dim_account a ON a.opened_at<m.month_start)
SELECT month_start,COUNT(*) working_population FROM status_asof
WHERE status_asof NOT IN ('PAID','CLOSED','WRITEOFF') GROUP BY month_start ORDER BY month_start;
