"""
Synthetic healthcare dataset generator.

Produces CSV files for a fictional hospital network ("Northwind General Health").
All data is randomly generated and contains NO real patient information (PHI).

Output is deterministic (fixed random seed) so the repository stays reproducible:
running this script always yields byte-identical CSVs.

Usage:
    python scripts/generate_data.py
"""

import csv
import os
import random
from datetime import date, timedelta

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
SEED = 42
N_PATIENTS = 2000
N_PROVIDERS = 60
START_DATE = date(2023, 1, 1)
END_DATE = date(2024, 12, 31)

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "data")

random.seed(SEED)

# ---------------------------------------------------------------------------
# Reference / lookup data
# ---------------------------------------------------------------------------
DEPARTMENTS = [
    ("Cardiology", "Inpatient"),
    ("Emergency", "Emergency"),
    ("Oncology", "Inpatient"),
    ("Orthopedics", "Inpatient"),
    ("Pediatrics", "Inpatient"),
    ("Neurology", "Inpatient"),
    ("General Surgery", "Surgical"),
    ("Internal Medicine", "Outpatient"),
    ("Obstetrics", "Inpatient"),
    ("Radiology", "Diagnostic"),
    ("Psychiatry", "Outpatient"),
    ("Pulmonology", "Inpatient"),
]

# (icd10_code, description, chronic_flag, typical_department)
DIAGNOSES = [
    ("I21.9", "Acute myocardial infarction", False, "Cardiology"),
    ("I50.9", "Congestive heart failure", True, "Cardiology"),
    ("I10", "Essential hypertension", True, "Internal Medicine"),
    ("E11.9", "Type 2 diabetes mellitus", True, "Internal Medicine"),
    ("J44.9", "Chronic obstructive pulmonary disease", True, "Pulmonology"),
    ("J18.9", "Pneumonia", False, "Pulmonology"),
    ("C50.9", "Malignant neoplasm of breast", True, "Oncology"),
    ("C34.9", "Malignant neoplasm of lung", True, "Oncology"),
    ("S72.0", "Fracture of femur", False, "Orthopedics"),
    ("M17.9", "Osteoarthritis of knee", True, "Orthopedics"),
    ("I63.9", "Cerebral infarction (stroke)", False, "Neurology"),
    ("G40.9", "Epilepsy", True, "Neurology"),
    ("O80", "Normal delivery", False, "Obstetrics"),
    ("F32.9", "Major depressive disorder", True, "Psychiatry"),
    ("F41.1", "Generalized anxiety disorder", True, "Psychiatry"),
    ("A41.9", "Sepsis", False, "Emergency"),
    ("K35.80", "Acute appendicitis", False, "General Surgery"),
    ("N17.9", "Acute kidney failure", False, "Internal Medicine"),
    ("J45.909", "Asthma", True, "Pediatrics"),
    ("R07.9", "Chest pain, unspecified", False, "Emergency"),
]

# (name, route)
MEDICATIONS = [
    ("Atorvastatin", "Oral"),
    ("Lisinopril", "Oral"),
    ("Metformin", "Oral"),
    ("Amlodipine", "Oral"),
    ("Albuterol", "Inhalation"),
    ("Furosemide", "Oral"),
    ("Insulin Glargine", "Injection"),
    ("Warfarin", "Oral"),
    ("Levothyroxine", "Oral"),
    ("Omeprazole", "Oral"),
    ("Sertraline", "Oral"),
    ("Ceftriaxone", "Injection"),
    ("Morphine", "Injection"),
    ("Aspirin", "Oral"),
    ("Prednisone", "Oral"),
]

# (name, department)
PROCEDURES = [
    ("Coronary angioplasty", "Cardiology"),
    ("Echocardiogram", "Cardiology"),
    ("CT scan", "Radiology"),
    ("MRI scan", "Radiology"),
    ("Appendectomy", "General Surgery"),
    ("Knee replacement", "Orthopedics"),
    ("Hip replacement", "Orthopedics"),
    ("Chemotherapy session", "Oncology"),
    ("Colonoscopy", "General Surgery"),
    ("Cesarean section", "Obstetrics"),
    ("Dialysis", "Internal Medicine"),
    ("Intubation", "Emergency"),
]

ADMISSION_TYPES = ["Emergency", "Elective", "Urgent", "Newborn"]
INSURANCE_PROVIDERS = [
    ("Medicare", 0.30),
    ("Medicaid", 0.18),
    ("BlueCross BlueShield", 0.20),
    ("UnitedHealthcare", 0.14),
    ("Aetna", 0.10),
    ("Self-Pay", 0.08),
]
DISCHARGE_DISPOSITIONS = [
    ("Home", 0.70),
    ("Home Health Care", 0.10),
    ("Skilled Nursing Facility", 0.08),
    ("Transferred", 0.05),
    ("Rehabilitation", 0.04),
    ("Expired", 0.02),
    ("Left Against Medical Advice", 0.01),
]

