# OpenHealthDash — Technical Walkthrough & Defense Guide

This document explains exactly what you built, why each decision was made, and how to talk about it confidently — whether that's a visa caseworker, a pilot organisation, or a technical interviewer.

---

## 1. The one-sentence pitch

> "OpenHealthDash is an open-source analytics pipeline that turns raw clinic data into business intelligence dashboards — wait times, bed occupancy — using only free, open-source tools, so that facilities who can't afford Tableau or Power BI still get the same insight."

Memorise that line. Everything else in this document supports it.

---

## 2. The big picture: how data flows through the project

Your project follows a four-layer architecture that mirrors how real BI teams structure their pipelines (often called "medallion architecture" — raw/bronze, cleaned/silver, business-ready/gold):

```
Raw data (seeds)  →  Staging models  →  Marts  →  Dashboard
   CSV files          Clean & type        Joins &     Evidence.dev
                       the data            aggregate    charts/tables
```

**Why this layering matters (and is worth saying out loud in an interview):** each layer has exactly one job.

- **Raw data** is never modified — it's the source of truth, kept exactly as it arrived.
- **Staging models** only clean and standardise — one row in, one row out, no aggregation.
- **Marts** are where the real business logic lives — joins, grouping, calculations.
- **The dashboard** only displays — it doesn't do any calculation itself, it just queries already-finished marts.

This separation is the single most important architectural decision in the project. It means if a number on the dashboard looks wrong, you know exactly which layer to check — you're never debugging a tangle of logic mixed with presentation.

---

## 3. The tech stack — and why each tool was chosen

| Tool | What it is | Why you chose it |
|---|---|---|
| **dbt Core** | SQL-based data transformation framework, used by teams at Airbnb, GitLab, and thousands of companies | Lets you write transformations as version-controlled SQL with built-in testing and documentation — the industry-standard way to build BI pipelines |
| **DuckDB** | An embedded, zero-config analytical database (think "SQLite for analytics") | No server to install, no cloud costs — perfect for prototyping, and perfect for the actual use case: clinics with no IT budget |
| **Evidence.dev** | A code-based BI tool — dashboards are written as Markdown + SQL, not clicked together in a GUI | Free and open source (unlike Tableau/Power BI), and the dashboard itself lives in version control alongside the data logic |
| **Git / GitHub** | Version control + public record | Every change is tracked, dated, and explainable — this is also your portfolio evidence |

**Talking point:** the tool choices aren't arbitrary — they directly reflect the project's mission. A clinic with no budget can't pay for Snowflake or a Tableau licence. Every tool in this stack is free, lightweight, and can run on a basic laptop. The architecture *is* the pitch.

---

## 4. File-by-file walkthrough

### 4.1 Project configuration

**`dbt_project.yml`** — tells dbt where everything lives in your project:

```yaml
model-paths: ["dbt/models"]
seed-paths: ["dbt/seeds"]
test-paths: ["dbt/tests"]
analysis-paths: ["dbt/analyses"]
macro-paths: ["dbt/macros"]

models:
  openhealthdash:
    staging:
      +materialized: view
    marts:
      +materialized: table
```

