-- stg_visits.sql
-- Cleans visit data and calculates patient wait times

with source as (
    select * from {{ ref('sample_visits') }}
),

cleaned as (
    select
        visit_id,
        patient_id,
        visit_date::date                                        as visit_date,
        department,
        registration_time::time                                 as registration_time,
        consultation_time::time                                 as consultation_time,
        discharge_time::time                                    as discharge_time,
        visit_type,
        diagnosis_category,

        -- Wait time in minutes: registration -> consultation
        date_diff(
            'minute',
            (visit_date::varchar || ' ' || registration_time)::timestamp,
            (visit_date::varchar || ' ' || consultation_time)::timestamp
        )                                                       as wait_time_minutes,

        -- Total visit duration: registration -> discharge
        date_diff(
            'minute',
            (visit_date::varchar || ' ' || registration_time)::timestamp,
            (visit_date::varchar || ' ' || discharge_time)::timestamp
        )                                                       as total_visit_duration_minutes,

        dayname(visit_date::date)                               as visit_day_of_week

    from source
)

select * from cleaned