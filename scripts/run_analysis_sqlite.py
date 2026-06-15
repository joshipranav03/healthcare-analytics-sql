"""
Run the analysis against an in-memory SQLite database.

Why this exists:
  The canonical queries in sql/analysis/*.sql are written for PostgreSQL.
  This script loads the same CSVs into SQLite and runs dialect-adapted
  equivalents so anyone can reproduce the headline findings with zero
  setup (no database server required):

      python scripts/run_analysis_sqlite.py

  The numbers it prints are the ones quoted in findings/insights.md.
  SQLite differences handled here: DATE_TRUNC -> strftime, date subtraction
  -> julianday(), AGE() -> manual year math. Median/p90 are computed in
  Python because SQLite lacks PERCENTILE_CONT.
"""

import csv
import os
import sqlite3
import statistics

DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data")
TABLES = [
    "departments", "providers", "patients", "encounters",
    "diagnoses", "procedures", "prescriptions", "billing",
]


def load_db():
    conn = sqlite3.connect(":memory:")
    cur = conn.cursor()
    for table in TABLES:
        path = os.path.join(DATA_DIR, f"{table}.csv")
        with open(path) as fh:
            reader = csv.reader(fh)
            header = next(reader)
            cols = ", ".join(f'"{c}"' for c in header)
            cur.execute(f'CREATE TABLE {table} ({cols})')
            placeholders = ", ".join("?" for _ in header)
            cur.executemany(
                f'INSERT INTO {table} VALUES ({placeholders})', list(reader)
            )
    conn.commit()
    return conn


def show(title, rows, headers):
    print(f"\n{'=' * 70}\n{title}\n{'=' * 70}")
    widths = [len(h) for h in headers]
    for r in rows:
        for i, v in enumerate(r):
            widths[i] = max(widths[i], len(str(v)))
    fmt = "  ".join("{:<%d}" % w for w in widths)
    print(fmt.format(*headers))
    print("  ".join("-" * w for w in widths))
    for r in rows:
        print(fmt.format(*[str(v) for v in r]))


