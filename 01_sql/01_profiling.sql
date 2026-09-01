-- P0: source profiling / grain checks
SELECT 'accounts' table_name, COUNT(*) rows, COUNT(DISTINCT account_id) distinct_keys, COUNT(*)-COUNT(DISTINCT account_id) duplicates FROM raw.accounts;
SELECT 'payments' table_name, COUNT(*) rows, COUNT(DISTINCT payment_id) distinct_keys, COUNT(*)-COUNT(DISTINCT payment_id) duplicates FROM raw.payments;
SELECT 'agents' table_name, COUNT(*) rows, COUNT(DISTINCT agent_id) distinct_keys FROM raw.agents;
SELECT 'borrowers' table_name, COUNT(*) rows, COUNT(DISTINCT borrower_id) distinct_keys FROM raw.borrowers;
SELECT COUNT(*) recorded_before_event FROM raw.account_status_history WHERE recorded_at < event_at;
SELECT payment_reference, COUNT(*) rows, COUNT(DISTINCT account_id) accounts, COUNT(DISTINCT amount) amounts FROM raw.payments WHERE payment_reference IS NOT NULL GROUP BY payment_reference HAVING COUNT(*)>1;
