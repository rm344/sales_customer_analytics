with source_data as (
    select *
    from {{ ref('snp_employee') }}
    where dbt_valid_to is null
),

extracted as (
    select
        employee_id_clean                                      as employee_id,
        raw_json_payload:first_name::string                    as first_name,
        raw_json_payload:last_name::string                     as last_name,
        raw_json_payload:email::string                         as email,
        raw_json_payload:phone::string                         as phone,
        raw_json_payload:date_of_birth::string                 as date_of_birth,
        raw_json_payload:hire_date::string                     as hire_date,
        raw_json_payload:department::string                    as department,
        raw_json_payload:role::string                          as role,
        raw_json_payload:employment_status::string             as employment_status,
        raw_json_payload:manager_id::string                    as manager_id,
        raw_json_payload:education::string                     as education,
        raw_json_payload:salary::float                         as salary,
        raw_json_payload:performance_rating::float             as performance_rating,
        raw_json_payload:current_sales::float                  as current_sales,
        raw_json_payload:sales_target::float                   as sales_target,
        raw_json_payload:work_location::string                 as work_location,
        raw_json_payload:address:city::string                  as city,
        raw_json_payload:address:state::string                 as state,
        raw_json_payload:address:street::string                as street,
        raw_json_payload:address:zip_code::string               as zip_code,
        array_to_string(raw_json_payload:certifications::array, ', ') as certifications,
        last_modified_date_clean
    from source_data
),

cleaned as (
    select
        upper(trim(employee_id))                                as employee_id,
        initcap(trim(first_name)) || ' ' || initcap(trim(last_name)) as full_name,

        case
            when email like '%_@_%.com' then lower(trim(email))
            else null
        end                                                       as email,

        case
            when left(regexp_replace(phone, '[^0-9]', ''), 1) = '1'
                then concat('+', regexp_replace(phone, '[^0-9]', ''))
            else concat('+1', regexp_replace(phone, '[^0-9]', ''))
        end                                                       as phone,

        try_to_date(date_of_birth)                               as date_of_birth,
        try_to_date(hire_date)                                   as hire_date,
        datediff(year, try_to_date(hire_date), current_date())  as tenure_years,

        initcap(trim(department))                                as department,

        case
            when trim(role) ilike 'Senior Manager'   then 'Senior Manager'
            when trim(role) ilike '%Associate'       then 'Associate'
            when trim(role) ilike '%Manager'         then 'Manager'
            when trim(role) ilike '%Specialist'      then 'Specialist'
            else initcap(trim(role))
        end                                                       as role,

        initcap(trim(employment_status))                          as employment_status,

        upper(trim(manager_id))                                   as manager_id,
        initcap(trim(education))                                  as education,
        salary,
        performance_rating,
        current_sales,
        sales_target,
        upper(trim(work_location))                                as work_location,
        initcap(trim(city))                                       as city,
        upper(trim(state))                                        as state,
        initcap(trim(street))                                     as street,
        substring(zip_code, 1, 5)                                 as zip_code,
        certifications,
        last_modified_date_clean

    from extracted
),

orders_deduped as (
    select
        raw_json_payload:employee_id::string  as employee_id,
        raw_json_payload:order_id::string     as order_id,
        raw_json_payload:total_amount::float  as total_amount
    from {{ ref('snp_orders') }}
    where dbt_valid_to is null
      and raw_json_payload:employee_id::string is not null
    qualify row_number() over (
        partition by raw_json_payload:order_id::string
        order by _loaded_at desc
    ) = 1
),

order_metrics as (
    select
        employee_id,
        count(distinct order_id)         as orders_processed,
        sum(coalesce(total_amount, 0))   as total_sales_amount
    from orders_deduped
    group by employee_id
),

final as (
    select
        c.*,
        coalesce(om.orders_processed, 0)             as orders_processed,
        round(coalesce(om.total_sales_amount, 0), 2) as total_sales_amount,

        case
            when c.sales_target > 0
            then round((coalesce(om.total_sales_amount, 0) * 100 / c.sales_target), 2)
            else null
        end as target_achievement_percentage

    from cleaned c
    left join order_metrics om
        on c.employee_id = om.employee_id
)

select * from final