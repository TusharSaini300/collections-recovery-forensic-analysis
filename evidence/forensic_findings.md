# Forensic Findings & Reconciliation Bridge — Pass 2
Builds on `data_quality_report.md`. This file covers what was completed in this
pass: time-series shape, Simpson's paradox test, attribution sensitivity, and
the partial reconciliation bridge. Classification tags (FACT / STRONG EVIDENCE /
CORRELATION / HYPOTHESIS) are applied per-line, not per-section.

---

## 1. The central finding of this pass

**Gross recovery (₹) has no statistically significant trend, Jan–Jul, in
aggregate or within any DPD bucket.** Linear regression of monthly gross
recovery against month index:

| Cut | Slope (₹/month) | r | p-value | Significant? |
|---|---|---|---|---|
| Aggregate | +221,852 | 0.06 | 0.891 | No |
| DPD 0–30 | -202,250 | -0.08 | 0.859 | No |
| DPD 31–60 | +117,262 | 0.14 | 0.765 | No |
| DPD 61–90 | +249,649 | 0.29 | 0.532 | No |
| DPD 90+ | +57,190 | 0.06 | 0.904 | No |
| **recovery_per_working_account (ratio)** | **+549/month** | **0.97** | **0.0002** | **Yes** |

**FACT.** The money actually recovered each month is flat noise around a
constant mean — in aggregate and inside every DPD bucket independently. The
only series that shows a real, statistically strong upward trend is the
*ratio* — recovery divided by the (shrinking) working population.

**STRONG EVIDENCE**, not yet FACT, that this is a **denominator artifact**,
not operational improvement: the numerator isn't moving in any subgroup, so a
rising ratio can only come from the denominator shrinking faster than the
numerator holds steady. This is short of FACT because it hasn't been
confirmed against a cohort-tracked (not population-tracked) view (Part 8,
still open — see status table) — a true cohort curve is the last check that
could still overturn this.

