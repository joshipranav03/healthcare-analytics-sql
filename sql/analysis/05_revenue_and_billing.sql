-- =====================================================================
-- 05 — Revenue, Billing & Collections
-- Difficulty: ⭐⭐ Intermediate → ⭐⭐⭐ Advanced (JOINs, ratios, NULLIF)
-- =====================================================================
-- Business questions:
--   * How much revenue do we bill, and how much do we actually collect?
--   * Which payers reimburse best? Where is money outstanding?
-- =====================================================================


-- Q5.1 — Top-line financials --------------------------------------------
-- "Collection rate" = (insurance_paid + patient_paid) / total_charge.
SELECT
    ROUND(SUM(total_charge), 2)                              AS total_billed,
    ROUND(SUM(insurance_paid + patient_paid), 2)            AS total_collected,
    ROUND(SUM(total_charge - insurance_paid - patient_paid), 2) AS outstanding,
    ROUND(100.0 * SUM(insurance_paid + patient_paid)
          / NULLIF(SUM(total_charge), 0), 1)                AS collection_rate_pct
FROM billing;


-- Q5.2 — Revenue and collection rate by insurance payer -----------------
SELECT
    pt.insurance_provider,
    COUNT(*)                                                 AS claims,
    ROUND(SUM(b.total_charge), 2)                            AS total_billed,
    ROUND(SUM(b.insurance_paid + b.patient_paid), 2)        AS total_collected,
    ROUND(100.0 * SUM(b.insurance_paid + b.patient_paid)
          / NULLIF(SUM(b.total_charge), 0), 1)              AS collection_rate_pct
FROM billing b
JOIN encounters e ON e.encounter_id = b.encounter_id
JOIN patients   pt ON pt.patient_id = e.patient_id
GROUP BY pt.insurance_provider
ORDER BY total_billed DESC;


-- Q5.3 — Revenue by department ------------------------------------------
SELECT
    d.department_name,
    COUNT(*)                                                 AS encounters,
    ROUND(SUM(b.total_charge), 2)                            AS total_billed,
    ROUND(AVG(b.total_charge), 2)                            AS avg_charge_per_encounter
FROM billing b
JOIN encounters e   ON e.encounter_id = b.encounter_id
JOIN departments d  ON d.department_id = e.department_id
GROUP BY d.department_name
ORDER BY total_billed DESC;


-- Q5.4 — Outstanding balance by payment status --------------------------
SELECT
    payment_status,
    COUNT(*)                                                 AS claims,
    ROUND(SUM(total_charge - insurance_paid - patient_paid), 2) AS outstanding_balance,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)       AS pct_of_claims
FROM billing
GROUP BY payment_status
ORDER BY outstanding_balance DESC;


-- Q5.5 — Monthly billed revenue trend -----------------------------------
SELECT
    DATE_TRUNC('month', e.admit_date)::date AS month,
    ROUND(SUM(b.total_charge), 2)           AS billed_revenue
FROM billing b
JOIN encounters e ON e.encounter_id = b.encounter_id
GROUP BY DATE_TRUNC('month', e.admit_date)
ORDER BY month;
