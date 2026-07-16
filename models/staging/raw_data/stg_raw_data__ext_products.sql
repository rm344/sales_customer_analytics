with 

source as (

    select * from {{ source('raw_data', 'ext_products') }}

),

renamed as (

    select
        value as raw_json_payload
    from source

)

select * from renamed