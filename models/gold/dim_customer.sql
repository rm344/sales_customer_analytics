{{ config(materialized='table', schema='gold') }}

select
    md5(
        coalesce(cast(customer_id as varchar), '') || '|' ||
        coalesce(cast(valid_from as varchar), '')
    )                                as customer_key,
    customer_id,
    full_name,
    email,
    phone,
    birth_date,
    age_segment,
    registration_date,
    income_bracket,
    loyalty_tier,
    street,
    city,
    state,
    zip_code,
    country,
    valid_from,
    valid_to,
    is_current
from {{ ref('sil_customer') }}