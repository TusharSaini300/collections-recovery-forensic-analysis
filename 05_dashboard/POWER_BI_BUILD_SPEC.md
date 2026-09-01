# Power BI Dashboard — Build Specification

## Objective
Create the one-page executive dashboard required by the assignment. The page should answer, in order:

1. What happened?
2. Is the reported +11% improvement real?
3. What explains the apparent improvement?
4. Is the conclusion robust?
5. What should leadership do?

## Data
Import `pbi_monthly_metrics.csv` as **Monthly Metrics**.
Import `pbi_forensic_facts.csv` as **Forensic Facts**.

These are presentation-ready tables derived from the committed Golden Dataset/evidence layer.

## Page layout — 16:9, one page

### Header
**Collections Recovery — Is the 11% Real?**

Subtitle:
`CEO view · Complete Jan–Jul months · August excluded from trend conclusions`

Add a prominent text box:
**DECISION: HOLD ₹10 Cr**

### KPI row
1. **Leadership claim** — `11%` — supporting text `Feb→Mar = +11.03%` — label `UNVERIFIED`
2. **Corrected recovery/account** — `-0.2% Jan→Jul`
3. **Mix + cohort robustness** — `~0%`
4. **Investment decision** — `HOLD ₹10 Cr`

### Main visual A
Line chart:
- Axis: `month_label`
- Values: `gross_recovery_cr`, `working_recovery_cr`
- Title: **Gross recovery vs working-population recovery**
- Subtitle: `Gross recovery remains broadly flat; denominator correction changes the interpretation.`
- Legend labels: `Gross Recovery`, `Working-Population Recovery`
- X-axis labels: `Jan, Feb, Mar, Apr, May, Jun, Jul`
- Y-axis: ₹ Cr

Purpose: show that gross recovery does not support the headline ratio story.

### Main visual B
Line chart:
- Axis: `month_label`
- Values:
  - `raw_recovery_per_account`
  - `jan_mix_recovery_per_account`
  - `fixed_jan_cohort_recovery_per_account`
- Title: **Recovery / Account: Robustness Checks**
- Subtitle: `Mix-adjusted and fixed-cohort checks remain effectively flat.`
- Legend labels: `Corrected`, `Jan Mix Standardized`, `Fixed Jan Cohort`
- X-axis labels: `Jan, Feb, Mar, Apr, May, Jun, Jul`
- Y-axis: ₹ per account

Purpose: demonstrate convergence of the corrected, mix-adjusted and fixed-cohort views.

### Bottom-left
Table from **Forensic Facts**:
- Check
- Finding
- Evidence class
- Interpretation

### Bottom-right
Text / cards:
**Hold the ₹10 Cr commitment.**

Next action:
- Randomize eligible accounts within DPD × risk × geography strata.
- Primary KPI: incremental recovered ₹ per eligible account.
- Secondary KPIs: recovery rate, cost/₹ recovered, complaints, confidence interval.
- Scale only if measured lift and downside case clear the investment hurdle.

### Footnote
`FACT = directly observed/reconstructed · STRONG EVIDENCE = survives robustness checks · CORRELATION = observational association · HYPOTHESIS = unresolved. August excluded from Jan–Jul trend conclusions.`

## Formatting
- White/light neutral canvas.
- One-page executive layout.
- No pie charts.
- No decorative visuals.
- No more than one optional slicer (Month), default Jan–Jul.
- Keep decision visible without scrolling.
- Use consistent ₹ and % formatting.


## Headline-claim bridge
The dashboard must make the reported number directly auditable:

- Reported claim: approximately `11% MoM`.
- Independently reproducible gross-recovery bridge: **Feb ₹17.01 Cr → Mar ₹18.89 Cr = +11.03%**.
- Corrected recovery/account also gives **Feb ₹5,618 → Mar ₹6,277 = +11.73%**.
- Because the supplied brief does not specify the leadership numerator/denominator/attribution rule, the exact source of the reported 11% remains **UNVERIFIED**.
- The full Jan→Jul like-for-like checks remain effectively flat.

This bridge should appear in the leadership-claim KPI supporting text or in the forensic evidence table.
