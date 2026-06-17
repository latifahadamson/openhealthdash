-- stg_patients.sql
-- Cleans and standardises raw patient data

with source as (
    select * from {{ ref('sample_patients') }}
),

cleaned as (
    select
        patient_id,
        concat(upper(substring(first_name,1,1)), lower(substring(first_name,2))) as first_name,
        concat(upper(substring(last_name,1,1)), lower(substring(last_name,2)))   as last_name,
        date_of_birth::date                             as date_of_birth,
        upper(gender)                                   as gender,
        concat(upper(substring(state,1,1)), lower(substring(state,2)))          as state,
        registration_date::date                         as registration_date,
        is_active::boolean                              as is_active,

        date_diff('year', date_of_birth::date, current_date) as age_years,

        case
            when date_diff('year', date_of_birth::date, current_date) < 5  then 'Under 5'
            when date_diff('year', date_of_birth::date, current_date) < 18 then '5–17'
            when date_diff('year', date_of_birth::date, current_date) < 35 then '18–34'
            when date_diff('year', date_of_birth::date, current_date) < 60 then '35–59'
            else '60+'
        end                                             as age_group

    from source
)

select * from cleaned