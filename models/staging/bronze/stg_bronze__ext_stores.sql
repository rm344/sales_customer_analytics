with 

source as (

    select * from {{ source('bronze', 'ext_stores') }}

),

renamed as (

    select

    from source

)

select * from renamed