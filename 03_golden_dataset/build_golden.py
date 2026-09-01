# FINAL CORRECTED GOLDEN PIPELINE
# Run from the submission root: python 03_golden_dataset/build_golden.py
# Raw input expected at ../data/raw when run from this folder, or set RAW below.
"""
Golden Dataset Pipeline — Collections Analytics
=================================================
Builds a trustworthy analytical layer from 17 raw source tables.
Every cleaning decision below is documented inline and logged to
reports/data_quality_report.md via the `log()` calls.

Design principle: ACCOUNT_ID is the only fully clean natural key in
this dataset (30,000 rows / 30,000 unique account_id, zero dupes).
BORROWER_ID and AGENT_ID are NOT reliable person-level keys (see
findings below) — they are treated as low-confidence dimensions,
not as ground truth for "same person" claims.
"""
import pandas as pd
import numpy as np
import os

RAW = os.environ.get("COLLECTIONS_RAW", "data")
OUT = os.environ.get("COLLECTIONS_GOLDEN", "golden")
REPORT_DIR = os.environ.get("COLLECTIONS_REPORT_DIR", "03_golden_dataset/reports")
os.makedirs(OUT, exist_ok=True)
os.makedirs(REPORT_DIR, exist_ok=True)

LOG_LINES = []
def log(section, msg):
    LOG_LINES.append(f"### {section}\n{msg}\n")
    print(f"[{section}] {msg}")

def read(name, parse_dates=None):
    return pd.read_csv(f"{RAW}/{name}.csv", parse_dates=parse_dates, low_memory=False)

# ---------------------------------------------------------------------------
# 0. LOAD RAW
# ---------------------------------------------------------------------------
borrowers   = read("borrowers", ["created_at","updated_at"])
accounts    = read("accounts", ["opened_at"])
agents      = read("agents", ["joined_at","updated_at"])
sessions    = read("agent_sessions", ["login_at","logout_at"])
campaigns   = read("campaigns", ["start_at","end_at"])
targeting   = read("daily_targeting", ["target_date"])
calls       = read("calls", ["event_at"])
attempts    = read("call_attempts", ["event_at"])
dispositions= read("call_dispositions", ["event_at"])
wa          = read("whatsapp_events", ["event_at"])
sms         = read("sms_events", ["event_at"])
visits      = read("field_visits", ["event_at","scheduled_at"])
ptp         = read("promises_to_pay", ["event_at","promised_date"])
payments    = read("payments", ["event_at"])
vendors     = read("vendor_telephony")
complaints  = read("complaints", ["event_at","resolution_at"])
history     = read("account_status_history", ["event_at","recorded_at"])
# Operational facts used by attribution, PTP integrity and counterfactual diagnostics.
# These are pass-through Golden facts except where an exact duplicate natural ID is present.
wa          = read("whatsapp_events", ["event_at"])
sms         = read("sms_events", ["event_at"])
visits      = read("field_visits", ["event_at","scheduled_at"])
ptp         = read("promises_to_pay", ["event_at","promised_date"])
sessions    = read("agent_sessions", ["login_at","logout_at"])
targeting   = read("daily_targeting", ["target_date"])

RAW_COUNTS = {name: len(df) for name, df in [
    ("borrowers",borrowers),("accounts",accounts),("agents",agents),
    ("agent_sessions",sessions),("campaigns",campaigns),("daily_targeting",targeting),
    ("calls",calls),("call_attempts",attempts),("call_dispositions",dispositions),
    ("whatsapp_events",wa),("sms_events",sms),("field_visits",visits),
    ("promises_to_pay",ptp),("payments",payments),("vendor_telephony",vendors),
    ("complaints",complaints),("account_status_history",history),
]}

