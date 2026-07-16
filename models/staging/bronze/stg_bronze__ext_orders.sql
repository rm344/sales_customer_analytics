with 

source as (

    select * from {{ source('bronze', 'ext_orders') }}

),

renamed as (

    select

    from source

)

select * from renamed