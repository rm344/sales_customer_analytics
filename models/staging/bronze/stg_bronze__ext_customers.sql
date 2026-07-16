with 

source as (

    select * from {{ source('bronze', 'ext_customers') }}

),

renamed as (

    select

    from source

)

select * from renamed