-- national_health_context.sql
-- Real WHO Global Health Observatory data for Nigeria
-- Source: WHO GHO (https://www.who.int/data/gho)
-- Used as national-level context alongside this project's facility-level analysis

select
    year,
    indicator,
    value_per_10000_population
from {{ ref('who_workforce_indicators') }}
order by indicator, year
