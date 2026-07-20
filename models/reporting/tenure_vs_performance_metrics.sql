{{ config(materialized='view') }}

with sales as (

    select
        employee_key,
        total_sales_amount,
        profit_amount,
        order_id
    from {{ ref('fact_sales') }}

),

employees as (

    select
        employee_key,
        full_name,
        role,
        tenure_years,
        performance_rating,
        target_achievement_percentage,
        orders_processed
    from {{ ref('dim_employee') }}

),

employee_summary as (

    select
        e.employee_key,
        e.full_name,
        e.role,
        e.tenure_years,
        e.performance_rating,
        e.target_achievement_percentage,
        e.orders_processed,

        count(distinct s.order_id) as total_orders,
        sum(s.total_sales_amount) as total_sales,
        sum(s.profit_amount) as total_profit

    from employees e
    left join sales s
        on e.employee_key = s.employee_key

    group by
        e.employee_key,
        e.full_name,
        e.role,
        e.tenure_years,
        e.performance_rating,
        e.target_achievement_percentage,
        e.orders_processed

),

tenure_analysis as (

    select

        case
            when tenure_years < 2 then '0-2 Years'
            when tenure_years < 5 then '2-5 Years'
            when tenure_years < 10 then '5-10 Years'
            else '10+ Years'
        end as tenure_group,

        count(*) as employee_count,

        round(avg(performance_rating), 2) as avg_performance_rating,

        round(avg(target_achievement_percentage), 2) as avg_target_achievement_percent,

        sum(total_sales) as total_sales,

        sum(total_profit) as total_profit,

        sum(total_orders) as total_orders,

        round(avg(total_sales), 2) as avg_sales_per_employee,

        round(avg(total_profit), 2) as avg_profit_per_employee,

        round(avg(orders_processed), 0) as avg_orders_processed,

        concat(round(
            sum(total_profit) * 100.0 /
            nullif(sum(total_sales), 0),
            2
        ), '%') as profit_margin_percent

    from employee_summary
    group by 1

)

select *
from tenure_analysis
order by
    case tenure_group
        when '0-2 Years' then 1
        when '2-5 Years' then 2
        when '5-10 Years' then 3
        else 4
    end