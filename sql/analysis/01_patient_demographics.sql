-- =====================================================================
-- 01 — Patient Demographics
-- Difficulty: ⭐ Fundamentals (COUNT, GROUP BY, CASE, simple ratios)
-- =====================================================================
-- Business questions:
--   * Who are our patients? (gender, age, geography, insurance mix)
--   * What is the age distribution of the patient population?
-- =====================================================================


-- Q1.1 — Headline patient counts and gender split -----------------------
SELECT
    COUNT(*)                                              AS total_patients,
    COUNT(*) FILTER (WHERE gender = 'F')                  AS female,
    COUNT(*) FILTER (WHERE gender = 'M')                  AS male,
    ROUND(100.0 * COUNT(*) FILTER (WHERE gender = 'F') / COUNT(*), 1) AS pct_female
FROM patients;


-- Q1.2 — Patient age distribution by band -------------------------------
-- AGE() returns an interval; EXTRACT pulls whole years out of it.
SELECT
    CASE
        WHEN age_years < 18 THEN '0-17  (Pediatric)'
        WHEN age_years < 35 THEN '18-34 (Young adult)'
        WHEN age_years < 50 THEN '35-49 (Adult)'
        WHEN age_years < 65 THEN '50-64 (Older adult)'
        ELSE                     '65+   (Senior)'
    END                              AS age_band,
    COUNT(*)                         AS patients,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_total
FROM (
    SELECT EXTRACT(YEAR FROM AGE(DATE '2024-12-31', birth_date)) AS age_years
    FROM patients
) AS aged
GROUP BY age_band
ORDER BY age_band;


-- Q1.3 — Insurance coverage mix -----------------------------------------
SELECT
    insurance_provider,
    COUNT(*)                                            AS patients,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)  AS pct_of_total
FROM patients
GROUP BY insurance_provider
ORDER BY patients DESC;


-- Q1.4 — Patients by state and city (top locations) ---------------------
SELECT
    state,
    city,
    COUNT(*) AS patients
FROM patients
GROUP BY state, city
ORDER BY patients DESC
LIMIT 10;
