{% snapshot snp_store %}

{{
    config(
      target_schema='snapshot',
      unique_key='store_id_clean',
      strategy='timestamp',
      updated_at='last_modified_date_clean',
      invalidate_hard_deletes=True
    )
}}

with unwrapped as (
    select
        st.value                        as store_json,
        file_last_modified,
        _batch_id,
        _loaded_at,
        _source_file
    from {{ ref('store') }},
         lateral flatten(input => raw_json_payload:stores_data) st
),

extracted as (
    select
        store_json:store_id::string       as store_id,
        store_json                         as raw_json_payload,
        file_last_modified,
        _batch_id,
        _loaded_at,
        _source_file
    from unwrapped
),

cleaned as (
    select
        *,
        trim(store_id) as store_id_clean,
        coalesce(file_last_modified, _loaded_at) as last_modified_date_clean
    from extracted
)

select *
from cleaned
where store_id_clean is not null
  and store_id_clean != ''
qualify row_number() over (
    partition by store_id_clean
    order by last_modified_date_clean desc, _loaded_at desc
) = 1

{% endsnapshot %}