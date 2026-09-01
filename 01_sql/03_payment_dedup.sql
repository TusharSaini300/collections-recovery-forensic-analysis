USE collections_recovery;

-- P2A: exact payment-key uniqueness
SELECT COUNT(*) AS rows,
       COUNT(DISTINCT payment_id) AS distinct_payment_ids,
       COUNT(*) - COUNT(DISTINCT payment_id) AS duplicate_payment_ids
FROM fact_payments_golden;

-- Same-account + same-amount within 60 minutes.
-- This is an investigation set, not an automatic deletion rule.
SELECT COUNT(*) AS near_duplicate_pairs
FROM fact_payments_golden p1
JOIN fact_payments_golden p2
  ON p1.account_id = p2.account_id
 AND p1.payment_id < p2.payment_id
 AND p1.amount = p2.amount
 AND ABS(TIMESTAMPDIFF(SECOND, p1.event_at, p2.event_at)) <= 3600;

-- Payment reconciliation by status
SELECT payment_status,
       COUNT(*) AS payment_count,
       SUM(amount) AS payment_amount
FROM fact_payments_golden
GROUP BY payment_status
ORDER BY payment_amount DESC;
