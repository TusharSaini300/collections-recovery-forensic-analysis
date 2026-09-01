# Data Quality Report — Golden Dataset Build

Raw record counts (all 17 source tables):

borrowers                  30600
accounts                   30000
agents                     30000
agent_sessions             15000
campaigns                    120
daily_targeting            45000
calls                      91350
call_attempts             120000
call_dispositions          35000
whatsapp_events            60600
sms_events                 45000
field_visits               25000
promises_to_pay            18000
payments                   25500
vendor_telephony              15
complaints                  8000
account_status_history     60000

### dim_account
accounts.csv is clean: 30000 rows, 30000 unique account_id, 0 duplicates. Used as-is. This is the ANCHOR entity for the whole golden layer — every other dimension's reliability is judged relative to this one.

### dim_borrower — CRITICAL FINDING
borrowers.csv has 30600 rows for only 11015 unique borrower_id (avg 2.78 rows/id). This is NOT a clean append-only update log: 8185 borrower_ids (74.3%) show *conflicting names* across their rows (e.g. BRW0006302 appears as 'Aarav Sharma', 'Sneha Das', 'Vikram Shah', 'Priya Mehta', 'Neha Singh', 'Rahul Verma', 'Amit Kumar' — seven different people under one ID). This means borrower_id is functioning as a **collision-prone recycled key**, not a stable person identifier. There is no reliable secondary key to re-resolve identity (phone has 614 nulls and is not clean either). DECISION: treat borrower_id as a join key to accounts only, not as proof of 'same person'. Build dim_borrower by taking the MOST RECENT row per borrower_id (by updated_at) as a best-effort 'current believed state', and flag every borrower_id with attribute conflicts as identity_confidence=LOW. Any borrower-level demographic cut (e.g. by city/state) inherits this low confidence and should be reported with that caveat, never presented as clean segmentation.

### dim_agent — corrected methodology
30000 source rows collapse to 1000 agent_ids. employee_code and joined_at are not used for identity/tenure because prior null-model tests showed they create false precision. first_seen_active_at from actual call activity is retained only as an observed activity proxy.

### dim_campaign
campaigns.csv: 120 unique campaign_id but only 5 distinct campaign_name values — each logical campaign family (e.g. NPA_RECOVERY) is relaunched under a new campaign_id 24 times on average, often overlapping in time with different strategy_version tags. DECISION: keep campaign_id as the true analytical grain (it's what calls/targeting actually reference), rename campaign_name to campaign_family for rollup reporting. Any 'campaign performance' metric must state which grain it used — 'per campaign_id' and 'per campaign_family' will tell different stories, and the reported 11% may have used whichever grain was convenient (this is one of the attribution-error hypotheses to test in Part 2).

### disposition crosswalk
All 9 disposition_code values appear in roughly equal volume (~1,250-1,370 rows) under ALL THREE disposition_version tags (legacy/v1/v2) — so the versions are NOT sequential code-set replacements, they coexist for the whole period (likely marks which pipeline/vendor wrote the row, not a taxonomy migration). Separately, 'PTP' and 'PROMISE_TO_PAY' exist as two independent code strings at near-identical volume — very likely the same real-world outcome logged by two different systems/channels. DECISION (flagged HYPOTHESIS, not Fact — needs SME confirmation): canonicalize PTP + PROMISE_TO_PAY -> 'PTP_MADE' for the golden layer, keep disposition_version as a lineage attribute (not part of the canonical code). If wrong, PTP rate is understated by ~50% in any report that only queried one of the two strings — worth checking whether the reported 11% used just one.

### payments dedup — TWO DIFFERENT PROBLEMS, ONE TRAP
Raw payments: 25500 rows. (a) 500 rows are exact full duplicate payment_id — pure ingestion/retry noise, dropped outright (500 rows removed). (b) 3406 groups of rows share a duplicate payment_reference, but critically only 0 of those groups (0%) actually share the same account_id + amount — i.e. only those are true duplicate submissions. The other 3406 groups (100%) are DIFFERENT payments (different account, different amount) that happen to share a reference string — payment_reference is not globally unique in this system and is NOT a safe dedup key on its own. THE TRAP: a naive 'drop duplicate payment_reference' rule would have deleted ~3406 legitimate, distinct payments — i.e. it would have artificially DEFLATED recovery, the opposite error from double-counting. DECISION: dedup only on (payment_reference, account_id, amount) match, keep earliest by event_at within true-dupe groups. Net rows removed: 500 of 25500 (2.0%).

### account_status_history — timestamp integrity
30191/60000 rows (50%) have recorded_at BEFORE event_at — impossible in a real system (you cannot log an event before it happened). This means recorded_at cannot be trusted as an ingestion-lag signal at row level; it looks like independent random noise around event_at rather than a genuine ingestion timestamp. DECISION: use event_at as the sole source of truth for status sequencing. Do NOT compute 'late-arriving data' SLA metrics from recorded_at without first fixing this at the source — any such metric in Part 5's monitoring design should flag rows where recorded_at < event_at as REJECTED for lag-calculation purposes, not silently averaged in (a naive AVG(recorded_at-event_at) would be biased toward ~0 and mask real late-arrival).

### timezone normalization
calls, accounts, agent_sessions, vendor_telephony carry an explicit timezone column (Asia/Kolkata / Asia/Dubai / UTC, near-even 3-way split) and are normalized to UTC for the golden layer. payments, call_dispositions, promises_to_pay, whatsapp/sms events, field_visits, complaints, account_status_history carry NO timezone column — their event_at timezone is UNSTATED. DECISION: assume Asia/Kolkata (business HQ timezone) for these tables and flag tz_confidence=ASSUMED on every row, rather than silently treating them as UTC (which would shift every hour-of-day and day-of-week analysis in Part 2's 'calling time' investigation by up to 5.5 hours with no warning).

### monthly working population (corrected)
Uses latest account status as of month-start. Accounts can reappear after a terminal event if later status/activity supports that. No permanent first-terminal exclusion.

  month  working_population
2026-01               30000
2026-02               26838
2026-03               24667
2026-04               22852
2026-05               21444
2026-06               20364
2026-07               19643
2026-08               18931

### operational Golden facts
PTP=18,000 rows, SMS=45,000, field visits=25,000, agent sessions=15,000, daily targeting=45,000. WhatsApp had 600 duplicate event IDs, all of which were exact duplicate rows; deduplicated to 60,000 rows. No non-exact WhatsApp ID reuse was found.

### IMPACT SUMMARY
                 table  raw_rows  golden_rows  rows_removed                                                                                                treatment
             borrowers     30600        11015         19585             collapsed to 1 row/borrower_id (latest by updated_at); LOW-confidence flag on conflicted ids
                agents     30000         1000         29000 collapsed to 1 row/agent_id for descriptive attributes; first_seen_active_at used only as activity proxy
              payments     25500        25000           500                                dropped exact payment_id dupes + true reference+account+amount dupes only
account_status_history     60000        60000             0                           kept all rows, flagged 30191 as RECORDED_BEFORE_EVENT (not usable for lag SLA)
     call_dispositions     35000        35000             0                          added disposition_canonical (PTP+PROMISE_TO_PAY -> PTP_MADE), kept raw code too
       whatsapp_events     60600        60000           600             removed exact duplicate whatsapp_event_id rows only; all duplicate IDs were exact duplicates
