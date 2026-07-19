{% snapshot snp_orders %}

{{
    config(
      target_schema='snapshot',
      unique_key=['order_id_clean', 'product_id_clean'],
      strategy='timestamp',
      updated_at='last_modified_date_clean',
      invalidate_hard_deletes=True
    )
}}

with orders_unwrapped as (
    select
        ord.value                       as order_json,
        file_last_modified,
        _batch_id,
        _loaded_at,
        _source_file
    from {{ ref('orders') }},
         lateral flatten(input => raw_json_payload:orders_data) ord
),

extracted as (
    select
        order_json:order_id::string      as order_id,
        item.value:product_id::string     as product_id,
        order_json                        as raw_json_payload,
        file_last_modified,
        _batch_id,
        _loaded_at,
        _source_file
    from orders_unwrapped,
         lateral flatten(input => order_json:order_items) item
),

cleaned as (
    select
        *,
        trim(order_id) as order_id_clean,
        trim(product_id) as product_id_clean,
        coalesce(file_last_modified, _loaded_at) as last_modified_date_clean
    from extracted
)

select *
from cleaned
where order_id_clean is not null and order_id_clean != ''
  and product_id_clean is not null and product_id_clean != ''
qualify row_number() over (
    partition by order_id_clean, product_id_clean
    order by last_modified_date_clean desc, _loaded_at desc
) = 1

{% endsnapshot %}