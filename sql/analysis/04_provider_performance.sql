-- =====================================================================
-- 04 — Provider & Department Performance
-- Difficulty: ⭐⭐⭐ Advanced (RANK, DENSE_RANK, window partitions)
-- =====================================================================
-- Business questions:
--   * Who are the busiest providers in each department?
--   * How is workload distributed across the medical staff?
-- =====================================================================


-- Q4.1 — Provider workload leaderboard ----------------------------------
SELECT
    p.provider_id,
    p.first_name || ' ' || p.last_name        AS provider_name,
    p.specialty,
    COUNT(e.encounter_id)                      AS encounters,
    ROUND(AVG(e.discharge_date - e.admit_date), 2) AS avg_los_days,
    RANK() OVER (ORDER BY COUNT(e.encounter_id) DESC) AS workload_rank
FROM providers p
LEFT JOIN encounters e ON e.provider_id = p.provider_id
GROUP BY p.provider_id, provider_name, p.specialty
ORDER BY encounters DESC
LIMIT 15;


-- Q4.2 — Top provider within each department ----------------------------
-- Classic "top-N per group": rank inside each department partition,
-- then keep rank #1. RANK() lets us surface ties cleanly.
WITH provider_volume AS (
    SELECT
        d.department_name,
        p.first_name || ' ' || p.last_name AS provider_name,
        COUNT(e.encounter_id)              AS encounters,
        RANK() OVER (
            PARTITION BY d.department_name
            ORDER BY COUNT(e.encounter_id) DESC
        ) AS rnk
    FROM providers p
    JOIN departments d ON d.department_id = p.department_id
    LEFT JOIN encounters e ON e.provider_id = p.provider_id
    GROUP BY d.department_name, provider_name
)
SELECT department_name, provider_name, encounters
FROM provider_volume
WHERE rnk = 1
ORDER BY encounters DESC;


-- Q4.3 — Department throughput and share of total activity --------------
SELECT
    d.department_name,
    d.department_type,
    COUNT(e.encounter_id)                                     AS encounters,
    ROUND(100.0 * COUNT(e.encounter_id)
          / SUM(COUNT(e.encounter_id)) OVER (), 1)            AS pct_of_all_encounters
FROM departments d
LEFT JOIN encounters e ON e.department_id = d.department_id
GROUP BY d.department_name, d.department_type
ORDER BY encounters DESC;


-- Q4.4 — Workload concentration: avg encounters per provider by dept ----
SELECT
    d.department_name,
    COUNT(DISTINCT p.provider_id)                            AS providers,
    COUNT(e.encounter_id)                                    AS encounters,
    ROUND(COUNT(e.encounter_id)::numeric
          / NULLIF(COUNT(DISTINCT p.provider_id), 0), 1)     AS encounters_per_provider
FROM departments d
JOIN providers p   ON p.department_id = d.department_id
LEFT JOIN encounters e ON e.provider_id = p.provider_id
GROUP BY d.department_name
ORDER BY encounters_per_provider DESC;
