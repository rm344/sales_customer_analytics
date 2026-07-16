with 

source as (

    select * from {{ source('bronze', 'ext_products') }}

),

renamed as (

    select

    from source

)

select * from renamed