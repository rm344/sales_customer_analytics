{{ config(materialized='table', schema='gold') }}

with order_items as (

    select * from {{ ref('sil_order') }}

),

joined as (

    select
        oi.order_id,
        oi.product_id,
        oi.item_index,

        c.customer_key,
        p.product_key,
        s.store_key,
        d.date_key,
        e.employee_key,

        oi.quantity                as quantity_sold,
        oi.unit_price,
        oi.quantity * oi.unit_price as total_sales_amount,
        oi.line_cost                as cost_amount,
        oi.item_discount_amount    as discount_amount,
        oi.shipping_cost,
        oi.profit_amount,

        s.region,

        case
            when oi.order_source = 'In-Store' then 'In-Store'
            else 'Online'
        end                          as sales_channel,

        c.age_segment               as customer_segment_impact

    from order_items oi

    left join {{ ref('dim_customer') }} c
        on oi.customer_id = c.customer_id
        and c.is_current = true

    left join {{ ref('dim_product') }} p
        on oi.product_id = p.product_id

    left join {{ ref('dim_store') }} s
        on oi.store_id = s.store_id

    left join {{ ref('dim_date') }} d
        on cast(oi.order_date as date) = d.full_date

    left join {{ ref('dim_employee') }} e
        on oi.employee_id = e.employee_id

)

select
    md5(
        coalesce(cast(order_id as varchar), '') || '|' ||
        coalesce(cast(product_id as varchar), '') || '|' ||
        coalesce(cast(item_index as varchar), '')
    )                              as sales_key,
    order_id,
    customer_key,
    product_key,
    store_key,
    date_key,
    employee_key,
    quantity_sold,
    unit_price,
    total_sales_amount,
    cost_amount,
    discount_amount,
    shipping_cost,
    profit_amount,
    region,
    sales_channel,
    customer_segment_impact
from joined