-- =====================================================================
-- 03 — 30-Day Readmissions
-- Difficulty: ⭐⭐⭐ Advanced (window functions: LEAD, self-sequencing)
-- =====================================================================
-- 30-day readmission rate is one of the most-watched hospital quality
-- metrics (it drives Medicare reimbursement penalties). A "readmission"
-- here = a patient is admitted again within 30 days of a prior discharge.
--
-- Technique: order each patient's encounters by date, then use LEAD()
-- to look at the *next* encounter's admit_date from the current row.
-- =====================================================================


-- Q3.1 — Flag every encounter that is followed by a 30-day readmission --
WITH ordered AS (
    SELECT
        encounter_id,
        patient_id,
        department_id,
        admit_date,
        discharge_date,
        LEAD(admit_date) OVER (
            PARTITION BY patient_id
            ORDER BY admit_date
        ) AS next_admit_date
    FROM encounters
)
SELECT
    encounter_id,
    patient_id,
    discharge_date,
    next_admit_date,
    (next_admit_date - discharge_date)                       AS days_to_next_admit,
    (next_admit_date IS NOT NULL
     AND next_admit_date - discharge_date <= 30)             AS is_readmission_index
FROM ordered
WHERE next_admit_date IS NOT NULL
ORDER BY days_to_next_admit
LIMIT 20;


-- Q3.2 — Overall 30-day readmission rate --------------------------------
WITH ordered AS (
    SELECT
        patient_id,
        discharge_date,
        LEAD(admit_date) OVER (
            PARTITION BY patient_id ORDER BY admit_date
        ) AS next_admit_date
    FROM encounters
)
SELECT
    COUNT(*)                                                   AS index_discharges,
    COUNT(*) FILTER (
        WHERE next_admit_date IS NOT NULL
          AND next_admit_date - discharge_date <= 30
    )                                                          AS readmissions_30d,
    ROUND(100.0 * COUNT(*) FILTER (
        WHERE next_admit_date IS NOT NULL
          AND next_admit_date - discharge_date <= 30
    ) / COUNT(*), 2)                                           AS readmission_rate_pct
FROM ordered;


-- Q3.3 — 30-day readmission rate by department --------------------------
-- Which service lines have the highest "bounce-back" rate?
WITH ordered AS (
    SELECT
        department_id,
        discharge_date,
        LEAD(admit_date) OVER (
            PARTITION BY patient_id ORDER BY admit_date
        ) AS next_admit_date
    FROM encounters
)
SELECT
    d.department_name,
    COUNT(*)                                                   AS index_discharges,
    COUNT(*) FILTER (
        WHERE o.next_admit_date IS NOT NULL
          AND o.next_admit_date - o.discharge_date <= 30
    )                                                          AS readmissions_30d,
    ROUND(100.0 * COUNT(*) FILTER (
        WHERE o.next_admit_date IS NOT NULL
          AND o.next_admit_date - o.discharge_date <= 30
    ) / COUNT(*), 2)                                           AS readmission_rate_pct
FROM ordered o
JOIN departments d ON d.department_id = o.department_id
GROUP BY d.department_name
HAVING COUNT(*) >= 50          -- ignore tiny-volume departments
ORDER BY readmission_rate_pct DESC;
