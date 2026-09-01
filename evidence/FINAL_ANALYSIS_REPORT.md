# Collections Recovery — Independent Analysis Progress

## Executive conclusion at current stage

The reported **"11% month-on-month recovery improvement" is not supported by the current evidence**. The strongest current evidence is that the apparent increase in recovery per working account is driven by a shrinking denominator and, importantly, by a numerator/denominator mismatch: an increasing share of monthly payments comes from accounts that were already outside the working population at month-start.

This is **not yet a causal conclusion** about the business. The data does not contain a clean observed targeting-strategy change or the cost inputs needed for a defensible ₹10 Cr ROI calculation.

## P0-P2 status

- Raw profiling: complete.
- Golden-layer audit: corrected agent-tenure and working-population logic; payment deduplication independently validated.
- Duplicate payments: 500 exact payment_id duplicates removed; broader same-account/same-amount/60-minute check found no additional duplicates.
- Attribution: last-touch vs 30/14/7-day lookback produces stable channel rankings; campaign-level attribution remains a minor open item.
- Timezone: no material change to best-hour conclusions.
- Agent identity: fragmented IDs; first-seen activity is used only as a tenure proxy.
- Vendor mapping: no evidence of a material code-distribution shift yet; coarse PAID-share analysis is not sufficient, but code-level testing is now complete enough to find no systematic vendor-month drift.
- Portfolio mix: highly stable on DPD/risk/geography; direct standardization confirms mix is not explaining the headline trend.
- Denominator: historical terminal status was not treated as permanently terminal; latest status as-of month-start is used, with no-history accounts treated as active. This corrected a material denominator bias.

## P3 — Independent metric reconstruction

### Monthly gross recovery and denominator

| Month | Gross recovery ₹Cr | Working population | Gross recovery / working account | MoM |
|---|---:|---:|---:|---:|
| Jan | 18.72 | 30,000 | ₹6,241 | — |
| Feb | 17.01 | 26,838 | ₹6,340 | +1.6% |
| Mar | 18.89 | 24,667 | ₹7,659 | +20.8% |
| Apr | 17.51 | 22,852 | ₹7,664 | +0.1% |
| May | 18.43 | 21,444 | ₹8,592 | +12.1% |
| Jun | 17.56 | 20,364 | ₹8,621 | +0.3% |
| Jul | 18.72 | 19,643 | ₹9,532 | +10.6% |

August is partial and excluded from trend conclusions.

Gross recovery has no detectable linear trend over Jan-Jul (slope ≈ ₹0.22m/month, r=0.06, p=0.891). Gross recovery therefore does not support a sustained +11% operational improvement.

The ratio has a strong upward trend (slope ≈ ₹549/month, r=0.97, p=0.0002), but this is primarily a denominator effect.

### Numerator / denominator mismatch

When recovery is restricted to accounts that were actually in the working population at month-start:

| Month | Working-account recovery ₹Cr | Recovery / working account |
|---|---:|---:|
| Jan | 18.72 | ₹6,241 |
| Feb | 15.08 | ₹5,618 |
| Mar | 15.48 | ₹6,277 |
| Apr | 13.37 | ₹5,852 |
| May | 13.24 | ₹6,174 |
| Jun | 11.73 | ₹5,761 |
| Jul | 12.24 | ₹6,230 |

Jan → Jul: **-0.2%**, effectively flat.

By July, **₹64.9m / 34.6% of gross monthly recovery came from accounts that were not in the working population at month-start**. This makes gross recovery divided by current working population a poor operational-efficiency measure.

### Mix standardization

Direct standardization against January's joint `DPD × risk_segment × geography` mix gives:

| Month | Raw recovery/account | Jan-mix standardized recovery/account |
|---|---:|---:|
| Jan | ₹6,241 | ₹6,241 |
| Feb | ₹5,618 | ₹5,622 |
| Mar | ₹6,277 | ₹6,274 |
| Apr | ₹5,852 | ₹5,851 |
| May | ₹6,174 | ₹6,180 |
| Jun | ₹5,761 | ₹5,758 |
| Jul | ₹6,230 | ₹6,241 |

The standardized Jan → Jul change is approximately **0%**.

A second standardization using the overall Jan-Jul mix gives the same conclusion. Mix therefore does not explain the headline improvement.

### Fixed January cohort

Tracking the original January working cohort with a fixed 30,000-account denominator produces monthly recovery/account of approximately:

`₹6,241, ₹5,671, ₹6,297, ₹5,838, ₹6,142, ₹5,852, ₹6,241`

The trend slope is approximately ₹7/account/month with p=0.891. This is strong evidence against a genuine broad operational improvement.