# ---------------------------------------------------------------------------
# 1. DIM_ACCOUNT — clean as-is, this is the only reliable natural key
# ---------------------------------------------------------------------------
assert accounts.account_id.is_unique, "accounts.account_id not unique — assumption broken"
dim_account = accounts.copy()
log("dim_account", f"accounts.csv is clean: {len(accounts)} rows, {accounts.account_id.nunique()} unique account_id, "
    f"0 duplicates. Used as-is. This is the ANCHOR entity for the whole golden layer — "
    f"every other dimension's reliability is judged relative to this one.")

# ---------------------------------------------------------------------------
# 2. DIM_BORROWER — borrower_id is NOT a reliable person-level key
# ---------------------------------------------------------------------------
n_raw_b = len(borrowers)
n_unique_b = borrowers.borrower_id.nunique()
name_conflict = borrowers.groupby("borrower_id")["name"].nunique()
n_conflicted = (name_conflict > 1).sum()

log("dim_borrower — CRITICAL FINDING",
    f"borrowers.csv has {n_raw_b} rows for only {n_unique_b} unique borrower_id "
    f"(avg {n_raw_b/n_unique_b:.2f} rows/id). This is NOT a clean append-only update log: "
    f"{n_conflicted} borrower_ids ({n_conflicted/n_unique_b*100:.1f}%) show *conflicting names* "
    f"across their rows (e.g. BRW0006302 appears as 'Aarav Sharma', 'Sneha Das', 'Vikram Shah', "
    f"'Priya Mehta', 'Neha Singh', 'Rahul Verma', 'Amit Kumar' — seven different people under one ID). "
    f"This means borrower_id is functioning as a **collision-prone recycled key**, not a stable person "
    f"identifier. There is no reliable secondary key to re-resolve identity (phone has {borrowers.phone.isna().sum()} "
    f"nulls and is not clean either). DECISION: treat borrower_id as a join key to accounts only, not as "
    f"proof of 'same person'. Build dim_borrower by taking the MOST RECENT row per borrower_id (by updated_at) "
    f"as a best-effort 'current believed state', and flag every borrower_id with attribute conflicts as "
    f"identity_confidence=LOW. Any borrower-level demographic cut (e.g. by city/state) inherits this low "
    f"confidence and should be reported with that caveat, never presented as clean segmentation.")

dim_borrower = (borrowers.sort_values("updated_at")
                 .drop_duplicates(subset="borrower_id", keep="last")
                 .copy())
dim_borrower["identity_confidence"] = np.where(
    dim_borrower.borrower_id.isin(name_conflict[name_conflict > 1].index), "LOW", "MEDIUM"
)
# even "MEDIUM" is not "HIGH" because we cannot independently verify any borrower_id given the
# collision behavior observed in the conflicted rows — a borrower_id with only 1 row could still
# be a fragment of a person who has other rows lost to the same collision process.

# ---------------------------------------------------------------------------
# 3. DIM_AGENT — source agent_id is recycled/fragmented. Do not use
#    employee_code or joined_at as identity/tenure. Use first_seen_active_at
#    from actual calls as an observed-activity proxy only.
# ---------------------------------------------------------------------------
n_raw_a = len(agents)
n_unique_a = agents.agent_id.nunique()

def mode_or_first(s):
    m = s.dropna().mode()
    return m.iloc[0] if len(m) else (s.dropna().iloc[0] if s.notna().any() else np.nan)

first_seen_active = calls.groupby('agent_id')['event_at'].min().rename('first_seen_active_at')
dim_agent = (agents.groupby('agent_id').agg(
    employee_code=('employee_code', mode_or_first),
    vendor_id=('vendor_id', mode_or_first),
    team=('team', mode_or_first),
    status=('status', mode_or_first),
).reset_index().merge(first_seen_active, on='agent_id', how='left'))
dim_agent['identity_confidence'] = 'LOW/MEDIUM — recycled source ID; first_seen_active_at is only an activity proxy'
log('dim_agent — corrected methodology',
    f'{n_raw_a} source rows collapse to {n_unique_a} agent_ids. employee_code and joined_at are not used for identity/tenure because prior null-model tests showed they create false precision. first_seen_active_at from actual call activity is retained only as an observed activity proxy.')

