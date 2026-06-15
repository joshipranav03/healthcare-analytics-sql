-- =====================================================================
-- Northwind General Health — Database Schema (PostgreSQL)
-- =====================================================================
-- Run order:
--   1) 01_schema.sql      <- you are here (creates tables)
--   2) 02_load_data.sql   (loads CSVs with \copy)
--   3) 03_indexes.sql     (adds indexes for analytical queries)
--
-- All data is synthetic. No real patient information is present.
-- =====================================================================

DROP TABLE IF EXISTS billing        CASCADE;
DROP TABLE IF EXISTS prescriptions  CASCADE;
DROP TABLE IF EXISTS procedures      CASCADE;
DROP TABLE IF EXISTS diagnoses       CASCADE;
DROP TABLE IF EXISTS encounters      CASCADE;
DROP TABLE IF EXISTS patients        CASCADE;
DROP TABLE IF EXISTS providers       CASCADE;
DROP TABLE IF EXISTS departments     CASCADE;

-- ---------------------------------------------------------------------
-- Reference tables
-- ---------------------------------------------------------------------
CREATE TABLE departments (
    department_id   INTEGER PRIMARY KEY,
    department_name TEXT    NOT NULL,
    department_type TEXT    NOT NULL,   -- Inpatient, Outpatient, Emergency, ...
    floor           INTEGER NOT NULL
);

CREATE TABLE providers (
    provider_id   INTEGER PRIMARY KEY,
    first_name    TEXT    NOT NULL,
    last_name     TEXT    NOT NULL,
    specialty     TEXT    NOT NULL,
    department_id INTEGER NOT NULL REFERENCES departments (department_id),
    hire_date     DATE    NOT NULL
);

CREATE TABLE patients (
    patient_id         INTEGER PRIMARY KEY,
    first_name         TEXT    NOT NULL,
    last_name          TEXT    NOT NULL,
    gender             CHAR(1) NOT NULL CHECK (gender IN ('M', 'F')),
    birth_date         DATE    NOT NULL,
    city               TEXT    NOT NULL,
    state              CHAR(2) NOT NULL,
    insurance_provider TEXT    NOT NULL,
    registration_date  DATE    NOT NULL
);

-- ---------------------------------------------------------------------
-- Core fact table: one row per hospital visit / admission
-- ---------------------------------------------------------------------
CREATE TABLE encounters (
    encounter_id          INTEGER PRIMARY KEY,
    patient_id            INTEGER NOT NULL REFERENCES patients (patient_id),
    provider_id           INTEGER NOT NULL REFERENCES providers (provider_id),
    department_id         INTEGER NOT NULL REFERENCES departments (department_id),
    admit_date            DATE    NOT NULL,
    discharge_date        DATE    NOT NULL,
    admission_type        TEXT    NOT NULL,   -- Emergency, Elective, Urgent, Newborn
    discharge_disposition TEXT    NOT NULL,   -- Home, SNF, Expired, ...
    CONSTRAINT chk_dates CHECK (discharge_date >= admit_date)
);

-- ---------------------------------------------------------------------
-- Child tables hanging off an encounter
-- ---------------------------------------------------------------------
CREATE TABLE diagnoses (
    diagnosis_id          INTEGER PRIMARY KEY,
    encounter_id          INTEGER NOT NULL REFERENCES encounters (encounter_id),
    icd10_code            TEXT    NOT NULL,
    diagnosis_description TEXT    NOT NULL,
    is_primary            BOOLEAN NOT NULL
);

CREATE TABLE procedures (
    procedure_id   INTEGER PRIMARY KEY,
    encounter_id   INTEGER NOT NULL REFERENCES encounters (encounter_id),
    procedure_name TEXT    NOT NULL,
    procedure_date DATE    NOT NULL
);

CREATE TABLE prescriptions (
    prescription_id INTEGER PRIMARY KEY,
    encounter_id    INTEGER NOT NULL REFERENCES encounters (encounter_id),
    medication_name TEXT    NOT NULL,
    route           TEXT    NOT NULL
);

CREATE TABLE billing (
    encounter_id   INTEGER PRIMARY KEY REFERENCES encounters (encounter_id),
    total_charge   NUMERIC(12, 2) NOT NULL,
    insurance_paid NUMERIC(12, 2) NOT NULL,
    patient_paid   NUMERIC(12, 2) NOT NULL,
    payment_status TEXT           NOT NULL   -- Paid, Partially Paid, Pending, Written Off
);
