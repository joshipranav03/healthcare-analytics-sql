# Findings & Insights — Northwind General Health

A short analyst's write-up of what the data shows. Every figure below is
reproducible by running `python scripts/run_analysis_sqlite.py`, or by
executing the corresponding query in `sql/analysis/` against PostgreSQL.

> Dataset: 2,000 patients · 4,675 encounters · Jan 2023 – Dec 2024 (synthetic).

---

## 1. Who are the patients?

- **2,000 patients**, near-even gender split (**50.9% female**).
- The population skews older, as expected for a hospital: **53% are 50+**,
  and **27% are seniors (65+)**. Only 6.8% are pediatric.
- **Medicare is the single largest payer (29.6%)** — consistent with the
  older age profile — followed by BlueCross BlueShield (20.4%) and
  Medicaid (18.6%). **6.7% are Self-Pay** (uninsured), the group most at
  risk for unpaid bills (see §4).

*Source: [`01_patient_demographics.sql`](../sql/analysis/01_patient_demographics.sql)*

## 2. Length of stay (LOS)

- **Cardiology (6.2 days), Oncology (5.9), and Neurology (5.8)** have the
  longest average stays — the high-acuity inpatient services.
- **Emergency (0.8 days) and Psychiatry (1.7)** are the shortest.
- Median LOS confirms the pattern and is robust to outliers: Cardiology,
  Oncology and Neurology all sit at a **median of 6 days with a p90 of 11**,
  meaning the longest 10% of stays run nearly double the typical case.

*Source: [`02_admissions_and_los.sql`](../sql/analysis/02_admissions_and_los.sql),
[`06_advanced_cohorts_and_windows.sql`](../sql/analysis/06_advanced_cohorts_and_windows.sql)*

## 3. 30-day readmissions (a key quality metric)

- The **overall 30-day readmission rate is 10.2%**.
- It is highest in **Oncology (13.6%)** and **Orthopedics (12.3%)**, and
  lowest in **Neurology (7.1%)** and **Psychiatry (8.4%)**.
- **Takeaway:** Oncology and Orthopedics are the two service lines where
  better discharge planning or follow-up care would most reduce costly
  "bounce-back" admissions.

*Source: [`03_readmissions.sql`](../sql/analysis/03_readmissions.sql)*

## 4. Revenue & collections

- **$90.1M billed**, **$83.3M collected** → an overall **collection rate
  of 92.5%**, leaving **$6.7M outstanding**.
- Collection rate is strongest for **Medicaid (96.5%)** and **Medicare
  (94.0%)**, and weakest for **Self-Pay (75.8%)** — the uninsured segment
  is where the hospital writes off or fails to collect the most.
- **Oncology is the top revenue department ($13.1M billed)**, followed by
  Cardiology ($11.7M) — driven by both volume and long, expensive stays.

*Source: [`05_revenue_and_billing.sql`](../sql/analysis/05_revenue_and_billing.sql)*

## 5. Staffing & operations

- Internal Medicine carries the highest total encounter volume (727), and
  the busiest individual providers each handle 150+ encounters over the
  two-year window.
- This supports **workload-balancing** conversations: departments with
  high encounters-per-provider are candidates for additional hiring.

*Source: [`04_provider_performance.sql`](../sql/analysis/04_provider_performance.sql)*

---

## Recommended actions (analyst's summary)

1. **Target Oncology & Orthopedics readmissions** — highest 30-day rates;
   the biggest quality-and-cost lever.
2. **Tighten Self-Pay collections** — 75.8% vs. 92%+ for insured payers;
   ~$6.7M is outstanding overall.
3. **Review Cardiology/Oncology LOS** — longest stays drive both cost and
   bed availability; the p90 tail (11 days) is worth case-managing.

*All insights are derived from synthetic data and are illustrative of the
analytical approach, not real clinical findings.*
