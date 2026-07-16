with 

source as (

    select * from {{ source('raw_data', 'ext_customer') }}

),

renamed as (

    select
        value
    from source

)

select * from renamed