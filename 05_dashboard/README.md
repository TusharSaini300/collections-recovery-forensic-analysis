# Power BI Executive Dashboard

The primary dashboard deliverable should be a **Power BI Desktop `.pbix` file** built from this package.

## Files
- `pbi_monthly_metrics.csv` — monthly dashboard model.
- `pbi_forensic_facts.csv` — forensic evidence table.
- `POWER_BI_BUILD_SPEC.md` — exact one-page layout.
- `POWER_BI_DAX_MEASURES.txt` — DAX measures.
- `power_bi_model_schema.csv` — field guide.

## Headline claim bridge

The dashboard should explicitly show that the reported ~11% can be reproduced as **Feb→Mar gross recovery: ₹17.01 Cr → ₹18.89 Cr = +11.03%**. The exact leadership KPI definition is still unverified because the supplied brief does not disclose the numerator, denominator, or attribution rule.

## Build
1. Open Power BI Desktop.
2. Get Data → Text/CSV → import `pbi_monthly_metrics.csv`; rename table **Monthly Metrics**.
3. Import `pbi_forensic_facts.csv`; rename **Forensic Facts**.
4. Create the measures in `POWER_BI_DAX_MEASURES.txt`.
5. Build the one-page Executive Overview exactly as specified.
6. Save as `Collections_Recovery_Dashboard.pbix`.

Do not use the previous HTML dashboard as the primary submission artifact.
