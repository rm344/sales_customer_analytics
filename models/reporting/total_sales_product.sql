{{ config(materialized='view', schema='reporting') }}

select
    p.category,
    p.subcategory,
    count(distinct f.order_id)       as total_orders,
    sum(f.quantity_sold)              as total_units_sold,
    sum(f.total_sales_amount)          as total_sales_amount,
    sum(f.cost_amount)                  as total_cost_amount,
    sum(f.profit_amount)                 as total_profit_amount,
    case
        when sum(f.total_sales_amount) > 0
        then round((sum(f.profit_amount) / sum(f.total_sales_amount)) * 100, 2)
        else null
    end                                    as profit_margin_percentage

from {{ ref('fact_sales') }} f
join {{ ref('dim_product') }} p
    on f.product_key = p.product_key

group by p.category, p.subcategory
order by total_sales_amount desc