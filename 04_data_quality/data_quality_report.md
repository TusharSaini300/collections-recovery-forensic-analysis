# Data Quality Report

## Headline claim audit
The reported `~11% MoM` is arithmetically reproducible as **Feb→Mar gross recovery: ₹17.01 Cr → ₹18.89 Cr = +11.03%**. A second plausible KPI, corrected recovery/account, gives **+11.73%** over the same month pair. Because the supplied brief does not disclose the exact numerator, denominator, attribution rule or window used by leadership, the claim's precise metric basis remains **UNVERIFIED**.

## Executive summary
The dataset contains structural issues capable of distorting collections KPIs. The most material is the working-population denominator rule: accounts can show activity after an earlier terminal status.

| Issue | Detection | Treatment | Business impact |
|---|---|---|---|
| Duplicate payment IDs | payment_id uniqueness | remove exact duplicates | ₹25.90m duplicate SUCCESS recovery removed across full period |
| Reference collisions | reference grouped by account/amount | do not dedup reference alone | avoids deleting legitimate payments |
| Borrower collisions | conflicting names per borrower_id | latest state + confidence flag | borrower cuts are lower confidence |
| Agent fragmentation | repeated/inconsistent agent attributes | descriptive mode + activity proxy | agent/tenure ranking not decision-grade |
| Status timestamp anomaly | recorded_at < event_at | use event_at for lifecycle sequencing | prevents false late-arrival metrics |
| Terminal reactivation | later activity after terminal event | latest status as of month-start | fixes denominator bias |
| PTP kept mismatch | raw status vs payment ledger | payment-based KPI with disclosed window | raw kept rate materially overstated |

## Denominator correction
7,758 of 25,999 affected accounts (~30%) show activity after a terminal-status event. The old permanent-exclusion rule was therefore invalid.

## Remaining limitations
Client and language are absent; historical targeting intervention/control is not identifiable; borrower/agent IDs are imperfect; PTP kept definition needs SME confirmation.
