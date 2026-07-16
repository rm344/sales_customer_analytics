with 

source as (

    select * from {{ source('bronze', 'ext_employees') }}

),

renamed as (

    select

    from source

)

select * from renamed