# OpenHealthDash 🏥📊

> Open-source healthcare analytics framework for clinics and NGOs in low-resource settings.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![dbt](https://img.shields.io/badge/dbt-1.7-orange)](https://getdbt.com)
[![Evidence](https://img.shields.io/badge/Evidence.dev-latest-blue)](https://evidence.dev)
[![Contributions Welcome](https://img.shields.io/badge/contributions-welcome-brightgreen)](CONTRIBUTING.md)
## Dashboard Preview

![OpenHealthDash dashboard showing wait time and bed occupancy charts](docs/images/dashboard-preview.png)

---

## Why OpenHealthDash?

Most healthcare facilities in Africa and the Global South lack access to affordable business intelligence tools. Enterprise platforms like Tableau and Power BI are too expensive. Spreadsheets don't scale.

**OpenHealthDash is a free, open-source analytics framework** that lets hospitals, clinics, and health NGOs build production-grade dashboards using open-source tools — with zero licensing cost.

---

## What It Does

- **Pre-built dbt models** for common healthcare metrics (patient volume, wait times, bed occupancy, maternal health KPIs, disease trends)
- **Dashboard templates** built on Evidence.dev — deployable with a single command
- **Modular design** — use only the models you need; swap in your own data sources
- **Documentation-first** — every model has full lineage docs, tests, and example data

---

## Tech Stack

| Layer | Tool | Why |
|---|---|---|
| Transformation | [dbt Core](https://getdbt.com) | SQL-based, version-controlled data models |
| Storage | [DuckDB](https://duckdb.org) | Zero-config embedded analytics DB |
| Visualisation | [Evidence.dev](https://evidence.dev) | Markdown-based BI — free and open source |
| CI/CD | GitHub Actions | Automated testing and deployment |

---

## Quick Start

### Prerequisites
- Python 3.9+
- Node.js 18+
- Git

### Installation

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/openhealthdash.git
cd openhealthdash

# Install dbt dependencies
pip install dbt-duckdb

# Install Evidence.dev
npm install @evidence-dev/evidence

# Load sample data and run models
dbt deps
dbt seed
dbt run
dbt test

# Launch the dashboard
npm run dev
```

Open `http://localhost:3000` to see your dashboard.

---

## Project Structure

```
openhealthdash/
│
├── dbt/                          # All dbt models and config
│   ├── dbt_project.yml           # Project config
│   ├── profiles.yml              # Connection config (DuckDB)
│   ├── seeds/                    # Sample/demo data (CSV)
│   │   ├── sample_patients.csv
│   │   ├── sample_visits.csv
│   │   └── sample_beds.csv
│   ├── models/
│   │   ├── staging/              # Raw source cleaning
│   │   │   ├── stg_patients.sql
│   │   │   ├── stg_visits.sql
│   │   │   └── stg_beds.sql
│   │   ├── intermediate/         # Business logic
│   │   │   ├── int_wait_times.sql
│   │   │   └── int_bed_occupancy.sql
│   │   └── marts/                # Final analytical models
│   │       ├── patient_volume.sql
│   │       ├── wait_time_analysis.sql
│   │       ├── bed_occupancy.sql
│   │       └── maternal_health_kpis.sql
│   └── tests/                    # Data quality tests
│       └── generic/
│
├── dashboards/                   # Evidence.dev pages
│   ├── index.md                  # Home / overview
│   ├── patient-volume.md
│   ├── wait-times.md
│   ├── bed-occupancy.md
│   └── maternal-health.md
│
├── docs/                         # Project documentation
│   ├── setup-guide.md
│   ├── data-dictionary.md
│   ├── contributing.md
│   └── adapting-for-your-clinic.md
│
├── .github/
│   ├── workflows/
│   │   ├── dbt-ci.yml            # Run dbt tests on PRs
│   │   └── dashboard-deploy.yml  # Deploy dashboard on merge
│   └── ISSUE_TEMPLATE/
│       ├── bug_report.md
│       └── feature_request.md
│
├── CONTRIBUTING.md
├── LICENSE                       # MIT
└── README.md                     # This file
```

---

## Available Dashboards

### 1. Patient Volume
Track daily/weekly/monthly patient registrations, broken down by department, age group, and visit type.

**Key metrics:** Total visits, new vs. returning patients, peak hours, seasonal trends.

### 2. Wait Time Analysis
Monitor how long patients wait from registration to consultation — the single biggest patient satisfaction driver.

**Key metrics:** Average wait time by department, wait time distribution, % of patients seen within 30 mins.

### 3. Bed Occupancy
Track real-time and historical bed occupancy rates across wards.

**Key metrics:** Occupancy rate, average length of stay, bed turnover rate, ward-level breakdown.

### 4. Maternal Health KPIs
WHO-aligned indicators for maternal and newborn care.

**Key metrics:** ANC attendance rate, skilled birth attendance, postnatal care coverage, low birth weight %.

---

## Adapting for Your Facility

OpenHealthDash is designed to be adapted, not just installed. See [docs/adapting-for-your-clinic.md](docs/adapting-for-your-clinic.md) for a step-by-step guide to:

- Connecting your existing HMIS or spreadsheet data
- Customising metrics for your facility's priorities
- Adding new dashboard pages

---

## Who Is This For?

- Primary healthcare clinics in Africa and low-income countries
- Health NGOs running community health programmes
- Government health departments with limited BI budgets
- Health data analysts who want reusable, open building blocks

---

## Roadmap

- [x] Project scaffolding and sample data
- [x] Core dbt models (patient volume, wait times, bed occupancy)
- [x] Evidence.dev dashboard templates
- [ ] Maternal health module
- [ ] Disease surveillance module
- [ ] Docker-based one-click deployment
- [ ] Integration adapters for OpenMRS and DHIS2
- [ ] Multi-facility / district-level rollup views

---

## Contributing

Contributions are very welcome — especially from health data professionals in Africa and the Global South.

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines. Good first issues are tagged [`good first issue`](https://github.com/latifahadamson/openhealthdash/labels/good%20first%20issue).

---

## Citation

If you use OpenHealthDash in research or reporting, please cite:

```
[Latifah Omotayo Adamson]. (2025). OpenHealthDash: Open-source healthcare analytics framework.
GitHub. https://github.com/latifahadamson/openhealthdash
```

---

## License

MIT License — free to use, modify, and distribute. See [LICENSE](LICENSE).

---

## Author

Built by Latifah Omotayo Adamson, a BI Architect focused on using open-source data tools to improve healthcare delivery in low-resource settings.

[GitHub](https://github.com/latifahadamson) · [LinkedIn](https://latifahadamson) · [Dev.to](https://dev.to/latifahadamson)

---

*If this project has helped your facility make better decisions with data, please star ⭐ the repo and share it.*