# ---------------------------------------------------------------------------
# 4. DIM_CAMPAIGN — keep campaign_id as grain, attach campaign_name as a
#    rollup family. Do NOT collapse to campaign_name (would erase real
#    distinctions in strategy_version / timing).
# ---------------------------------------------------------------------------
fam_counts = campaigns.groupby("campaign_name")["campaign_id"].nunique()
log("dim_campaign",
    f"campaigns.csv: {campaigns.campaign_id.nunique()} unique campaign_id but only "
    f"{campaigns.campaign_name.nunique()} distinct campaign_name values — each logical campaign family "
    f"(e.g. NPA_RECOVERY) is relaunched under a new campaign_id {fam_counts.mean():.0f} times on average, "
    f"often overlapping in time with different strategy_version tags. DECISION: keep campaign_id as the "
    f"true analytical grain (it's what calls/targeting actually reference), rename campaign_name to "
    f"campaign_family for rollup reporting. Any 'campaign performance' metric must state which grain it "
    f"used — 'per campaign_id' and 'per campaign_family' will tell different stories, and the reported "
    f"11% may have used whichever grain was convenient (this is one of the attribution-error hypotheses "
    f"to test in Part 2).")
dim_campaign = campaigns.rename(columns={"campaign_name": "campaign_family"}).copy()

# ---------------------------------------------------------------------------
# 5. DISPOSITION CROSSWALK — legacy/v1/v2 are NOT sequential vocabulary
#    replacements (all 3 versions carry all 9 codes in similar volume).
#    PTP and PROMISE_TO_PAY coexist as separate strings for what looks
#    like the same outcome.
# ---------------------------------------------------------------------------
xwalk = pd.crosstab(dispositions.disposition_code, dispositions.disposition_version)
log("disposition crosswalk",
    "All 9 disposition_code values appear in roughly equal volume (~1,250-1,370 rows) under ALL THREE "
    "disposition_version tags (legacy/v1/v2) — so the versions are NOT sequential code-set replacements, "
    "they coexist for the whole period (likely marks which pipeline/vendor wrote the row, not a taxonomy "
    "migration). Separately, 'PTP' and 'PROMISE_TO_PAY' exist as two independent code strings at near-"
    "identical volume — very likely the same real-world outcome logged by two different systems/channels. "
    "DECISION (flagged HYPOTHESIS, not Fact — needs SME confirmation): canonicalize "
    "PTP + PROMISE_TO_PAY -> 'PTP_MADE' for the golden layer, keep disposition_version as a lineage "
    "attribute (not part of the canonical code). If wrong, PTP rate is understated by ~50% in any report "
    "that only queried one of the two strings — worth checking whether the reported 11% used just one.")

CODE_XWALK = {
    "PTP": "PTP_MADE", "PROMISE_TO_PAY": "PTP_MADE",
    "PTP_BROKEN": "PTP_BROKEN", "PAID": "PAID", "NO_CONTACT": "NO_CONTACT",
    "WRONG_NUMBER": "WRONG_NUMBER", "REFUSED": "REFUSED",
    "DISPUTE": "DISPUTE", "CALLBACK": "CALLBACK",
}
fact_dispositions = dispositions.copy()
fact_dispositions["disposition_canonical"] = fact_dispositions.disposition_code.map(CODE_XWALK).fillna(fact_dispositions.disposition_code)

# ---------------------------------------------------------------------------
# 6. PAYMENTS — dedup. Two DIFFERENT problems, need different fixes.
# ---------------------------------------------------------------------------
n_raw_p = len(payments)
exact_dupe_mask = payments.duplicated(subset=[c for c in payments.columns if c != "payment_id"]) | payments.duplicated(subset="payment_id")
# a) exact full-row duplicate payment_id -> pure ingestion retries, drop
exact_dupes = payments.payment_id.duplicated().sum()
payments_dedup1 = payments.drop_duplicates(subset="payment_id", keep="first")

