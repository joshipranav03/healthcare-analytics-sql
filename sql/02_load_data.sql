-- =====================================================================
-- Load CSV data into the schema (PostgreSQL)
-- =====================================================================
-- Run this from the project root with psql so the relative paths resolve:
--
--     psql -d healthcare -f sql/02_load_data.sql
--
-- \copy runs client-side, so it works without server-side file access
-- (unlike the SQL COPY command, which requires superuser / file perms).
-- Load order respects foreign keys: parents before children.
-- =====================================================================

\copy departments   FROM 'data/departments.csv'   WITH (FORMAT csv, HEADER true);
\copy providers     FROM 'data/providers.csv'     WITH (FORMAT csv, HEADER true);
\copy patients      FROM 'data/patients.csv'      WITH (FORMAT csv, HEADER true);
\copy encounters    FROM 'data/encounters.csv'    WITH (FORMAT csv, HEADER true);
\copy diagnoses     FROM 'data/diagnoses.csv'     WITH (FORMAT csv, HEADER true);
\copy procedures    FROM 'data/procedures.csv'    WITH (FORMAT csv, HEADER true);
\copy prescriptions FROM 'data/prescriptions.csv' WITH (FORMAT csv, HEADER true);
\copy billing       FROM 'data/billing.csv'       WITH (FORMAT csv, HEADER true);

-- Quick sanity check on row counts after loading.
SELECT 'departments'   AS table_name, COUNT(*) AS rows FROM departments
UNION ALL SELECT 'providers',     COUNT(*) FROM providers
UNION ALL SELECT 'patients',      COUNT(*) FROM patients
UNION ALL SELECT 'encounters',    COUNT(*) FROM encounters
UNION ALL SELECT 'diagnoses',     COUNT(*) FROM diagnoses
UNION ALL SELECT 'procedures',    COUNT(*) FROM procedures
UNION ALL SELECT 'prescriptions', COUNT(*) FROM prescriptions
UNION ALL SELECT 'billing',       COUNT(*) FROM billing;