### Survivorship

Monthly working-population exits are roughly 10% each month, with PAID/CLOSED/WRITEOFF each accounting for about one-third of terminal exits. Exit rates are also very similar by starting DPD and risk segment:

- DPD exit rates: ~10.2%–10.4% across buckets.
- Risk-segment exit rates: ~10.1%–10.4%.

There is therefore **no strong evidence that the population is becoming easier solely because high-risk/high-DPD accounts disproportionately disappear**. The denominator still changes materially, but the evidence does not show a large DPD/risk-selective exit mechanism.

## P3 metric integrity findings

### Contact / RPC / PTP

The independently reconstructed funnel is broadly flat:

- Contact rate: ~32%–35%, no significant trend.
- RPC rate on working population: ~10.7%–12.0%, no significant trend.
- RPC among contacted accounts: ~33%–35%, no significant trend.
- PTP rate on working population: ~7.2%–8.3%, no significant trend.
- Recovery per agent-hour: ~₹16.1k–₹17.0k, no significant trend.

### PTP kept-rate problem

The raw `promises_to_pay.status = KEPT` field labels approximately **24.9%** of PTPs as kept.

An independent payment-based reconstruction finds only about:

- **3.6%** had any successful payment by the promised date.
- **2.4%** met the promised amount by the promised date.
- **5.4%** had any payment by promised date + 7 days.
- **3.6%** met the promised amount by promised date + 7 days.

This is a material metric-integrity issue. The raw PTP status field should not be used as the final definition of PTP kept rate without validation.

## P2B Attribution

Last-touch and 30/14/7-day lookback attribution preserve the same channel ranking:

**CALL > WHATSAPP > SMS > FIELD**

Channel recovery shares move by less than ~1.5 percentage points across windows. Therefore attribution-window choice does not materially change the channel ranking.

However, match rate falls from **86.0% under unlimited lookback to 20.2% under 7 days**. This means tight attribution windows exclude a large fraction of successful payments and can materially distort PTP-kept/channel-conversion metrics.

Campaign-level attribution remains an open robustness check.

## P2D Vendor mapping

A vendor × month × disposition-code analysis finds no systematic code-distribution shift. Global month × disposition-code variation is not statistically significant (p≈0.45), and the disposition-version distributions are nearly identical.

A few individual vendor tests produce nominal p<0.05, but after considering multiple testing and the absence of a coherent date-boundary/code migration pattern, there is no evidence for a systematic vendor mapping change.

Conclusion: **no material vendor-code drift detected**, but retain raw disposition version/code for lineage.

## P4 Driver analysis

### Strongest descriptive dimensions

- DPD: recovery/account varies modestly across buckets; 31–60 is highest and 90+ lowest.
- Risk segment: recovery/account differences are small.
- Geography: Rajasthan is highest and Karnataka lowest, but geography inherits borrower identity uncertainty.
- Loan type: Consumer is highest and BNPL lowest.
- Channel exposure: accounts receiving calls/WhatsApp/SMS/field interactions have lower observed recovery than unexposed accounts. This is **not evidence that the channels hurt recovery**; it is classic selection/reverse-causality: harder accounts are more likely to be worked.
- Attempt frequency: higher attempts are negatively associated with recovery in raw and adjusted models. Again, this is consistent with harder accounts receiving more attempts and should not be interpreted causally.
- Campaign family: after controlling for month, DPD, risk, geography and loan type, campaign-family coefficients are small and statistically non-significant.
- Vendor: no vendor has a statistically reliable adjusted recovery advantage.
- Recommended channel: after controls, differences are small and statistically non-significant.
- Agent: agent IDs are fragmented/recycled; individual-agent ranking is not decision-grade without HR/identity source data.
- Agent tenure: only first-seen activity is available as a proxy, not true tenure.
- Calling time: no material time-of-day driver detected.
- Client: unavailable.
- Language: unavailable.

### Driver conclusion

There is currently **no causally supported operational lever** explaining the apparent 11% improvement.

The strongest evidence points toward a metric/population artifact rather than an operational lift.

## P5 Counterfactual

The data does **not provide a clean observable mid-year targeting-strategy change**.

Targeting diagnostics show:

- targeting priority is stable across months;
- recommended-channel shares are stable;
- targeting status shares are stable;
- campaign strategy-version mix is stable;
- DPD/risk mix of targeted accounts is broadly stable.

Therefore a conventional DiD estimate cannot honestly be produced from the current data because there is no defensible treatment/control transition.

### Required methodology if the actual targeting change is supplied

