with source_data as (
    select *
    from {{ ref('snp_customer') }}
    where dbt_valid_to is null
),

extracted as (
    select
        customer_id_clean                                       as customer_id,
        raw_json_payload:first_name::string                     as first_name,
        raw_json_payload:last_name::string                      as last_name,
        raw_json_payload:email::string                          as email,
        raw_json_payload:phone::string                          as phone,
        raw_json_payload:birth_date::string                     as birth_date,
        raw_json_payload:registration_date::string              as registration_date,
        raw_json_payload:last_purchase_date::string             as last_purchase_date,
        raw_json_payload:income_bracket::string                 as income_bracket,
        raw_json_payload:loyalty_tier::string                   as loyalty_tier,
        raw_json_payload:occupation::string                     as occupation,
        raw_json_payload:preferred_communication::string        as preferred_communication,
        raw_json_payload:preferred_payment_method::string       as preferred_payment_method,
        raw_json_payload:marketing_opt_in::boolean              as marketing_opt_in,
        raw_json_payload:total_purchases::number                as total_purchases,
        raw_json_payload:total_spend::float                     as total_spend,
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
        upper(trim(customer_id))                                        as customer_id,
        initcap(trim(first_name)) || ' ' || initcap(trim(last_name))    as full_name,

        case
            when email like '%_@_%.com' then lower(trim(email))
            else null
        end                                                             as email,

        regexp_replace(phone, '[^0-9A-Za-z]', '')                       as phone,

        try_to_date(birth_date)                                         as birth_date,
        datediff(year, try_to_date(birth_date), current_date())         as age,

        case
            when datediff(year, try_to_date(birth_date), current_date()) between 18 and 35 then 'Young'
            when datediff(year, try_to_date(birth_date), current_date()) between 36 and 55 then 'Middle-aged'
            else 'Senior'
        end                                                             as age_segment,

        try_to_date(registration_date)                                  as registration_date,
        try_to_date(last_purchase_date)                                 as last_purchase_date,

        upper(trim(income_bracket))                                     as income_bracket,
        initcap(trim(loyalty_tier))                                     as loyalty_tier,
        initcap(trim(occupation))                                       as occupation,
        upper(trim(preferred_communication))                            as preferred_communication,
        initcap(trim(preferred_payment_method))                         as preferred_payment_method,
        marketing_opt_in,
        total_purchases,
        total_spend,

        initcap(trim(street))                                     as street,
        initcap(trim(city))                                       as city,
        upper(trim(state))                                        as state,
        substring(zip_code, 1, 5)                                 as zip_code,
        upper(trim(country))                                      as country,

        last_modified_date_clean

    from extracted
)

select * from cleaned