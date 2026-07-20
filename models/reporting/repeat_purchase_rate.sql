{{ config(materialized='view', schema='reporting') }}

with customer_orders as (
    select
        customer_key,
        count(distinct order_id) as total_orders

    from {{ ref('fact_sales') }}

    group by
        customer_key
)

select
    count(customer_key) as total_customers,
    count(
        case
            when total_orders > 1
            then customer_key
        end
    ) as repeat_customers,
    round(
        count(
            case
                when total_orders > 1
                then customer_key
            end
        ) * 100.0
        / nullif(count(customer_key), 0),
        2
    ) as repeat_purchase_rate_percent

from customer_orders