The last part is important to be able to explain: **staging models are built as views** (a saved query, recalculated every time it's read — fast to build, always fresh) while **marts are built as tables** (the result is physically stored — faster to query repeatedly, which matters for a dashboard that gets hit by many users).

**`~/.dbt/profiles.yml`** (lives outside the repo, never committed) — tells dbt *how* to connect to the database:

```yaml
openhealthdash:
  target: dev
  outputs:
    dev:
      type: duckdb
      path: 'dev.duckdb'
```

**Why this file isn't in GitHub:** profiles.yml is where database credentials normally live. Keeping it outside the repo (and in `.gitignore`) is standard security practice — even though DuckDB has no real "password" here, the habit is what matters, and it's worth mentioning that you followed this convention deliberately.

---

### 4.2 Raw data — the "seeds" layer

In dbt, **seeds** are CSV files that represent raw source data, loaded into the database exactly as-is via `dbt seed`. You built four:

| Seed file | Represents | Key columns |
|---|---|---|
| `sample_patients.csv` | Patient registry | patient_id, name, date_of_birth, gender, state, registration_date |
| `sample_visits.csv` | Outpatient visit records | visit_id, patient_id, department, registration_time, consultation_time, discharge_time |
| `sample_admissions.csv` | Inpatient stays | admission_id, patient_id, ward, admission_date, discharge_date |
| `sample_beds.csv` | Ward bed capacity | ward, total_beds |

**Important talking point — be upfront about this:** these are realistic *synthetic* datasets you created to build and demonstrate the pipeline, not real patient data. In a real deployment, this layer would be replaced by a live connection to the clinic's actual records system (EMR/HMIS) — the rest of the pipeline (staging, marts, dashboard) would work identically without changes, because it only depends on the *shape* of the data, not where it came from. This is actually a strength to point out: **the architecture is designed so swapping the data source doesn't require rewriting any logic.**

---

### 4.3 Staging layer — cleaning the raw mess

This is where every staging model lives: `with ... as (...)` blocks called CTEs (Common Table Expressions). They're used everywhere in your project — they let you break a complex query into named, readable steps instead of one giant nested query.

#### `stg_patients.sql`

```sql
with source as (
    select * from {{ ref('sample_patients') }}
),

cleaned as (
    select
        patient_id,
        concat(upper(substring(first_name,1,1)), lower(substring(first_name,2))) as first_name,
        ...
        date_of_birth::date as date_of_birth,
        upper(gender) as gender,
        ...
        date_diff('year', date_of_birth::date, current_date) as age_years,

        case
            when date_diff('year', date_of_birth::date, current_date) < 5  then 'Under 5'
            when date_diff('year', date_of_birth::date, current_date) < 18 then '5–17'
            ...
            else '60+'
        end as age_group

    from source
)

select * from cleaned
```

**What's happening, in plain terms:**
- `{{ ref('sample_patients') }}` is dbt's templating syntax — instead of hardcoding a table name, this tells dbt "depend on whatever model is called sample_patients." dbt uses every `ref()` in your project to automatically build a dependency graph, so it always runs models in the correct order.
- `::date`, `::boolean` are type casts — raw CSV data arrives as text; casting it to proper types means dates can be compared, sorted, and used in calculations.
- `date_diff('year', ..., current_date)` calculates a patient's current age from their date of birth.
- The `case when` block buckets patients into age groups — turning a continuous number into a category that's more useful for reporting ("how many patients under 5 visited this month?" is a more actionable question than raw ages).

**A genuinely good story to tell here — the `initcap` bug:** PostgreSQL and Snowflake have a built-in `initcap()` function that capitalises names properly ("amina" → "Amina"). When you ran this model, DuckDB threw an error: `Scalar Function with name initcap does not exist!`. You diagnosed that DuckDB doesn't support that function, and rebuilt the same logic manually using `concat(upper(substring(...)), lower(substring(...)))` — capitalising the first letter and lowercasing the rest. **This is worth mentioning explicitly in an interview** — it shows you can read an error message, understand *why* a database-specific function doesn't exist, and engineer an equivalent solution rather than getting stuck.

#### `stg_visits.sql`

```sql
date_diff(
    'minute',
    (visit_date::varchar || ' ' || registration_time)::timestamp,
    (visit_date::varchar || ' ' || consultation_time)::timestamp
) as wait_time_minutes
```

**What's happening:** your raw data stores `visit_date` and `registration_time` as two separate columns. To calculate a time difference, you need a single combined timestamp. The `||` operator concatenates the date and time into one string (e.g. `"2024-01-05" || " " || "08:00"` becomes `"2024-01-05 08:00"`), then `::timestamp` casts that string into a proper timestamp dbt/DuckDB can do arithmetic on. `date_diff('minute', ...)` then returns the number of minutes between registration and consultation — **this single calculated column is the core metric your entire wait-time dashboard is built on.**

#### `stg_admissions.sql`

The simplest staging model — calculates `length_of_stay_days` the same way, using `date_diff('day', admission_date, discharge_date)`.

---

### 4.4 Marts layer — where the business logic lives

This is the layer that turns "clean data" into "an answer to a real question."

#### `wait_time_analysis.sql`

```sql
joined as (
    select ...
    from visits
    left join patients
        on visits.patient_id = patients.patient_id
)

select
    department,
    count(*) as total_visits,
    round(avg(wait_time_minutes), 1) as avg_wait_time_minutes,
    ...
    round(
        100.0 * sum(case when wait_time_minutes <= 30 then 1 else 0 end) / count(*),
        1
    ) as pct_seen_within_30_mins
from joined
group by department
order by avg_wait_time_minutes desc
```

**What's happening, and why it's worth explaining well:**
- **`left join`, not `inner join`** — a left join keeps every visit row, even if a matching patient record were somehow missing. An inner join would silently drop those visits. In healthcare data, silently losing records is much worse than showing a blank field — so the choice of join type is a deliberate data-integrity decision, not a default.
- **`group by department`** collapses many individual visit rows into one summary row per department — this is the fundamental operation of "aggregation" in BI.
- **The conditional sum trick** — `sum(case when wait_time_minutes <= 30 then 1 else 0 end) / count(*)` — is a very common BI pattern worth being able to explain on the spot: for every row, the `case when` returns 1 if the condition is true and 0 if not. Summing that column counts how many rows matched. Dividing by the total row count turns that into a percentage. This exact pattern is how you'd calculate almost any "% of X meeting a target" metric in SQL.

**The actual insight this produced:** General OPD patients wait roughly 80 minutes on average, nearly 2.5x longer than Maternity patients at 32 minutes. That's a genuinely actionable finding — a real clinic could use it to investigate staffing or triage processes in General OPD specifically.

#### `bed_occupancy.sql`

```sql
ward_stats as (
    select
        ward,
        count(*) as total_admissions,
        round(avg(length_of_stay_days), 1) as avg_length_of_stay_days,
        sum(length_of_stay_days) as total_bed_days_used
    from admissions
    group by ward
)

select
    beds.ward,
    beds.total_beds,
    ...
    round(ward_stats.total_admissions::float / beds.total_beds, 1) as bed_turnover_rate,
    round(
        100.0 * ward_stats.total_bed_days_used / (beds.total_beds * 30),
        1
    ) as occupancy_rate_pct

from beds
left join ward_stats on beds.ward = ward_stats.ward
```

**What's happening:**
- This model joins two *different kinds* of data — admission events (things that happened) and bed capacity (a fixed fact about the ward) — to produce a rate that neither table could tell you alone.
- **`occupancy_rate_pct` formula explained:** `total_bed_days_used` is the sum of every patient's length of stay in that ward. Dividing by `(total_beds × 30)` gives the percentage of total possible bed-days that were actually used, assuming a 30-day window. **Be ready to name this assumption directly if asked** — it's a simplification (real systems would use the exact number of days in the reporting period, and track real-time bed status), and openly naming it shows analytical maturity rather than overselling the metric.
- **The actual insight this produced:** ICU patients stay 8 days on average — 4x longer than Paediatrics at 2 days — despite ICU having the fewest beds (5). That's the kind of number a hospital administrator would use directly for staffing and resource-allocation decisions.

---

### 4.5 The dashboard layer — Evidence.dev

Three pieces work together here:

**`sources/openhealthdash/connection.yaml`** — tells Evidence.dev where your DuckDB database file lives:
```yaml
name: openhealthdash
type: duckdb
options:
  filename: ../../../dev.duckdb
```

**`sources/openhealthdash/*.sql`** (one per table) — each file is just a single `select * from <table>` that tells Evidence which tables to pull data from and make queryable on the dashboard.

**`pages/index.md`** — the actual dashboard page, mixing Markdown with embedded SQL and chart components:

```markdown
## Wait Time Analysis by Department

```sql wait_times
select * from openhealthdash.wait_time_analysis
order by avg_wait_time_minutes desc
```

<BarChart
    data={wait_times}
    x=department
    y=avg_wait_time_minutes
    title="Average Wait Time by Department (minutes)"
/>
```

**Why this matters as a concept — "BI as code":** in a traditional tool like Tableau or Power BI, a chart is something you click and drag together in a GUI, and it lives as a binary file you can't meaningfully diff or review. Here, every chart is fully reconstructable from a plain-text SQL query and a few lines of Markdown — both checked into Git. Anyone can see exactly how a number became a chart, just by reading the file. This is a genuinely important, modern industry trend (sometimes called "BI as code") and you can speak to it directly as a deliberate choice, not an accident of the tooling.

---

## 5. The full pipeline — command reference

| Command | What it does |
|---|---|
| `dbt seed` | Loads all CSV files in `dbt/seeds/` into the DuckDB database, exactly as-is |
| `dbt run` | Executes every `.sql` model, in dependency order (staging before marts) |
| `dbt test` | *(not yet added — see Section 7)* Would run data quality checks against your models |
| `npm run sources` | Tells Evidence.dev to re-query the database and refresh its local data cache |
| `npm run dev` | Starts the local dashboard server at `localhost:3000` |

Being able to recite this sequence — and *why* each step happens in that order — is a good, simple way to demonstrate you understand the full pipeline, not just individual files.

---

## 6. Real-world value — what problem this solves

The core barrier: hospitals and clinics in low-resource settings often have patient data sitting in spreadsheets or basic record systems, but no affordable way to turn it into the kind of insight that informs decisions — because BI tools like Tableau and Power BI charge per-user licensing fees that are completely out of reach for an under-funded public health facility.

OpenHealthDash demonstrates that the *entire* BI workflow — ingest data, clean it, calculate meaningful metrics, visualise it — can be built with zero-cost, open-source tools, running on a normal laptop, with no vendor lock-in.

The two metrics built so far aren't arbitrary — they're two of the most operationally important numbers any hospital tracks:
- **Wait time by department** — directly tied to patient satisfaction and staffing decisions
- **Bed occupancy and turnover by ward** — directly tied to resource allocation and capacity planning

---

## 7. Known limitations — say these proactively, don't wait to be asked

Being able to name your own project's limitations confidently is a sign of maturity, not weakness. Have these ready:

1. **Sample data, not yet validated against a real facility's live data.** The pipeline works correctly on realistic synthetic data; the next step is testing it against a real (anonymised) dataset, which may surface edge cases this sample data doesn't have (missing values, inconsistent formats, larger volume).
2. **No automated data-quality tests yet.** dbt supports built-in tests (uniqueness, not-null, accepted values, referential integrity) — this is a planned next step, not an oversight, and you can describe exactly what you'd add (e.g. testing that `patient_id` is unique and not null in every model).
3. **The occupancy calculation assumes a fixed 30-day window**, rather than the exact number of days in whatever period is being analysed — a known simplification you'd refine for production use.
4. **Single-developer project so far.** No external contributors or code review yet — which is exactly why you're pursuing a pilot partnership and community outreach, to get real-world feedback and validation.

---

## 8. Anticipated questions & suggested answers

**"Why dbt instead of writing plain SQL scripts?"**
> "dbt adds version control, automatic dependency management, and testing on top of plain SQL. If I rename a column in a staging model, dbt knows every downstream model that depends on it and rebuilds in the right order. Plain scripts give you none of that — you'd have to track dependencies manually."

**"Why DuckDB and not PostgreSQL or a cloud warehouse like Snowflake?"**
> "DuckDB needs no server, no setup, and no ongoing cost — it runs as a single file. That directly matches the target user: a clinic with no IT budget and no dedicated database administrator. For a larger, multi-facility rollout, the architecture could swap in Postgres or a cloud warehouse without changing any of the model logic — only the connection config would change."

**"Why Evidence.dev instead of Power BI or Tableau?"**
> "Cost and transparency. Evidence is free and open source, and because dashboards are defined in version-controlled code, anyone can audit exactly how a number was calculated. Power BI and Tableau also require per-seat licensing, which is the exact barrier this project exists to remove."

**"Walk me through how a single number gets from raw data to the dashboard."**
> "Take the average wait time for General OPD. It starts as two raw timestamps in `sample_visits.csv` — registration time and consultation time. The `stg_visits` model combines those into proper timestamps and calculates the difference in minutes as `wait_time_minutes`. The `wait_time_analysis` mart then groups all visits by department and averages that column. Evidence.dev queries that finished mart table directly and renders it as a bar chart — no calculation happens in the dashboard itself."

**"What was the hardest technical problem you solved?"**
> "DuckDB doesn't support the `initcap()` function that other databases like Postgres have, which I needed to properly capitalise patient names. I diagnosed the error message, understood that DuckDB had a different function set, and rebuilt the same result using a combination of `substring`, `upper`, and `lower` instead. It was a small fix, but it's a good example of adapting to a specific tool's constraints rather than assuming SQL behaves identically everywhere."

**"What would you need to do to move this to production with a real clinic?"**
> "Three things: connect to their actual data source instead of sample CSVs — which the architecture already supports without changing any model logic; add dbt tests for data quality, since real-world data is messier than sample data; and get a formal feedback loop with clinic staff to validate that the metrics I'm calculating actually match what they need for decisions."

**"How would this scale to multiple facilities?"**
> "Each model would add a `facility_id` column so I can filter or compare across locations, and I'd add a facility-level dimension table. The current architecture already separates raw data from business logic, so scaling to multiple facilities is mostly a matter of adding that dimension — not rebuilding the pipeline."

---

## 9. Your 60-second elevator pitch (memorise this)

> "I built OpenHealthDash, an open-source analytics tool for clinics and health NGOs that can't afford BI software like Tableau or Power BI. It's a full pipeline — I use dbt to clean and transform raw patient, visit, and admission data, DuckDB as a free embedded database, and Evidence.dev to turn that data into live dashboards. Right now it calculates two real operational metrics: average wait time by department, and bed occupancy and turnover by ward — both things hospital administrators actually use to make staffing and resourcing decisions. Everything in the stack is free and open source, which matters because the whole point of the project is removing the cost barrier that keeps under-resourced facilities from getting the same data insight that well-funded hospitals take for granted."

---

*Keep this document for your own reference — you don't need to memorise all of it, just be comfortable enough that you could explain any single piece if someone asked "what does this part do?"*
