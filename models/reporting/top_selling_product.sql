{{ config(materialized='view', schema='reporting') }}

select
    p.product_name,
    p.category,

    sum(f.quantity_sold) as units_sold,

    sum(f.total_sales_amount) as total_sales

from {{ ref('fact_sales') }} f

left join {{ ref('dim_product') }} p

    on f.product_key = p.product_key

group by

    p.product_name,
    p.category

order by
    total_sales desc