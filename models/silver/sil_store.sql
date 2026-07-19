with source_data as (
    select *
    from {{ ref('snp_store') }}
    where dbt_valid_to is null
),

extracted as (
    select
        store_id_clean                                          as store_id,
        raw_json_payload:store_name::string                     as store_name,
        raw_json_payload:store_type::string                     as store_type,
        raw_json_payload:region::string                         as region,
        raw_json_payload:email::string                          as email,
        raw_json_payload:phone_number::string                   as phone_number,
        raw_json_payload:manager_id::string                     as manager_id,
        raw_json_payload:opening_date::string                   as opening_date,
        raw_json_payload:size_sq_ft::number                     as size_sq_ft,
        raw_json_payload:employee_count::number                 as employee_count,
        raw_json_payload:sales_target::float                    as sales_target,
        raw_json_payload:current_sales::float                   as current_sales,
        raw_json_payload:monthly_rent::float                    as monthly_rent,
        raw_json_payload:is_active::boolean                     as is_active,
        raw_json_payload:operating_hours:weekdays::string       as hours_weekdays,
        raw_json_payload:operating_hours:weekends::string       as hours_weekends,
        raw_json_payload:operating_hours:holidays::string       as hours_holidays,
        array_to_string(raw_json_payload:services::array, ', ') as services,
        raw_json_payload:address:street::string                 as street,
        raw_json_payload:address:city::string                   as city,
        raw_json_payload:address:state::string                  as state,
        raw_json_payload:address:zip_code::string               as zip_code,
        raw_json_payload:address:country::string                as country,
        last_modified_date_clean
    from source_data
),

cleaned as (
    select
        upper(trim(store_id))                                   as store_id,
        initcap(trim(store_name))                               as store_name,
        initcap(trim(store_type))                               as store_type,
        initcap(trim(region))                                   as region,

        case
            when email like '%_@_%.com' then lower(trim(email))
            else null
        end                                                       as email,

        case
            when regexp_like(phone_number, '^[0-9()\\-\\s+]+$') then regexp_replace(phone_number, '[^0-9]', '')
            else null
        end                                                       as phone_number,

        upper(trim(manager_id))                                 as manager_id,

        try_to_date(opening_date)                               as opening_date,
        datediff(year, try_to_date(opening_date), current_date()) as store_age_years,

        size_sq_ft,
        case
            when size_sq_ft < 5000 then 'Small'
            when size_sq_ft >= 5000 and size_sq_ft <= 10000 then 'Medium'
            when size_sq_ft > 10000 then 'Large'
        end                                                       as size_category,

        employee_count,
        sales_target,
        current_sales,
        monthly_rent,
        is_active,

        case
            when sales_target > 0 then round((current_sales / sales_target) * 100, 2)
            else null
        end                                                       as sales_target_achievement_percentage,

        case
            when size_sq_ft > 0 then round(current_sales / size_sq_ft, 2)
            else null
        end                                                       as revenue_per_sq_ft,

        case
            when employee_count > 0 then round(current_sales / employee_count, 2)
            else null
        end                                                       as employee_efficiency,

        case
            when sales_target > 0 and (current_sales / sales_target) * 100 < 90 then true
            else false
        end                                                       as has_performance_issue,

        hours_weekdays,
        hours_weekends,
        hours_holidays,
        services,

        initcap(trim(street))                                    as street,
        initcap(trim(city))                                      as city,
        upper(trim(state))                                       as state,
        substring(zip_code, 1, 5)                                as zip_code,
        upper(trim(country))                                     as country,

        last_modified_date_clean

    from extracted
)

select * from cleaned