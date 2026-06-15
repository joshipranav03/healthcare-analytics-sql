-- =====================================================================
-- 02 — Admissions Volume & Length of Stay (LOS)
-- Difficulty: ⭐⭐ Intermediate (JOIN, DATE_TRUNC, date math, aggregates)
-- =====================================================================
-- Business questions:
--   * How does admission volume trend month over month?
--   * Which departments keep patients the longest?
--   * How does length of stay vary by admission type?
-- =====================================================================


-- Q2.1 — Monthly admissions trend ---------------------------------------
-- DATE_TRUNC collapses each admit_date to the first of its month.
SELECT
    DATE_TRUNC('month', admit_date)::date AS month,
    COUNT(*)                              AS admissions
FROM encounters
GROUP BY DATE_TRUNC('month', admit_date)
ORDER BY month;


-- Q2.2 — Average length of stay by department ---------------------------
-- In PostgreSQL, (date - date) yields an integer number of days.
SELECT
    d.department_name,
    COUNT(*)                                          AS encounters,
    ROUND(AVG(e.discharge_date - e.admit_date), 2)    AS avg_los_days,
    MAX(e.discharge_date - e.admit_date)              AS max_los_days
FROM encounters e
JOIN departments d ON d.department_id = e.department_id
GROUP BY d.department_name
ORDER BY avg_los_days DESC;


-- Q2.3 — Length of stay by admission type -------------------------------
SELECT
    admission_type,
    COUNT(*)                                       AS encounters,
    ROUND(AVG(discharge_date - admit_date), 2)     AS avg_los_days
FROM encounters
GROUP BY admission_type
ORDER BY avg_los_days DESC;


-- Q2.4 — Same-day discharges vs admitted stays --------------------------
-- A simple operational KPI: what share of encounters are day cases?
SELECT
    CASE WHEN discharge_date = admit_date THEN 'Same-day'
         ELSE 'Overnight+' END                       AS stay_type,
    COUNT(*)                                          AS encounters,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM encounters
GROUP BY stay_type
ORDER BY encounters DESC;