1. Identify exact change date and changed rule.
2. Treatment = newly prioritized accounts/segments.
3. Control = accounts/segments whose targeting rules did not change.
4. Test pre-period parallel trends.
5. Run DiD:

`(Treatment post - Treatment pre) - (Control post - Control pre)`

6. Control for seasonality, campaign launches, staffing changes and portfolio inflow.
7. Use propensity matching as robustness check if treatment/control differ materially.
8. If parallel trends fail or no untouched control exists, do not report a causal estimate.

## P6 ₹10 Cr decision

A defensible ROI recommendation **cannot currently be made**.

The dataset lacks direct cost inputs for:

- telephony infrastructure
- agent hiring/compensation
- AI voice
- WhatsApp/digital engagement
- field operations

It also lacks a clean causal estimate for incremental recovery from any of those levers.

Current evidence:

- telephony vendors: no reliable advantage;
- additional contact attempts: negative observational association, likely selection;
- channels: stable attribution but no causal lift;
- targeting: no identifiable strategy change and no DiD treatment/control;
- agent productivity: recovery/hour is flat;
- PTP kept metric: raw status field is unreliable.

### Recommendation

**Do not allocate the full ₹10 Cr on the basis of this historical dataset.**

If leadership requires a next action, run a controlled targeting experiment before committing the full amount because targeting is the most directly testable lever in the assignment's counterfactual framework.

Do not present this as a positive-ROI investment recommendation. It is an experiment recommendation.

### Experiment design

- Stratify by DPD × risk × geography.
- Randomly assign eligible accounts to current targeting vs. proposed targeting.
- Keep agent capacity, channel availability and observation windows controlled.
- Primary outcome: incremental recovered ₹ per eligible account.
- Secondary outcomes: recovery rate, recovery/account, cost/₹ recovered, complaints.
- Pre-register attribution and payment windows.
- Estimate confidence interval around incremental recovery.
- Scale only if the lower bound of the incremental recovery distribution supports the required return.

## P7 Production architecture

```text
RAW
  ↓
STAGING
  ↓
CLEAN
  ↓
GOLDEN
  ↓
FEATURE
  ↓
METRICS
  ↓
EXECUTIVE DASHBOARD
```

### Raw
Immutable source copies. Preserve original timestamps and source identifiers.

### Staging
Schema conformance, ingestion-grain deduplication, null/type validation. Violations quarantined.

### Clean
Timezone normalization, identity resolution, standardized dispositions, explicit business rules with rule IDs.

### Golden
One reconciled entity representation for accounts, agents and payments. Version late-arriving corrections instead of silently overwriting history.

### Feature
Point-in-time-correct features: DPD buckets, contact attempts, agent-hours, channel exposure, PTP and payment features.

### Metrics
Version-controlled definitions. Metric changes require review rather than silent query changes.

### Monitoring
- row-count checks;
- null-rate checks;
- uniqueness/referential-integrity checks;
- payment-to-settlement reconciliation;
- recorded_at < event_at anomaly monitoring;
- headline metric anomaly alerts.

## P8 Final deliverable status

| Deliverable | Status |
|---|---|
| SQL repository | Partially complete; P3/P4 SQL should be consolidated |
| Analysis notebook | Needs consolidation into a narrated final notebook |
| Golden dataset/pipeline | Core entities complete; remaining event tables need formal golden treatment if required |
| Data quality report | Substantially complete; update with P3 findings |
| Executive dashboard | Draftable now, but final headline should wait for memo sign-off |
| Executive memo | Can now be drafted with the current conclusion and explicit limitations |
| Architecture diagram | Design complete; needs final visual rendering |

## Evidence classification for current conclusion

**FACT:** gross recovery is not trending over Jan-Jul; the working population shrinks; payment-based PTP kept rates materially disagree with the raw PTP status field; mix-standardized recovery is flat; targeting composition shows no clean mid-year change.

**STRONG EVIDENCE:** the reported recovery/account improvement is primarily a denominator/population artifact rather than broad operational improvement.

**CORRELATION:** geography, loan type, DPD and channel exposure are associated with recovery differences.

**HYPOTHESIS:** the exact cause of the stepwise March/May/July ratio jumps remains unresolved.

## Bottom line

The current evidence does **not** support the business statement "recovery improved by 11% month-on-month."

A more defensible statement is:

> **Gross recovery remained broadly flat through the complete Jan-Jul months. The apparent improvement in recovery per working account is explained primarily by a shrinking and changing denominator, while mix-standardized and fixed-cohort recovery remain essentially flat. No causal operational lever has yet been demonstrated, and the data does not support a reliable ₹10 Cr ROI estimate.**