FIRST_NAMES = [
    "James", "Mary", "Robert", "Patricia", "John", "Jennifer", "Michael", "Linda",
    "David", "Elizabeth", "William", "Barbara", "Richard", "Susan", "Joseph", "Jessica",
    "Thomas", "Sarah", "Charles", "Karen", "Maria", "Jose", "Wei", "Aisha", "Mohammed",
    "Priya", "Chen", "Sofia", "Liam", "Olivia", "Noah", "Emma", "Carlos", "Fatima",
]
LAST_NAMES = [
    "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis",
    "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson",
    "Thomas", "Taylor", "Moore", "Jackson", "Martin", "Lee", "Patel", "Nguyen",
    "Kim", "Chen", "Wang", "Ali", "Khan", "Singh", "Okafor",
]
CITIES = [
    ("Boston", "MA"), ("Cambridge", "MA"), ("Worcester", "MA"), ("Springfield", "MA"),
    ("Providence", "RI"), ("Hartford", "CT"), ("Manchester", "NH"), ("Portland", "ME"),
]


def weighted_choice(pairs):
    """pairs: list of (value, weight). Returns a value."""
    values, weights = zip(*pairs)
    return random.choices(values, weights=weights, k=1)[0]


def random_date(start, end):
    delta_days = (end - start).days
    return start + timedelta(days=random.randint(0, delta_days))


