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

## Patient Overview

```sql patients
select * from openhealthdash.patients
```

<DataTable data={patients} />