-- =====================================================================
-- 06 — Advanced: Cohorts, Running Totals & Distributions
-- Difficulty: ⭐⭐⭐⭐ Advanced (LAG, running SUM, PERCENTILE_CONT, NTILE)
-- =====================================================================
-- A showcase of analytical SQL patterns an analyst reaches for daily:
-- month-over-month growth, cumulative running totals, statistical
-- distribution (median/percentiles), and bucketing with NTILE.
-- =====================================================================


-- Q6.1 — Month-over-month admissions growth (LAG) -----------------------
WITH monthly AS (
    SELECT
        DATE_TRUNC('month', admit_date)::date AS month,
        COUNT(*)                              AS admissions
    FROM encounters
    GROUP BY DATE_TRUNC('month', admit_date)
)
SELECT
    month,
    admissions,
    LAG(admissions) OVER (ORDER BY month)                       AS prev_month,
    admissions - LAG(admissions) OVER (ORDER BY month)          AS change,
    ROUND(100.0 * (admissions - LAG(admissions) OVER (ORDER BY month))
          / NULLIF(LAG(admissions) OVER (ORDER BY month), 0), 1) AS pct_change
FROM monthly
ORDER BY month;


-- Q6.2 — Cumulative (running) billed revenue over time ------------------
-- Running totals are the bread and butter of financial dashboards.
WITH monthly_rev AS (
    SELECT
        DATE_TRUNC('month', e.admit_date)::date AS month,
        SUM(b.total_charge)                     AS billed
    FROM billing b
    JOIN encounters e ON e.encounter_id = b.encounter_id
    GROUP BY DATE_TRUNC('month', e.admit_date)
)
SELECT
    month,
    ROUND(billed, 2)                                                 AS monthly_billed,
    ROUND(SUM(billed) OVER (ORDER BY month
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2)     AS cumulative_billed
FROM monthly_rev
ORDER BY month;


-- Q6.3 — Length-of-stay distribution per department (percentiles) -------
-- PERCENTILE_CONT is an ordered-set aggregate: exact median + quartiles.
SELECT
    d.department_name,
    COUNT(*)                                                            AS encounters,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY e.discharge_date - e.admit_date) AS median_los,
    PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY e.discharge_date - e.admit_date) AS p90_los
FROM encounters e
JOIN departments d ON d.department_id = e.department_id
GROUP BY d.department_name
ORDER BY median_los DESC;


-- Q6.4 — Segment patients into spend quartiles (NTILE) ------------------
-- Buckets patients into 4 equal-size groups by lifetime billed amount,
-- then profiles each segment — a lightweight value-segmentation model.
WITH patient_spend AS (
    SELECT
        e.patient_id,
        SUM(b.total_charge) AS lifetime_billed,
        COUNT(*)            AS encounters
    FROM billing b
    JOIN encounters e ON e.encounter_id = b.encounter_id
    GROUP BY e.patient_id
),
quartiled AS (
    SELECT
        patient_id,
        lifetime_billed,
        encounters,
        NTILE(4) OVER (ORDER BY lifetime_billed) AS spend_quartile
    FROM patient_spend
)
SELECT
    spend_quartile,
    COUNT(*)                              AS patients,
    ROUND(MIN(lifetime_billed), 2)        AS min_billed,
    ROUND(AVG(lifetime_billed), 2)        AS avg_billed,
    ROUND(MAX(lifetime_billed), 2)        AS max_billed,
    ROUND(AVG(encounters), 1)             AS avg_encounters
FROM quartiled
GROUP BY spend_quartile
ORDER BY spend_quartile;


-- Q6.5 — Most common primary diagnoses with running share ---------------
-- Pareto view: which diagnoses drive the cumulative bulk of admissions?
WITH primary_dx AS (
    SELECT
        dx.diagnosis_description,
        COUNT(*) AS encounters
    FROM diagnoses dx
    WHERE dx.is_primary
    GROUP BY dx.diagnosis_description
)
SELECT
    diagnosis_description,
    encounters,
    ROUND(100.0 * encounters / SUM(encounters) OVER (), 1)          AS pct_of_total,
    ROUND(100.0 * SUM(encounters) OVER (ORDER BY encounters DESC
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
          / SUM(encounters) OVER (), 1)                             AS cumulative_pct
FROM primary_dx
ORDER BY encounters DESC;
