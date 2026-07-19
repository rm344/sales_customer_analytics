{% snapshot snp_customer %}

{{
    config(
      target_schema='snapshot',
      unique_key='customer_id_clean',
      strategy='timestamp',
      updated_at='last_modified_date_clean',
      invalidate_hard_deletes=True
    )
}}

with unwrapped as (
    select
        cust.value                      as customer_json,
        file_last_modified,
        _batch_id,
        _loaded_at,
        _source_file
    from {{ ref('customer') }},
         lateral flatten(input => raw_json_payload:customers_data) cust
),

extracted as (
    select
        customer_json:customer_id::string   as customer_id,
        customer_json                        as raw_json_payload,
        file_last_modified,
        _batch_id,
        _loaded_at,
        _source_file
    from unwrapped
),

cleaned as (
    select
        *,
        trim(customer_id) as customer_id_clean,
        coalesce(file_last_modified, _loaded_at) as last_modified_date_clean
    from extracted
)

select *
from cleaned
where customer_id_clean is not null
  and customer_id_clean != ''
qualify row_number() over (
    partition by customer_id_clean
    order by last_modified_date_clean desc, _loaded_at desc
) = 1

{% endsnapshot %}