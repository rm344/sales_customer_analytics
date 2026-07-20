{{ config(materialized='view') }}

with sales as (

    select
        employee_key,
        region,
        order_id,
        total_sales_amount,
        profit_amount,
        quantity_sold,
        discount_amount
    from {{ ref('fact_sales') }}

),

employees as (

    select
        employee_key,
        employee_id,
        full_name,
        role,
        performance_rating,
        target_achievement_percentage,
        orders_processed
    from {{ ref('dim_employee') }}

),

employee_performance as (

    select
        s.region,
        e.employee_id,
        e.full_name,
        e.role,

        count(distinct (s.order_id)) as total_orders,

        sum(s.quantity_sold) as total_quantity_sold,

        sum(s.total_sales_amount) as total_sales,

        sum(s.profit_amount) as total_profit,

        round(
            sum(s.profit_amount) * 100.0 /
            nullif(sum(s.total_sales_amount), 0),
            2
        ) as profit_margin_percent,

        e.performance_rating,

        e.target_achievement_percentage,

        e.orders_processed

    from sales s
    inner join employees e
        on s.employee_key = e.employee_key

    group by
        s.region,
        e.employee_id,
        e.full_name,
        e.role,
        e.performance_rating,
        e.target_achievement_percentage,
        e.orders_processed

),

ranked_employees as (

    select
        *,
        rank() over (
            partition by region
            order by total_sales desc
        ) as region_rank
    from employee_performance

)

select *
from ranked_employees
where region_rank <= 5
order by
    region,
    region_rank