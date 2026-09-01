USE collections_recovery;

-- P5: targeting / counterfactual identification.
-- Do NOT run a Difference-in-Differences estimate until a clean intervention
-- date, treatment group, control group and pre-period are established.

SELECT DATE_FORMAT(target_date, '%Y-%m-01') AS month,
       COUNT(*) AS target_rows,
       COUNT(DISTINCT account_id) AS accounts_targeted,
       COUNT(DISTINCT campaign_id) AS campaigns,
       COUNT(DISTINCT recommended_channel) AS recommended_channels
FROM fact_daily_targeting_golden
GROUP BY DATE_FORMAT(target_date, '%Y-%m-01')
ORDER BY month;

SELECT strategy_version,
       MIN(start_at) AS first_start,
       MAX(end_at) AS last_end,
       COUNT(*) AS campaigns
FROM dim_campaign
GROUP BY strategy_version
ORDER BY first_start;

SELECT DATE_FORMAT(target_date, '%Y-%m-01') AS month,
       status,
       COUNT(*) AS rows
FROM fact_daily_targeting_golden
GROUP BY DATE_FORMAT(target_date, '%Y-%m-01'), status
ORDER BY month, status;

-- Identification checklist:
-- 1. Is there a defensible targeting-change date?
-- 2. Is treatment assignment observable?
-- 3. Is an untreated control observable?
-- 4. Are there enough pre-period observations?
-- 5. Do treatment/control pre-trends appear parallel?
--
-- If any answer is NO, report the causal estimate as NOT IDENTIFIABLE.
