-- stg_admissions.sql
-- Cleans admission records and calculates length of stay

with source as (
    select * from {{ ref('sample_admissions') }}
),

cleaned as (
    select
        admission_id,
        patient_id,
        ward,
        admission_date::date  as admission_date,
        discharge_date::date  as discharge_date,

        date_diff('day', admission_date::date, discharge_date::date) as length_of_stay_days

    from source
)

select * from cleaned
