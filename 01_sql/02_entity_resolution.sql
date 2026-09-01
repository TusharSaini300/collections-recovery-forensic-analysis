-- P1: account is the clean anchor. Borrower/agent IDs are collision-prone.
CREATE OR REPLACE VIEW golden.dim_account AS SELECT * FROM raw.accounts;
CREATE OR REPLACE VIEW golden.dim_borrower AS
WITH conflicts AS (SELECT borrower_id, COUNT(DISTINCT name) distinct_names FROM raw.borrowers GROUP BY borrower_id),
r AS (SELECT b.*, ROW_NUMBER() OVER(PARTITION BY borrower_id ORDER BY updated_at DESC) rn FROM raw.borrowers b)
SELECT r.*, CASE WHEN c.distinct_names>1 THEN 'LOW' ELSE 'MEDIUM' END identity_confidence
FROM r JOIN conflicts c ON r.borrower_id=c.borrower_id WHERE rn=1;
-- Agent tenure: do NOT use joined_at or employee_code as identity.
-- first_seen_active_at is derived from calls and is only an observed-activity proxy.