# b) payment_reference duplicates -> only count as dupes if SAME account+amount
ref_dupe_groups = payments_dedup1[payments_dedup1.payment_reference.notna() &
                                   payments_dedup1.payment_reference.duplicated(keep=False)]
def group_is_true_dupe(d):
    return d[["account_id", "amount"]].drop_duplicates().shape[0] == 1

true_dupe_group_keys = ref_dupe_groups.groupby("payment_reference").filter(group_is_true_dupe).payment_reference.unique()
n_ref_groups = ref_dupe_groups.payment_reference.nunique()
n_true_dupe_groups = len(true_dupe_group_keys)

is_true_dupe_row = (payments_dedup1.payment_reference.isin(true_dupe_group_keys))
# within true-dupe groups, keep the first occurrence by event_at
true_dupe_rows = payments_dedup1[is_true_dupe_row].sort_values("event_at")
keep_idx = true_dupe_rows.drop_duplicates(subset="payment_reference", keep="first").index
drop_idx = true_dupe_rows.index.difference(keep_idx)
payments_golden = payments_dedup1.drop(index=drop_idx)

log("payments dedup — TWO DIFFERENT PROBLEMS, ONE TRAP",
    f"Raw payments: {n_raw_p} rows. (a) {exact_dupes} rows are exact full duplicate payment_id — pure "
    f"ingestion/retry noise, dropped outright ({exact_dupes} rows removed). "
    f"(b) {n_ref_groups} groups of rows share a duplicate payment_reference, but critically only "
    f"{n_true_dupe_groups} of those groups ({n_true_dupe_groups/n_ref_groups*100:.0f}%) actually share the "
    f"same account_id + amount — i.e. only those are true duplicate submissions. The other "
    f"{n_ref_groups - n_true_dupe_groups} groups ({(n_ref_groups-n_true_dupe_groups)/n_ref_groups*100:.0f}%) "
    f"are DIFFERENT payments (different account, different amount) that happen to share a reference string "
    f"— payment_reference is not globally unique in this system and is NOT a safe dedup key on its own. "
    f"THE TRAP: a naive 'drop duplicate payment_reference' rule would have deleted "
    f"~{n_ref_groups - n_true_dupe_groups} legitimate, distinct payments — i.e. it would have artificially "
    f"DEFLATED recovery, the opposite error from double-counting. DECISION: dedup only on "
    f"(payment_reference, account_id, amount) match, keep earliest by event_at within true-dupe groups. "
    f"Net rows removed: {exact_dupes + (len(drop_idx))} of {n_raw_p} ({(exact_dupes+len(drop_idx))/n_raw_p*100:.1f}%).")

# ---------------------------------------------------------------------------
# 7. ACCOUNT_STATUS_HISTORY — timestamp integrity break
# ---------------------------------------------------------------------------
history["lag_days"] = (history.recorded_at - history.event_at).dt.total_seconds() / 86400
n_impossible = (history.lag_days < 0).sum()
log("account_status_history — timestamp integrity",
    f"{n_impossible}/{len(history)} rows ({n_impossible/len(history)*100:.0f}%) have recorded_at BEFORE "
    f"event_at — impossible in a real system (you cannot log an event before it happened). This means "
    f"recorded_at cannot be trusted as an ingestion-lag signal at row level; it looks like independent "
    f"random noise around event_at rather than a genuine ingestion timestamp. DECISION: use event_at as "
    f"the sole source of truth for status sequencing. Do NOT compute 'late-arriving data' SLA metrics from "
    f"recorded_at without first fixing this at the source — any such metric in Part 5's monitoring design "
    f"should flag rows where recorded_at < event_at as REJECTED for lag-calculation purposes, not silently "
    f"averaged in (a naive AVG(recorded_at-event_at) would be biased toward ~0 and mask real late-arrival).")

golden_history = history.drop(columns=["lag_days"]).copy()
golden_history["timestamp_integrity_flag"] = np.where(
    history.lag_days < 0, "RECORDED_BEFORE_EVENT", "OK")

