{% snapshot snp_employee %}

{{
    config(
      target_schema='snapshot',
      unique_key='employee_id_clean',
      strategy='timestamp',
      updated_at='last_modified_date_clean',
      invalidate_hard_deletes=True
    )
}}

with unwrapped as (
    select
        emp.value                       as employee_json,
        file_last_modified,
        _batch_id,
        _loaded_at,
        _source_file
    from {{ ref('employee') }},
         lateral flatten(input => raw_json_payload:employees_data) emp
),

extracted as (
    select
        employee_json:employee_id::string   as employee_id,
        employee_json                        as raw_json_payload,
        file_last_modified,
        _batch_id,
        _loaded_at,
        _source_file
    from unwrapped
),

cleaned as (
    select
        *,
        trim(employee_id) as employee_id_clean,
        coalesce(file_last_modified, _loaded_at) as last_modified_date_clean
    from extracted
)

select *
from cleaned
where employee_id_clean is not null
  and employee_id_clean != ''
qualify row_number() over (
    partition by employee_id_clean
    order by last_modified_date_clean desc, _loaded_at desc
) = 1

{% endsnapshot %}