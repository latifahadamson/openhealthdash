# OpenHealthDash

Welcome to your healthcare analytics dashboard — built on real patient and visit data.

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

<DataTable data={wait_times} />

## Bed Occupancy by Ward

```sql bed_occupancy
select
    ward,
    total_beds,
    total_admissions,
    avg_length_of_stay_days,
    total_bed_days_used,
    bed_turnover_rate,
    occupancy_rate_pct / 100 as occupancy_rate_pct
from openhealthdash.bed_occupancy
order by occupancy_rate_pct desc
```

<BarChart
    data={bed_occupancy}
    x=ward
    y=occupancy_rate_pct
    title="Bed Occupancy Rate by Ward"
/>

<DataTable data={bed_occupancy} />

## National Context: Nigeria Health Workforce Trends (WHO Data)

This section uses real, published WHO Global Health Observatory data — shown alongside this project's facility-level analysis for national context.

```sql workforce
select * from openhealthdash.national_health_context
where indicator != 'Hospital beds'
order by year
```

<LineChart
    data={workforce}
    x=year
    y=value_per_10000_population
    series=indicator
    title="Health Workforce per 10,000 Population (Nigeria, WHO data)"
/>

<DataTable data={workforce} />

*Note: WHO's most recent published figure for hospital beds in Nigeria is 5.0 per 10,000 population, dating to 2004 — included here for transparency, though it is too dated to treat as a current benchmark. Source: [WHO Global Health Observatory](https://www.who.int/data/gho)*

## Patient Overview

```sql patients
select * from openhealthdash.patients
```

<DataTable data={patients} />
