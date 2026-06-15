-- =====================================================================
-- Indexes to support the analytical queries (PostgreSQL)
-- =====================================================================
-- These cover the most common filter/join columns used in sql/analysis/*.
-- Primary keys are already indexed automatically; we add foreign-key and
-- date columns that drive the bulk of the analysis.
-- =====================================================================

-- Encounter lookups by patient (readmission / cohort analysis)
CREATE INDEX IF NOT EXISTS idx_encounters_patient   ON encounters (patient_id);
CREATE INDEX IF NOT EXISTS idx_encounters_provider  ON encounters (provider_id);
CREATE INDEX IF NOT EXISTS idx_encounters_dept      ON encounters (department_id);
CREATE INDEX IF NOT EXISTS idx_encounters_admit     ON encounters (admit_date);

-- Child-table joins back to the encounter
CREATE INDEX IF NOT EXISTS idx_diagnoses_encounter     ON diagnoses (encounter_id);
CREATE INDEX IF NOT EXISTS idx_procedures_encounter    ON procedures (encounter_id);
CREATE INDEX IF NOT EXISTS idx_prescriptions_encounter ON prescriptions (encounter_id);

-- Filtering primary diagnoses is common
CREATE INDEX IF NOT EXISTS idx_diagnoses_primary ON diagnoses (encounter_id) WHERE is_primary;