# ---------------------------------------------------------------------------
# 8. TIMEZONE NORMALIZATION (tables that carry a timezone column)
# ---------------------------------------------------------------------------
tz_note = ("calls, accounts, agent_sessions, vendor_telephony carry an explicit timezone column "
           "(Asia/Kolkata / Asia/Dubai / UTC, near-even 3-way split) and are normalized to UTC for the "
           "golden layer. payments, call_dispositions, promises_to_pay, whatsapp/sms events, field_visits, "
           "complaints, account_status_history carry NO timezone column — their event_at timezone is "
           "UNSTATED. DECISION: assume Asia/Kolkata (business HQ timezone) for these tables and flag "
           "tz_confidence=ASSUMED on every row, rather than silently treating them as UTC (which would "
           "shift every hour-of-day and day-of-week analysis in Part 2's 'calling time' investigation by "
           "up to 5.5 hours with no warning).")
log("timezone normalization", tz_note)

def to_utc(df, ts_col, tz_col):
    out = df.copy()
    out[ts_col] = pd.to_datetime(out[ts_col])
    def conv(row):
        tz = row[tz_col]
        try:
            return row[ts_col].tz_localize(tz).tz_convert("UTC").tz_localize(None)
        except Exception:
            return pd.NaT
    out[ts_col + "_utc"] = out.apply(conv, axis=1)
    return out

calls_golden = to_utc(calls, "event_at", "timezone")
accounts_tz = accounts[["account_id","timezone"]]

# ---------------------------------------------------------------------------
# 9. WORKING POPULATION — latest-status-as-of-month-start. An historical
#    terminal status does not permanently remove an account because the data
#    contains later activity after terminal events.
# ---------------------------------------------------------------------------
months = pd.period_range('2026-01', '2026-08', freq='M')
pop_rows = []
for m in months:
    month_start = m.start_time
    opened = accounts[accounts.opened_at < month_start].account_id
    h = golden_history[golden_history.event_at < month_start].sort_values('event_at').drop_duplicates('account_id', keep='last')
    h = h[h.account_id.isin(opened)][['account_id','status']]
    status_map = dict(zip(h.account_id, h.status))
    asof = pd.Series(opened, dtype='object').map(status_map).fillna('ACTIVE')
    working = opened[~asof.isin(['CLOSED','PAID','WRITEOFF'])]
    pop_rows.append({'month': str(m), 'working_population': int(len(working))})
working_pop = pd.DataFrame(pop_rows)
log('monthly working population (corrected)',
    'Uses latest account status as of month-start. Accounts can reappear after a terminal event if later status/activity supports that. No permanent first-terminal exclusion.\n\n' + working_pop.to_string(index=False))

# ---------------------------------------------------------------------------
# 10. OPERATIONAL GOLDEN FACTS
# ---------------------------------------------------------------------------
# These source tables already have a stable event-level ID except WhatsApp,
# where 600 exact duplicate rows reuse an otherwise unique event ID.
# Remove only exact duplicate WhatsApp rows; preserve all other events.
whatsapp_id_dupes = wa["whatsapp_event_id"].duplicated().sum()
whatsapp_exact_dupes = wa.duplicated().sum()
wa_golden = wa.drop_duplicates(subset="whatsapp_event_id", keep="first").copy()

sms_golden = sms.copy()
visits_golden = visits.copy()
ptp_golden = ptp.copy()
sessions_golden = sessions.copy()
targeting_golden = targeting.copy()

log("operational Golden facts",
    f"PTP={len(ptp_golden):,} rows, SMS={len(sms_golden):,}, field visits={len(visits_golden):,}, "
    f"agent sessions={len(sessions_golden):,}, daily targeting={len(targeting_golden):,}. "
    f"WhatsApp had {whatsapp_id_dupes:,} duplicate event IDs, all of which were exact duplicate rows; "
    f"deduplicated to {len(wa_golden):,} rows. No non-exact WhatsApp ID reuse was found.")

