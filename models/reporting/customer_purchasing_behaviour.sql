{{ config(materialized='view', schema='reporting') }}

select
    dc.customer_id,
    dc.full_name,
    dc.age_segment,
    count(distinct fs.order_id) as total_orders,
    sum(fs.quantity_sold) as total_items_purchased,
    sum(fs.total_sales_amount) as total_spend,
    round(sum(fs.total_sales_amount) / count(distinct fs.order_id), 2) as avg_order_value

from {{ ref('fact_sales') }} fs

left join {{ ref('dim_customer') }} dc
    on fs.customer_key = dc.customer_key

group by
    dc.customer_id,
    dc.full_name,
    dc.age_segment

order by
    total_spend desc