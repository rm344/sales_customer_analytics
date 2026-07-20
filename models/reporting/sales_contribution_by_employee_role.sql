{{ config(materialized='view') }}

with sales as (

    select
        employee_key,
        order_id,
        total_sales_amount,
        profit_amount
    from {{ ref('fact_sales') }}

),

employees as (

    select
        employee_key,
        role,
        orders_processed,
        performance_rating,
        target_achievement_percentage
    from {{ ref('dim_employee') }}

),

role_summary as (

    select
        e.role,
        count(distinct e.employee_key) as employee_count,
        count(distinct s.order_id) as total_orders,
        sum(s.total_sales_amount) as total_sales,
        sum(s.profit_amount) as total_profit,
        avg(e.performance_rating) as avg_performance_rating,
        avg(e.target_achievement_percentage) as avg_target_achievement,
        sum(e.orders_processed) as orders_processed
    from employees e
    left join sales s
        on e.employee_key = s.employee_key
    group by e.role

)

select
    role,
    employee_count,
    total_orders,
    orders_processed,
    total_sales as total_sales,
    total_profit as total_profit,

    round(total_sales / nullif(employee_count, 0), 2) as avg_sales_per_employee,

    round(total_sales / nullif(total_orders, 0), 2) as avg_order_value,

    round((total_profit * 100.0) / nullif(total_sales, 0), 2) as profit_margin_percent,

    round(avg_performance_rating, 2) as avg_performance_rating,

    round(avg_target_achievement, 2) as avg_target_achievement_percent,

    round(
        total_sales * 100.0 / sum(total_sales) over (),
        2
    ) as sales_contribution_percent

from role_summary
order by total_sales desc