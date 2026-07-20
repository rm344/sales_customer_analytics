{{ config(materialized='view', schema='reporting') }}

with customer as (

    select
        customer_key,
        age_segment,
        loyalty_tier,
        income_bracket,
        is_current
    from {{ ref('dim_customer') }}
    where is_current = true

),

sales as (

    select
        customer_key,
        order_id,
        total_sales_amount,
        profit_amount,
        quantity_sold
    from {{ ref('fact_sales') }}

),

customer_metrics as (

    select

        c.customer_key,

        c.age_segment,

        c.loyalty_tier,

        c.income_bracket,

        count(distinct s.order_id) as total_orders,

        sum(s.total_sales_amount) as total_spend,

        sum(s.profit_amount) as total_profit,

        sum(s.quantity_sold) as total_units_sold

    from customer c

    left join sales s
        on c.customer_key = s.customer_key

    group by
        c.customer_key,
        c.age_segment,
        c.loyalty_tier,
        c.income_bracket

)


select

    age_segment,

    count(customer_key) as total_customers,

    sum(total_orders) as total_orders,

    sum(total_spend) as total_revenue,

    sum(total_profit) as total_profit,

    round(
        avg(total_spend),
        2
    ) as avg_customer_value,

    round(
        avg(total_orders),
        2
    ) as avg_order_per_customer,

    round(
        sum(total_profit) * 100.0 /
        nullif(sum(total_spend), 0),
        2
    ) as profit_margin_percent,

    round(
        sum(total_spend) * 100.0 /
        sum(sum(total_spend)) over (),
        2
    ) as revenue_contribution_percent

from customer_metrics

group by age_segment

order by total_revenue desc