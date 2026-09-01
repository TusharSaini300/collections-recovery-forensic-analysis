USE collections_recovery;

-- P1: borrower identity conflicts
SELECT borrower_id,
       COUNT(*) AS rows,
       COUNT(DISTINCT name) AS distinct_names,
       COUNT(DISTINCT phone) AS distinct_phones,
       COUNT(DISTINCT email) AS distinct_emails
FROM dim_borrower
GROUP BY borrower_id
HAVING COUNT(DISTINCT name) > 1
    OR COUNT(DISTINCT phone) > 1
    OR COUNT(DISTINCT email) > 1
ORDER BY rows DESC;

-- Agent source-ID stability.
-- Do NOT infer human identity/tenure from employee_code or joined_at.
SELECT agent_id,
       employee_code,
       vendor_id,
       team,
       status,
       first_seen_active_at,
       identity_confidence
FROM dim_agent
ORDER BY first_seen_active_at;

-- Observed activity tenure is a proxy, not HR tenure.
SELECT agent_id,
       first_seen_active_at,
       TIMESTAMPDIFF(DAY, first_seen_active_at, '2026-07-31 23:59:59') AS observed_days_active
FROM dim_agent
ORDER BY first_seen_active_at;