def write_csv(filename, header, rows):
    path = os.path.join(OUTPUT_DIR, filename)
    with open(path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(header)
        writer.writerows(rows)
    print(f"  wrote {len(rows):>6} rows -> data/{filename}")


# ---------------------------------------------------------------------------
# Generators
# ---------------------------------------------------------------------------
def gen_departments():
    rows = []
    for i, (name, dtype) in enumerate(DEPARTMENTS, start=1):
        floor = random.randint(1, 8)
        rows.append([i, name, dtype, floor])
    write_csv("departments.csv", ["department_id", "department_name", "department_type", "floor"], rows)
    return rows


def gen_providers(departments):
    rows = []
    specialties = [d[1] for d in departments]
    for i in range(1, N_PROVIDERS + 1):
        first = random.choice(FIRST_NAMES)
        last = random.choice(LAST_NAMES)
        dept = random.choice(departments)
        hire_date = random_date(date(2010, 1, 1), date(2022, 12, 31))
        rows.append([i, first, last, dept[1], dept[0], hire_date.isoformat()])
    write_csv(
        "providers.csv",
        ["provider_id", "first_name", "last_name", "specialty", "department_id", "hire_date"],
        rows,
    )
    return rows


def gen_patients():
    rows = []
    for i in range(1, N_PATIENTS + 1):
        gender = random.choice(["M", "F"])
        first = random.choice(FIRST_NAMES)
        last = random.choice(LAST_NAMES)
        # Age skewed older to be realistic for a hospital population
        age = int(min(95, max(0, random.gauss(52, 22))))
        birth_date = date(END_DATE.year - age, random.randint(1, 12), random.randint(1, 28))
        city, state = random.choice(CITIES)
        insurance = weighted_choice(INSURANCE_PROVIDERS)
        registration = random_date(date(2015, 1, 1), END_DATE)
        rows.append([
            i, first, last, gender, birth_date.isoformat(),
            city, state, insurance, registration.isoformat(),
        ])
    write_csv(
        "patients.csv",
        ["patient_id", "first_name", "last_name", "gender", "birth_date",
         "city", "state", "insurance_provider", "registration_date"],
        rows,
    )
    return rows


def gen_encounters(patients, providers, dept_by_name):
    """Generate encounters (hospital visits/admissions) plus child tables."""
    enc_rows = []
    diag_rows = []
    proc_rows = []
    presc_rows = []
    bill_rows = []

    encounter_id = 0
    diag_id = 0
    proc_id = 0
    presc_id = 0

    providers_by_dept = {}
    for p in providers:
        providers_by_dept.setdefault(p[4], []).append(p)

    # Each patient has a variable number of encounters
    for patient in patients:
        pid = patient[0]
        n_enc = random.choices([1, 2, 3, 4, 5, 8], weights=[40, 25, 15, 10, 7, 3])[0]
        # Patients with chronic conditions tend to come back more
        last_discharge = None
        for _ in range(n_enc):
            encounter_id += 1

            # Pick a primary diagnosis, which drives the department
            diag = random.choice(DIAGNOSES)
            dept_name = diag[3]
            dept_id = dept_by_name[dept_name]
            dept_providers = providers_by_dept.get(dept_id) or providers
            provider = random.choice(dept_providers)

            admit_date = random_date(START_DATE, END_DATE)
            admission_type = weighted_choice(
                [("Emergency", 0.40), ("Elective", 0.30), ("Urgent", 0.25), ("Newborn", 0.05)]
            )

            # Length of stay depends on department/diagnosis severity
            if dept_name in ("Internal Medicine", "Psychiatry"):
                los = max(0, int(random.gauss(2, 2)))
            elif dept_name in ("Oncology", "Cardiology", "Neurology"):
                los = max(1, int(random.gauss(6, 4)))
            elif dept_name == "Emergency":
                los = random.choice([0, 0, 1, 1, 2])
            else:
                los = max(0, int(random.gauss(4, 3)))

            discharge_date = admit_date + timedelta(days=los)
            disposition = weighted_choice(DISCHARGE_DISPOSITIONS)

            enc_rows.append([
                encounter_id, pid, provider[0], dept_id,
                admit_date.isoformat(), discharge_date.isoformat(),
                admission_type, disposition,
            ])

            # --- Diagnoses (1 primary + 0-3 secondary) ---
            diag_id += 1
            diag_rows.append([diag_id, encounter_id, diag[0], diag[1], True])
            for _ in range(random.randint(0, 3)):
                sec = random.choice(DIAGNOSES)
                diag_id += 1
                diag_rows.append([diag_id, encounter_id, sec[0], sec[1], False])

            # --- Procedures (0-3) ---
            for _ in range(random.randint(0, 3)):
                proc = random.choice(PROCEDURES)
                proc_id += 1
                proc_date = admit_date + timedelta(days=random.randint(0, max(0, los)))
                proc_rows.append([proc_id, encounter_id, proc[0], proc_date.isoformat()])

            # --- Prescriptions (0-4) ---
            for _ in range(random.randint(0, 4)):
                med = random.choice(MEDICATIONS)
                presc_id += 1
                presc_rows.append([presc_id, encounter_id, med[0], med[1]])

            # --- Billing (one claim per encounter) ---
            base_per_day = random.uniform(1800, 4200)
            room_charges = round(base_per_day * max(1, los), 2)
            procedure_charges = round(
                sum(random.uniform(500, 9000) for _ in range(random.randint(0, 3))), 2
            )
            total_charge = round(room_charges + procedure_charges + random.uniform(200, 1500), 2)
            insurance = patient[7]
            # Coverage rate varies by insurer
            coverage = {
                "Medicare": 0.80, "Medicaid": 0.90, "BlueCross BlueShield": 0.75,
                "UnitedHealthcare": 0.72, "Aetna": 0.70, "Self-Pay": 0.0,
            }.get(insurance, 0.70)
            insurance_paid = round(total_charge * coverage * random.uniform(0.9, 1.0), 2)
            patient_paid = round(min(total_charge - insurance_paid,
                                     (total_charge - insurance_paid) * random.uniform(0.5, 1.0)), 2)
            # Some bills remain partly unpaid
            payment_status = weighted_choice(
                [("Paid", 0.65), ("Partially Paid", 0.20), ("Pending", 0.10), ("Written Off", 0.05)]
            )
            bill_rows.append([
                encounter_id, total_charge, insurance_paid, patient_paid, payment_status,
            ])

            last_discharge = discharge_date

    write_csv(
        "encounters.csv",
        ["encounter_id", "patient_id", "provider_id", "department_id",
         "admit_date", "discharge_date", "admission_type", "discharge_disposition"],
        enc_rows,
    )
    write_csv(
        "diagnoses.csv",
        ["diagnosis_id", "encounter_id", "icd10_code", "diagnosis_description", "is_primary"],
        diag_rows,
    )
    write_csv(
        "procedures.csv",
        ["procedure_id", "encounter_id", "procedure_name", "procedure_date"],
        proc_rows,
    )
    write_csv(
        "prescriptions.csv",
        ["prescription_id", "encounter_id", "medication_name", "route"],
        presc_rows,
    )
    write_csv(
        "billing.csv",
        ["encounter_id", "total_charge", "insurance_paid", "patient_paid", "payment_status"],
        bill_rows,
    )
    return enc_rows


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    print("Generating synthetic healthcare dataset (seed=%d)..." % SEED)
    departments = gen_departments()
    dept_by_name = {name: i for i, (name, _t, _f) in
                    ((row[0], (row[1], row[2], row[3])) for row in departments)}
    providers = gen_providers(departments)
    patients = gen_patients()
    gen_encounters(patients, providers, dept_by_name)
    print("Done.")


if __name__ == "__main__":
    main()
