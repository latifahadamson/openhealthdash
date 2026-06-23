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

## Patient Overview

```sql patients
select * from openhealthdash.patients
```

<DataTable data={patients} />
