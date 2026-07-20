{{ config(materialized='view', schema='reporting') }}

select
    dc.customer_id,
    dc.full_name,
    dc.age_segment,

    count(distinct fs.order_id) as total_orders,
    round(sum(fs.total_sales_amount), 2) as lifetime_value

from {{ ref('fact_sales') }} fs

left join {{ ref('dim_customer') }} dc
    on fs.customer_key = dc.customer_key
group by
    dc.customer_id,
    dc.full_name,
    dc.age_segment

order by
    lifetime_value desc