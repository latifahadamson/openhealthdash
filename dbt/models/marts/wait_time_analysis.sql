-- wait_time_analysis.sql
-- Combines patient and visit data to analyze wait times by department

with visits as (
    select * from {{ ref('stg_visits') }}
),

patients as (
    select * from {{ ref('stg_patients') }}
),

joined as (
    select
        visits.visit_id,
        visits.visit_date,
        visits.department,
        visits.visit_type,
        visits.diagnosis_category,
        visits.wait_time_minutes,
        visits.total_visit_duration_minutes,
        visits.visit_day_of_week,
        patients.patient_id,
        patients.gender,
        patients.age_group,
        patients.state
    from visits
    left join patients
        on visits.patient_id = patients.patient_id
)

select
    department,
    count(*)                                       as total_visits,
    round(avg(wait_time_minutes), 1)               as avg_wait_time_minutes,
    min(wait_time_minutes)                         as min_wait_time_minutes,
    max(wait_time_minutes)                         as max_wait_time_minutes,
    round(avg(total_visit_duration_minutes), 1)    as avg_visit_duration_minutes,
    round(
        100.0 * sum(case when wait_time_minutes <= 30 then 1 else 0 end) / count(*),
        1
    )                                               as pct_seen_within_30_mins
from joined
group by department
order by avg_wait_time_minutes desc