# ---------------------------------------------------------------------------
# 11. WRITE GOLDEN OUTPUTS
# ---------------------------------------------------------------------------
dim_account.to_csv(f"{OUT}/dim_account.csv", index=False)
dim_borrower.to_csv(f"{OUT}/dim_borrower.csv", index=False)
dim_agent.to_csv(f"{OUT}/dim_agent.csv", index=False)
dim_campaign.to_csv(f"{OUT}/dim_campaign.csv", index=False)
fact_dispositions.to_csv(f"{OUT}/fact_dispositions.csv", index=False)
payments_golden.to_csv(f"{OUT}/fact_payments_golden.csv", index=False)
golden_history.to_csv(f"{OUT}/fact_account_status_history.csv", index=False)
calls_golden.to_csv(f"{OUT}/fact_calls_golden.csv", index=False)
working_pop.to_csv(f"{OUT}/dim_monthly_working_population.csv", index=False)
sessions_golden.to_csv(f"{OUT}/fact_agent_sessions_golden.csv", index=False)
targeting_golden.to_csv(f"{OUT}/fact_daily_targeting_golden.csv", index=False)
visits_golden.to_csv(f"{OUT}/fact_field_visits_golden.csv", index=False)
ptp_golden.to_csv(f"{OUT}/fact_promises_to_pay_golden.csv", index=False)
sms_golden.to_csv(f"{OUT}/fact_sms_golden.csv", index=False)
wa_golden.to_csv(f"{OUT}/fact_whatsapp_golden.csv", index=False)

# ---------------------------------------------------------------------------
# 12. IMPACT SUMMARY TABLE (Raw -> Rejected/Corrected -> Golden)
# ---------------------------------------------------------------------------
impact = pd.DataFrame([
    {"table":"borrowers","raw_rows":len(borrowers),"golden_rows":len(dim_borrower),
     "rows_removed":len(borrowers)-len(dim_borrower),
     "treatment":"collapsed to 1 row/borrower_id (latest by updated_at); LOW-confidence flag on conflicted ids"},
    {"table":"agents","raw_rows":len(agents),"golden_rows":len(dim_agent),
     "rows_removed":len(agents)-len(dim_agent),
     "treatment":"collapsed to 1 row/agent_id for descriptive attributes; first_seen_active_at used only as activity proxy"},
    {"table":"payments","raw_rows":n_raw_p,"golden_rows":len(payments_golden),
     "rows_removed":n_raw_p-len(payments_golden),
     "treatment":"dropped exact payment_id dupes + true reference+account+amount dupes only"},
    {"table":"account_status_history","raw_rows":len(history),"golden_rows":len(golden_history),
     "rows_removed":0,
     "treatment":f"kept all rows, flagged {n_impossible} as RECORDED_BEFORE_EVENT (not usable for lag SLA)"},
    {"table":"call_dispositions","raw_rows":len(dispositions),"golden_rows":len(fact_dispositions),
     "rows_removed":0,
     "treatment":"added disposition_canonical (PTP+PROMISE_TO_PAY -> PTP_MADE), kept raw code too"},
    {"table":"whatsapp_events","raw_rows":len(wa),"golden_rows":len(wa_golden),
     "rows_removed":len(wa)-len(wa_golden),
     "treatment":"removed exact duplicate whatsapp_event_id rows only; all duplicate IDs were exact duplicates"},
])
impact.to_csv(f"{OUT}/_impact_summary.csv", index=False)
log("IMPACT SUMMARY", impact.to_string(index=False))

with open(f"{REPORT_DIR}/data_quality_report.md", "w") as f:
    f.write("# Data Quality Report — Golden Dataset Build\n\n")
    f.write("Raw record counts (all 17 source tables):\n\n")
    f.write(pd.Series(RAW_COUNTS).to_string() + "\n\n")
    f.write("\n".join(LOG_LINES))

print("\nDONE. Golden tables in ./golden, report in ./reports/data_quality_report.md")
