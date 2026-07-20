{% snapshot snp_product %}

{{
    config(
      target_schema='snapshot',
      unique_key='product_id_clean',
      strategy='timestamp',
      updated_at='last_modified_date_clean',
      invalidate_hard_deletes=True
    )
}}

with unwrapped as (
    select
        prod.value                      as product_json,
        file_last_modified,
        _batch_id,
        _loaded_at,
        _source_file
    from {{ ref('products') }},
         lateral flatten(input => raw_json_payload:products_data) prod
),

extracted as (
    select
        product_json:product_id::string   as product_id,
        product_json                        as raw_json_payload,
        file_last_modified,
        _batch_id,
        _loaded_at,
        _source_file
    from unwrapped
),

cleaned as (
    select
        *,
        trim(product_id) as product_id_clean,
        coalesce(file_last_modified, _loaded_at) as last_modified_date_clean
    from extracted
)

select *
from cleaned
where product_id_clean is not null
  and product_id_clean != ''
qualify row_number() over (
    partition by product_id_clean
    order by last_modified_date_clean desc, _loaded_at desc
) = 1

{% endsnapshot %}