def main():
    conn = load_db()
    c = conn.cursor()

    # --- Patient demographics -----------------------------------------
    c.execute("""
        SELECT COUNT(*),
               SUM(gender='F'), SUM(gender='M'),
               ROUND(100.0*SUM(gender='F')/COUNT(*), 1)
        FROM patients
    """)
    show("Patient counts & gender split", c.fetchall(),
         ["total", "female", "male", "pct_female"])

    c.execute("""
        WITH aged AS (
            SELECT CAST((julianday('2024-12-31') - julianday(birth_date))/365.25 AS INT) AS age
            FROM patients
        )
        SELECT CASE
                 WHEN age < 18 THEN '0-17  Pediatric'
                 WHEN age < 35 THEN '18-34 Young adult'
                 WHEN age < 50 THEN '35-49 Adult'
                 WHEN age < 65 THEN '50-64 Older adult'
                 ELSE '65+   Senior' END AS band,
               COUNT(*),
               ROUND(100.0*COUNT(*)/(SELECT COUNT(*) FROM patients), 1)
        FROM aged GROUP BY band ORDER BY band
    """)
    show("Age distribution", c.fetchall(), ["age_band", "patients", "pct"])

    c.execute("""
        SELECT insurance_provider, COUNT(*),
               ROUND(100.0*COUNT(*)/(SELECT COUNT(*) FROM patients), 1)
        FROM patients GROUP BY insurance_provider ORDER BY 2 DESC
    """)
    show("Insurance mix", c.fetchall(), ["payer", "patients", "pct"])

    # --- Length of stay by department ---------------------------------
    c.execute("""
        SELECT d.department_name, COUNT(*),
               ROUND(AVG(julianday(e.discharge_date)-julianday(e.admit_date)), 2)
        FROM encounters e JOIN departments d ON d.department_id=e.department_id
        GROUP BY d.department_name ORDER BY 3 DESC
    """)
    show("Avg length of stay by department", c.fetchall(),
         ["department", "encounters", "avg_los_days"])

    # --- 30-day readmissions (LEAD window) ----------------------------
    c.execute("""
        WITH ordered AS (
            SELECT patient_id,
                   discharge_date,
                   LEAD(admit_date) OVER (PARTITION BY patient_id ORDER BY admit_date) AS next_admit
            FROM encounters
        )
        SELECT COUNT(*),
               SUM(CASE WHEN next_admit IS NOT NULL
                         AND julianday(next_admit)-julianday(discharge_date) <= 30
                        THEN 1 ELSE 0 END),
               ROUND(100.0*SUM(CASE WHEN next_admit IS NOT NULL
                         AND julianday(next_admit)-julianday(discharge_date) <= 30
                        THEN 1 ELSE 0 END)/COUNT(*), 2)
        FROM ordered
    """)
    show("30-day readmission rate (overall)", c.fetchall(),
         ["index_discharges", "readmissions_30d", "rate_pct"])

    c.execute("""
        WITH ordered AS (
            SELECT department_id, patient_id, discharge_date,
                   LEAD(admit_date) OVER (PARTITION BY patient_id ORDER BY admit_date) AS next_admit
            FROM encounters
        )
        SELECT d.department_name, COUNT(*),
               ROUND(100.0*SUM(CASE WHEN o.next_admit IS NOT NULL
                         AND julianday(o.next_admit)-julianday(o.discharge_date) <= 30
                        THEN 1 ELSE 0 END)/COUNT(*), 2)
        FROM ordered o JOIN departments d ON d.department_id=o.department_id
        GROUP BY d.department_name HAVING COUNT(*) >= 50 ORDER BY 3 DESC
    """)
    show("30-day readmission rate by department", c.fetchall(),
         ["department", "index_discharges", "rate_pct"])

    # --- Provider leaderboard -----------------------------------------
    c.execute("""
        SELECT p.first_name||' '||p.last_name, p.specialty, COUNT(e.encounter_id)
        FROM providers p LEFT JOIN encounters e ON e.provider_id=p.provider_id
        GROUP BY p.provider_id ORDER BY 3 DESC LIMIT 5
    """)
    show("Top 5 providers by workload", c.fetchall(),
         ["provider", "specialty", "encounters"])

    # --- Financials ----------------------------------------------------
    c.execute("""
        SELECT ROUND(SUM(total_charge), 2),
               ROUND(SUM(insurance_paid+patient_paid), 2),
               ROUND(SUM(total_charge-insurance_paid-patient_paid), 2),
               ROUND(100.0*SUM(insurance_paid+patient_paid)/SUM(total_charge), 1)
        FROM billing
    """)
    show("Top-line financials", c.fetchall(),
         ["total_billed", "total_collected", "outstanding", "collection_rate_pct"])

    c.execute("""
        SELECT pt.insurance_provider, COUNT(*),
               ROUND(SUM(b.total_charge), 0),
               ROUND(100.0*SUM(b.insurance_paid+b.patient_paid)/SUM(b.total_charge), 1)
        FROM billing b JOIN encounters e ON e.encounter_id=b.encounter_id
        JOIN patients pt ON pt.patient_id=e.patient_id
        GROUP BY pt.insurance_provider ORDER BY 3 DESC
    """)
    show("Collection rate by payer", c.fetchall(),
         ["payer", "claims", "total_billed", "collection_rate_pct"])

    c.execute("""
        SELECT d.department_name, COUNT(*), ROUND(SUM(b.total_charge), 0)
        FROM billing b JOIN encounters e ON e.encounter_id=b.encounter_id
        JOIN departments d ON d.department_id=e.department_id
        GROUP BY d.department_name ORDER BY 3 DESC LIMIT 5
    """)
    show("Top 5 departments by billed revenue", c.fetchall(),
         ["department", "encounters", "total_billed"])

    # --- Top primary diagnoses ----------------------------------------
    c.execute("""
        SELECT diagnosis_description, COUNT(*),
               ROUND(100.0*COUNT(*)/(SELECT COUNT(*) FROM diagnoses WHERE is_primary='True'), 1)
        FROM diagnoses WHERE is_primary='True'
        GROUP BY diagnosis_description ORDER BY 2 DESC LIMIT 8
    """)
    show("Top primary diagnoses", c.fetchall(),
         ["diagnosis", "encounters", "pct_of_primary"])

    # --- Median / p90 LOS (computed in Python; SQLite lacks PERCENTILE) -
    c.execute("""
        SELECT d.department_name,
               julianday(e.discharge_date)-julianday(e.admit_date)
        FROM encounters e JOIN departments d ON d.department_id=e.department_id
    """)
    by_dept = {}
    for name, los in c.fetchall():
        by_dept.setdefault(name, []).append(los)
    rows = []
    for name, los_list in by_dept.items():
        los_list.sort()
        median = statistics.median(los_list)
        p90 = los_list[int(0.9 * (len(los_list) - 1))]
        rows.append((name, len(los_list), median, p90))
    rows.sort(key=lambda r: r[2], reverse=True)
    show("LOS distribution by department (median / p90)", rows,
         ["department", "encounters", "median_los", "p90_los"])

    conn.close()
    print("\nAll queries executed successfully against the dataset.")


if __name__ == "__main__":
    main()
