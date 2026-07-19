{% macro generate_bronze_incremental(source_name, source_table) %}

{{
    config(
        materialized='incremental',
        unique_key='_source_file',
        incremental_strategy='merge'
    )
}}

select
    metadata$filename                                                  as _source_file,
    current_timestamp()::timestamp_ntz                                 as _loaded_at,
    '{{ invocation_id }}'                                              as _batch_id,
    coalesce(value:updated_at::timestamp, metadata$file_last_modified) as file_last_modified,
    value                                                              as raw_json_payload

from {{ source(source_name, source_table) }}

{% if is_incremental() %}
  where coalesce(value:updated_at::timestamp, metadata$file_last_modified)
        > (select max(file_last_modified) from {{ this }})
{% endif %}

{% endmacro %}