USE collections_recovery;

-- P2B: attribution sensitivity
-- Change @lookback_days to 7, 14, or 30.
-- For an unlimited lookback, remove the final date condition in qualifying_touch.

SET @lookback_days = 30;

WITH touch_stream AS (
    SELECT account_id, event_at, 'CALL' AS channel
    FROM fact_calls_golden
    UNION ALL
    SELECT account_id, event_at, 'WHATSAPP'
    FROM fact_whatsapp_golden
    UNION ALL
    SELECT account_id, event_at, 'SMS'
    FROM fact_sms_golden
    UNION ALL
    SELECT account_id, event_at, 'FIELD'
    FROM fact_field_visits_golden
),
successful_payments AS (
    SELECT payment_id, account_id, event_at, amount
    FROM fact_payments_golden
    WHERE payment_status = 'SUCCESS'
),
qualifying_touch AS (
    SELECT p.payment_id,
           p.amount,
           t.channel,
           t.event_at AS touch_at,
           ROW_NUMBER() OVER (
               PARTITION BY p.payment_id
               ORDER BY t.event_at DESC
           ) AS rn
    FROM successful_payments p
    JOIN touch_stream t
      ON t.account_id = p.account_id
     AND t.event_at <= p.event_at
     AND t.event_at >= DATE_SUB(p.event_at, INTERVAL @lookback_days DAY)
)
SELECT channel,
       COUNT(*) AS attributed_payments,
       SUM(amount) AS attributed_recovery,
       ROUND(100 * SUM(amount) / SUM(SUM(amount)) OVER (), 2) AS recovery_share_pct
FROM qualifying_touch
WHERE rn = 1
GROUP BY channel
ORDER BY attributed_recovery DESC;

-- Repeat the query with @lookback_days = 7 and 14.
-- Compare rankings, not causal effects.
