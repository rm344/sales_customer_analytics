with source_data as (
    select *
    from {{ ref('snp_customer') }}
),

extracted as (
    select
        customer_id_clean                                       as customer_id,
        raw_json_payload:first_name::string                     as first_name,
        raw_json_payload:last_name::string                      as last_name,
        raw_json_payload:email::string                          as email,
        raw_json_payload:phone::string                          as phone,
        raw_json_payload:birth_date::string                     as birth_date_raw,
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
        dbt_valid_from,
        dbt_valid_to
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

        coalesce(
            try_to_date(birth_date_raw, 'YYYY-MM-DD'),
            try_to_date(birth_date_raw, 'MM-DD-YYYY'),
            try_to_date(birth_date_raw, 'DD-MM-YYYY'),
            try_to_date(birth_date_raw, 'YYYY/MM/DD'),
            try_to_date(birth_date_raw, 'MM/DD/YYYY'),
            try_to_date(birth_date_raw, 'DD/MM/YYYY')
        ) as birth_date_parsed,

        datediff(year, birth_date_parsed, current_date())              as age,

        case
            when birth_date_parsed is null then 'Unknown'
            when datediff(year, birth_date_parsed, current_date()) between 18 and 35 then 'Young'
            when datediff(year, birth_date_parsed, current_date()) between 36 and 55 then 'Middle-aged'
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

        dbt_valid_from                                            as valid_from,
        dbt_valid_to                                              as valid_to,
        (dbt_valid_to is null)                                    as is_current

    from extracted
)

select
    customer_id,
    full_name,
    email,
    phone,
    birth_date_parsed as birth_date,
    age,
    age_segment,
    registration_date,
    last_purchase_date,
    income_bracket,
    loyalty_tier,
    occupation,
    preferred_communication,
    preferred_payment_method,
    marketing_opt_in,
    total_purchases,
    total_spend,
    street,
    city,
    state,
    zip_code,
    country,
    valid_from,
    valid_to,
    is_current
from cleaned