This directly answers Part 10 (Simpson's paradox): **the aggregate ratio
"improves" while every within-DPD-bucket gross-recovery trend is flat** — the
textbook shape of the paradox. Flagged explicitly, not assumed.

---

## 2. Time-series shape (Part 12) — it is not "steady MoM improvement"

Recovery-per-working-account, Jan–Jul (Aug excluded, partial month):

| Month | Value | MoM% |
|---|---|---|
| Jan | 6,241 | — |
| Feb | 6,340 | +1.6% |
| Mar | 7,659 | **+20.8%** |
| Apr | 7,664 | +0.1% |
| May | 8,592 | **+12.1%** |
| Jun | 8,621 | +0.3% |
| Jul | 9,532 | **+10.6%** |

**FACT.** This is a step function — jump, plateau, jump, plateau — not a
smooth monthly climb. An exhaustive 2-segment mean-shift scan found the
strongest structural break sits right after February (standardized effect
size 3.03 — before-mean 6,290, after-mean 8,414).

**HYPOTHESIS, currently unresolved.** Checked whether the jump months
(Mar/May/Jul) coincide with campaign launches, targeting-priority shifts, or
recommended-channel mix changes in `daily_targeting` / `campaigns` — found
nothing: campaign launch volume, channel-recommendation mix, and average
targeting priority are all flat and unremarkable across these months. The
alternating jump/plateau cadence is real and reproducible but **its cause is
not yet identified** in this data. Given Section 1's finding, the leading
candidate explanation is that the *population denominator* itself declines in
a similarly steppy pattern (worth checking directly — not yet done), which
would mean the "jumps" are exit-event timing artifacts, not recovery events.
Do not report this pattern as an operational cadence (e.g. "campaigns launched
bimonthly work better") without that check.

Practical conclusion for the memo: **"11% MoM improvement" is not an accurate
description of this series either before or after correction** — the reported
number reads like a single favorable month-pair, and the corrected version is
a lumpy step pattern, not a rate.

---

## 3. Attribution sensitivity (Part 4) — closed

Compared last-touch (unlimited lookback) against 30/14/7-day capped lookback
windows for every successful payment.

| Model | Match rate | CALL | WHATSAPP | SMS | FIELD |
|---|---|---|---|---|---|
| Last-touch (unlimited) | 86.0% | 41.1% (#1) | 27.2% (#2) | 20.5% (#3) | 11.1% (#4) |
| Lookback 30d | 59.8% | 40.8% (#1) | 26.8% (#2) | 20.7% (#3) | 11.6% (#4) |
| Lookback 14d | 36.0% | 40.6% (#1) | 26.8% (#2) | 20.9% (#3) | 11.7% (#4) |
| Lookback 7d | 20.2% | 42.1% (#1) | 26.1% (#2) | 20.7% (#3) | 11.1% (#4) |

**FACT.** Channel ranking (CALL > WHATSAPP > SMS > FIELD) and each channel's
recovery share are stable within ~1.5 points across every window choice.
Attribution-model choice is **not** a material source of distortion for
channel-level conclusions — answers Part 4's questions A–C: rankings don't
change, campaign-level re-run not yet done (same method, not yet applied at
campaign_id grain — OPEN), total attributed recovery doesn't materially move.

**FACT, separate and important finding not in the original ask:** match rate
collapses from 86% → 20% as the window tightens from unlimited to 7 days. Most
successful payments do **not** have a logged touch within 7–14 days of the
payment. This matters directly for Part 11 (PTP-kept / conversion metrics
under different windows) — a tight window will make PTP-kept and
channel-conversion rates look artificially low not because kept-rate
performance changed, but because the window excludes genuine but slower-than-7-day
conversions. Any such metric needs its window choice disclosed prominently
per the brief's own instruction.

---

## 4. Data insufficiency — confirmed, not assumed (relevant to Part 6 & 15)

Checked the full 17-table schema against `data_dictionary.csv`: **no
`client` field and no `language` field exist anywhere in this dataset.** Two
of the 13 required driver dimensions (client, language) cannot be analyzed
with the data provided — this is a genuine gap, not an oversight to fix later.
Geography is analyzable only via `borrowers.city` / `borrowers.state`, and
inherits `dim_borrower`'s LOW identity-confidence flag from Part 1 — any
geography-cut driver conclusion is capped at CORRELATION even before
confounder-testing, because the underlying borrower attribution itself is
uncertain for 74% of borrower_ids.

---

## 5. Reconciliation bridge — PARTIAL, built honestly from what's actually done

| Step | Metric basis | Value vs. previous step | Classification | Evidence |
|---|---|---|---|---|
| **Reported** | "Recovery improved 11% MoM" (leadership's stated basis unknown — not disclosed in brief) | — | — | Business claim, unverified basis |
| **Dedup corrected** | Gross recovery, exact + true reference dupes removed | -2.0% of raw payment rows removed; dollar impact on gross monthly totals is small (~2% of row count, mostly low-value retries — exact ₹ impact not yet computed per month) | FACT | 500/25,500 exact dupes; 0/3,406 reference-collision groups were true dupes |
| **Denominator corrected** | recovery_per_working_account, buggy pop. vs. corrected pop. | Jul: 12,680 → 9,532 (-24.8%); Jan: unchanged (no accounts old enough to be affected yet) | FACT | Reactivation bug quantified in `data_quality_report.md` — 30% of accounts affected |
| **Attribution adjustment** | Channel-level recovery under last-touch vs. lookback | No material change (<1.5pp shift in any channel's share) | FACT | Section 3 above |
| **Mix adjustment (DPD/segment)** | Direct standardization vs. Jan reference mix | **NOT YET COMPUTED** | — | OPEN — see status table |
| **Cohort adjustment** | Fixed opening-cohort tracking vs. population tracking | **NOT YET COMPUTED** | — | OPEN — see status table |
| **True like-for-like change** | — | **NOT YET DETERMINED** | — | Depends on the two open rows above |

**What can already be said, even with the bridge incomplete:** the gross,
undeduped, unattributed, un-mix-adjusted number — the actual ₹ collected each
month — is flat with no significant trend (Section 1). Every adjustment step
run so far (dedup, denominator, attribution) either makes negligible
difference or *reduces* the apparent improvement (the denominator fix alone
cut the ratio's Jul growth from +103% to +53% vs. Jan). Nothing found so far
points toward the 11% claim being real; everything found so far points toward
it being an artifact of an unstated metric definition on a flat underlying
series. That said — the two most important remaining checks (mix
standardization, cohort curves) are exactly the ones that could most
plausibly still find a genuine pocket of real improvement hiding inside a
flat aggregate, so the bridge is not finished and the memo should not close
this out yet.

---

## 6. Status — COMPLETE / OPEN (honest accounting)

| Phase | Status | Evidence / what remains |
|---|---|---|
| P0 Raw profiling | **COMPLETE** | All 17 tables profiled: row counts, grain, key cardinality, nulls, timezones |
| P1 Golden Dataset | **COMPLETE for 7 of 17 tables** | dim_account, dim_borrower, dim_agent, dim_campaign, fact_dispositions, fact_payments_golden, fact_account_status_history built and audited. `agent_sessions`, `call_attempts`, `daily_targeting`, `whatsapp_events`, `sms_events`, `field_visits`, `promises_to_pay`, `complaints`, `vendor_telephony` loaded and used ad hoc in forensics queries but **not yet formally cleaned/exported as golden tables** — OPEN if the SQL/notebook deliverable needs all 17 |
| P2A Duplicate payments | **COMPLETE** | Section 3 of `data_quality_report.md`; 60-min-window broadened check found nothing beyond exact dupes |
| P2B Attribution | **COMPLETE** | Section 3 above — last-touch vs. 3 lookback windows, channel-level only. Campaign-level re-run under same models is OPEN |
| P2C Timezone | **COMPLETE** | Local vs. UTC "best hour" comparison, prior pass |
| P2D Vendor mapping | **OPEN — coarse pass only** | PAID-share by vendor/month checked, no step-change found; full per-code, per-vendor changepoint test (as required) not yet run |
| P2E Agent identity | **COMPLETE** | Fragmentation confirmed and resolved; employee_code/joined_at dropped as unrecoverable, documented with statistical tests |
| P2F Portfolio mix | **OPEN — single-dimension only** | risk_segment and DPD individually shown flat; **joint** DPD × segment × geography distribution (as required) not yet built |
| P2G Denominator | **COMPLETE** | Reactivation bug found, quantified (30% of accounts), fixed, re-validated |
| P3 Independent metrics | **OPEN** | Only recovery_per_working_account has been formally rebuilt; contact rate, RPC, PTP rate/kept rate, recovery/agent-hour, cost/₹ recovered are not yet redefined (Part 14) |
| Mix adjustment | **OPEN** | Direct standardization not yet run — this is the single most important open item given Section 1's finding |
| Cohort analysis | **OPEN** | No cohort curves built yet — the other check that could overturn Section 1's conclusion |
| Simpson's paradox | **COMPLETE for DPD bucket** | Section 1 above, with formal significance testing. Channel and risk-segment cuts not yet run with the same rigor — partially open |
| P4 Driver analysis | **OPEN** | Not started. Blocked on P3/mix/cohort completing first, per the assignment's own dependency order |
| P5 Counterfactual | **OPEN** | Not started. Also blocked — the targeting-change date itself hasn't been located in the data yet (Section 2's campaign/targeting check found no clear shift) |
| P6 ₹10 Cr recommendation | **NOT ATTEMPTED, correctly** | Per instruction — P3–P5 aren't done, so no lever is recommended yet |

**Bottom line:** the highest-value finding from this pass is that gross
recovery shows no real trend anywhere it's been sliced so far, and the
reported "improvement" so far looks like a denominator artifact — but that
conclusion is not yet FACT because mix-adjustment and cohort-tracking (the
two checks most likely to surface a real pocket of improvement hiding in a
flat aggregate) haven't been run. Those are the correct next steps, not
driver analysis or the counterfactual, which the brief's own dependency chain
says come later.
