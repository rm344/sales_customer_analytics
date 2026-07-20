{{ config(materialized='view', schema='reporting') }}

select
    d.year,
    d.month,
    s.region,
    count(distinct f.order_id) as total_orders,
    sum(f.total_sales_amount) as total_sales
 
from {{ ref('fact_sales') }} f

left join {{ ref('dim_store') }} s
    on f.store_key = s.store_key
left join {{ ref('dim_date') }} d
    on f.date_key = d.date_key
group by
    d.year,
    d.month,
    s.region
order by
    d.year,
    d.month,
    total_sales desc