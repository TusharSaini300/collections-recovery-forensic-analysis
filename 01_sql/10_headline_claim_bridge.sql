-- P3/P4: Headline claim bridge
-- Purpose: show where the reported ~11% can be arithmetically reproduced
-- without claiming that this is the exact undisclosed leadership KPI definition.
--
-- Gross recovery Feb -> Mar:
--   Feb = 170,142,453.76
--   Mar = 188,912,374.02
--   MoM = (Mar / Feb - 1) * 100 = 11.031885%
--
-- Corrected recovery/account Feb -> Mar is also approximately 11.73%.
-- Therefore the supplied brief does not identify the exact KPI basis.

WITH monthly AS (
    SELECT
        month,
        gross_recovery,
        corrected_recovery_per_working_account
    FROM monthly_metrics
    WHERE month BETWEEN '2026-01-01' AND '2026-07-01'
)
SELECT
    'Gross recovery' AS metric,
    'Feb -> Mar' AS comparison,
    MAX(CASE WHEN month = '2026-02-01' THEN gross_recovery END) AS prior_value,
    MAX(CASE WHEN month = '2026-03-01' THEN gross_recovery END) AS current_value,
    (
        MAX(CASE WHEN month = '2026-03-01' THEN gross_recovery END) /
        MAX(CASE WHEN month = '2026-02-01' THEN gross_recovery END) - 1
    ) * 100 AS change_pct
FROM monthly

UNION ALL

SELECT
    'Corrected recovery/account',
    'Feb -> Mar',
    MAX(CASE WHEN month = '2026-02-01' THEN corrected_recovery_per_working_account END),
    MAX(CASE WHEN month = '2026-03-01' THEN corrected_recovery_per_working_account END),
    (
        MAX(CASE WHEN month = '2026-03-01' THEN corrected_recovery_per_working_account END) /
        MAX(CASE WHEN month = '2026-02-01' THEN corrected_recovery_per_working_account END) - 1
    ) * 100
FROM monthly;
