{{ config(materialized='table', schema='gold') }}

with date_spine as (

    select dateadd(day, seq4(), '2024-04-01'::date) as full_date
    from table(generator(rowcount => 365))
    where full_date <= '2024-09-27'::date

),

enriched as (

    select
        full_date,
        year(full_date)                          as year,
        quarter(full_date)                        as quarter,
        month(full_date)                           as month,
        week(full_date)                             as week,
        dayofweek(full_date)                          as day_of_week_num,
        dayname(full_date)                              as day_of_week_name,

        case
            when dayofweek(full_date) in (0, 6) then true
            else false
        end                                                as is_weekend,

        case
            when month(full_date) in (12, 1, 2)  then 'Winter'
            when month(full_date) in (3, 4, 5)    then 'Spring'
            when month(full_date) in (6, 7, 8)    then 'Summer'
            when month(full_date) in (9, 10, 11)  then 'Fall'
        end                                                 as season,

        case
            when (month(full_date) = 1  and day(full_date) = 1)  then true  -- New Year's Day
            when (month(full_date) = 7  and day(full_date) = 4)  then true  -- July 4th
            when (month(full_date) = 12 and day(full_date) = 25) then true  -- Christmas
            when (month(full_date) = 11 and dayofweek(full_date) = 4 and day(full_date) between 22 and 28) then true -- Thanksgiving approx
            else false
        end                                                 as is_us_holiday

    from date_spine

)

select
    md5(cast(full_date as varchar)) as date_key,
    full_date,
    year,
    quarter,
    month,
    week,
    day_of_week_num,
    day_of_week_name,
    is_weekend,
    season,
    is_us_holiday
from enriched