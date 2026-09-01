# P3 — Reconciliation Bridge: Reported 11% vs. Like-for-Like Recovery

## Executive result

The supplied data does not disclose the numerator, denominator, attribution rule, or window used by leadership to produce the reported “11% month-on-month recovery improvement”. Therefore the exact reported 11% cannot be reproduced.

An independent reconstruction shows:

- Gross successful-payment recovery is broadly flat across complete Jan–Jul months.
- The corrected working-population denominator shrinks materially.
- Gross recovery divided by that shrinking denominator rises sharply, but this is not matched by recovery from accounts that were actually in the working population at month-start.
- Direct standardization against January DPD × risk × geography mix changes the Jan→Jul result from about -0.2% to about 0.0%.
- A fixed January cohort is also essentially flat.
- Attribution model changes do not materially alter channel ranking, although narrow lookback windows sharply reduce match coverage.

## Bridge

| Step | Definition | Jan→Jul result / effect | Classification |
|---|---|---:|---|
| 1. Leadership claim | “Recovery improved 11% MoM” | Exact basis unavailable | UNVERIFIED |
| 2. Independent gross recovery | Successful payments, after payment deduplication | No detectable Jan→Jul trend | FACT |
| 3. Denominator correction | Latest status as of month-start; historical terminal status not permanently terminal | Jul recovery/account falls from buggy ~₹12,680 to corrected ₹9,532 | FACT |
| 4. Numerator/denominator alignment | Recovery only from accounts in month-start working population | Jan ₹6,241/account → Jul ₹6,230/account = -0.2% | STRONG EVIDENCE |
| 5. Attribution sensitivity | Last-touch vs 30/14/7-day lookback | Channel shares shift <1.5pp; ranking unchanged | FACT |
| 6. Mix standardization | January DPD × risk × geography reference mix | Jan ₹6,241/account → Jul ₹6,241/account ≈ 0% | STRONG EVIDENCE |
| 7. Fixed opening cohort | Same January working cohort tracked across months | Jan ₹6,241/account → Jul ₹6,241/account ≈ 0% | STRONG EVIDENCE |
| 8. Like-for-like conclusion | Correct denominator + mix/cohort checks | No broad operational improvement demonstrated | STRONG EVIDENCE |

## Payment deduplication impact

Raw payments contain 25,500 rows and 17,880 SUCCESS rows. There are 500 duplicated payment IDs (1,000 rows total). Among SUCCESS payments, 346 rows are duplicate instances of those IDs. Removing the duplicated SUCCESS instances removes ₹25.90m of apparent successful-payment recovery across the full period.

Monthly successful-payment overstatement from these duplicate instances:

| Month | Raw successful ₹ | Dedup successful ₹ | Excess ₹ | Excess % |
|---|---:|---:|---:|---:|
| Jan | ₹191.13m | ₹187.23m | ₹3.90m | 2.04% |
| Feb | ₹174.10m | ₹170.14m | ₹3.95m | 2.27% |
| Mar | ₹193.23m | ₹188.91m | ₹4.32m | 2.24% |
| Apr | ₹178.43m | ₹175.14m | ₹3.29m | 1.84% |
| May | ₹187.05m | ₹184.25m | ₹2.80m | 1.50% |
| Jun | ₹178.72m | ₹175.56m | ₹3.16m | 1.77% |
| Jul | ₹190.28m | ₹187.24m | ₹3.04m | 1.60% |
| Aug | ₹48.54m | ₹47.11m | ₹1.43m | 2.95% |

The broader same-account + same-amount + 60-minute check found no additional duplicate payment IDs beyond the 500 exact duplicates. Payment-reference collisions are not safe to deduplicate because they occur across legitimate account/amount combinations.

## Denominator correction

The earlier population logic permanently removed accounts after their first terminal status. 7,758 of 25,999 accounts (~30%) subsequently showed activity after a terminal-status event.

The corrected logic uses the latest status known as of month-start. This prevents reactivated/reclassified accounts from being silently removed forever.

The old logic produced a July recovery/account figure of approximately ₹12,680 versus ₹9,532 under the corrected population. This is a 24.8% reduction in the July ratio caused by the denominator correction.

## Attribution

Last-touch and capped lookback models preserve the same channel ranking:

CALL > WHATSAPP > SMS > FIELD

Channel recovery shares remain within approximately 1.5 percentage points across unlimited, 30-day, 14-day and 7-day windows.

However, successful-payment match coverage falls from 86.0% under unlimited lookback to 59.8%, 36.0% and 20.2% under 30/14/7-day windows. Therefore tight attribution windows are unsuitable for an undisclosed “kept” metric without an explicit business rationale.

## Mix and cohort adjustment

Direct standardization against January’s joint DPD × risk × geography distribution produces:

- January: ₹6,240.97 raw → ₹6,240.97 standardized
- July: ₹6,230.09 raw → ₹6,240.86 standardized

Raw Jan→Jul change: approximately -0.2%.

Standardized Jan→Jul change: approximately 0.0%.

The fixed January opening cohort produces ₹6,240.97/account in January and ₹6,241.41/account in July. This is effectively flat.

## Final interpretation

Do not state that “recovery improved 11% month-on-month.” The data does not support that statement under an independently reconstructed, population-aligned, mix-adjusted or fixed-cohort metric.

The strongest supported conclusion is:

> The headline improvement is primarily a property of the recovery-per-working-account denominator and its mismatch with the broader payment numerator. After aligning the numerator and denominator, holding portfolio mix constant, and tracking a fixed opening cohort, there is no broad evidence of operational recovery improvement from January through July.

This does not prove that every individual operational initiative had zero effect. It means the dataset does not demonstrate a broad system-level recovery lift sufficient to support the reported 11% claim.
