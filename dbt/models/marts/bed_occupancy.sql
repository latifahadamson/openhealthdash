-- bed_occupancy.sql
-- Calculates bed occupancy and turnover rates by ward

with admissions as (
    select * from {{ ref('stg_admissions') }}
),

beds as (
    select * from {{ ref('sample_beds') }}
),

ward_stats as (
    select
        ward,
        count(*)                              as total_admissions,
        round(avg(length_of_stay_days), 1)    as avg_length_of_stay_days,
        sum(length_of_stay_days)              as total_bed_days_used
    from admissions
    group by ward
)

select
    beds.ward,
    beds.total_beds,
    ward_stats.total_admissions,
    ward_stats.avg_length_of_stay_days,
    ward_stats.total_bed_days_used,

    -- Bed turnover rate: how many patients passed through each bed
    round(ward_stats.total_admissions::float / beds.total_beds, 1) as bed_turnover_rate,

    -- Approximate occupancy rate over a 30-day period
    round(
        100.0 * ward_stats.total_bed_days_used / (beds.total_beds * 30),
        1
    ) as occupancy_rate_pct

from beds
left join ward_stats
    on beds.ward = ward_stats.ward
order by occupancy_rate_pct desc
