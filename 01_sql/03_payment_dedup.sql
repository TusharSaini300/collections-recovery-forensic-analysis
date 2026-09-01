-- P1/P2A: exact payment_id duplicate removal.
CREATE OR REPLACE TABLE golden.fact_payments AS
WITH r AS (SELECT p.*, ROW_NUMBER() OVER(PARTITION BY payment_id ORDER BY event_at) rn FROM raw.payments p)
SELECT * FROM r WHERE rn=1;
-- payment_reference is not globally unique; never deduplicate on reference alone.
-- A broader same-account + same-amount + 60-minute audit found no extra duplicates.
