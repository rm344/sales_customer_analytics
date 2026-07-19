with source_data as (
    select *
    from {{ ref('snp_orders') }}
    where dbt_valid_to is null
),

extracted as (
    select
        order_id_clean                                          as order_id,
        product_id_clean                                        as product_id,
        item_index,
        raw_json_payload:customer_id::string                     as customer_id,
        raw_json_payload:employee_id::string                     as employee_id,
        raw_json_payload:store_id::string                        as store_id,
        raw_json_payload:campaign_id::string                     as campaign_id,
        raw_json_payload:order_date::string                      as order_date,
        raw_json_payload:created_at::string                      as created_at,
        raw_json_payload:shipping_date::string                   as shipping_date,
        raw_json_payload:delivery_date::string                   as delivery_date,
        raw_json_payload:estimated_delivery_date::string         as estimated_delivery_date,
        raw_json_payload:discount_amount::float                  as order_discount_amount,
        raw_json_payload:shipping_cost::float                     as shipping_cost,
        raw_json_payload:tax_amount::float                       as tax_amount,
        raw_json_payload:total_amount::float                     as order_total_amount,
        raw_json_payload:order_source::string                    as order_source,
        raw_json_payload:order_status::string                    as order_status,
        raw_json_payload:payment_method::string                  as payment_method,
        raw_json_payload:shipping_method::string                 as shipping_method,
        raw_json_payload:billing_address:city::string            as billing_city,
        raw_json_payload:billing_address:state::string           as billing_state,
        raw_json_payload:shipping_address:city::string           as shipping_city,
        raw_json_payload:shipping_address:state::string          as shipping_state,
        item.value:quantity::number                              as quantity,
        item.value:unit_price::float                             as unit_price,
        item.value:cost_price::float                             as cost_price,
        item.value:discount_amount::float                        as item_discount_amount,
        last_modified_date_clean
    from source_data,
         lateral flatten(input => raw_json_payload:order_items) item
    where item.index = item_index
),

calculated as (
    select
        *,
        try_to_timestamp(order_date)                             as order_date_ts,
        try_to_timestamp(shipping_date)                          as shipping_date_ts,
        try_to_timestamp(delivery_date)                          as delivery_date_ts,
        try_to_timestamp(estimated_delivery_date)                as estimated_delivery_date_ts,

        quantity * unit_price * (1 - item_discount_amount)       as line_revenue,
        quantity * cost_price                                    as line_cost
    from extracted
),

final as (
    select
        order_id,
        product_id,
        item_index,
        customer_id,
        employee_id,
        store_id,
        campaign_id,

        order_date_ts                                            as order_date,
        created_at,
        shipping_date_ts                                         as shipping_date,
        delivery_date_ts                                         as delivery_date,
        estimated_delivery_date_ts                               as estimated_delivery_date,

        quantity,
        unit_price,
        cost_price,
        item_discount_amount,
        order_discount_amount,
        shipping_cost,
        tax_amount,
        order_total_amount,

        line_revenue,
        line_cost,
        (line_revenue * (1 - order_discount_amount)) - line_cost - shipping_cost - tax_amount as profit_amount,

        case
            when line_revenue > 0
            then round((((line_revenue * (1 - order_discount_amount)) - line_cost - shipping_cost - tax_amount) / line_revenue) * 100, 2)
            else null
        end                                                       as profit_margin_percentage,

        datediff(day, order_date_ts, shipping_date_ts)           as processing_days,
        datediff(day, shipping_date_ts, delivery_date_ts)        as shipping_days,

        case
            when delivery_date_ts is not null and delivery_date_ts <= estimated_delivery_date_ts then 'On Time'
            when delivery_date_ts is not null and delivery_date_ts > estimated_delivery_date_ts  then 'Delayed'
            when delivery_date_ts is null and current_timestamp() > estimated_delivery_date_ts   then 'Potentially Delayed'
            else 'In Transit'
        end                                                       as delivery_status,

        hour(order_date_ts)                                      as order_hour,

        case
            when hour(order_date_ts) >= 5  and hour(order_date_ts) < 12 then 'Morning'
            when hour(order_date_ts) >= 12 and hour(order_date_ts) < 17 then 'Afternoon'
            when hour(order_date_ts) >= 17 and hour(order_date_ts) < 22 then 'Evening'
            else 'Night'
        end                                                       as order_time_of_day,

        date_part('week', order_date_ts)                         as order_week,
        date_part('month', order_date_ts)                        as order_month,
        date_part('quarter', order_date_ts)                      as order_quarter,
        date_part('year', order_date_ts)                         as order_year,

        initcap(trim(order_source))                              as order_source,
        initcap(trim(order_status))                              as order_status,
        initcap(trim(payment_method))                            as payment_method,
        initcap(trim(shipping_method))                            as shipping_method,

        initcap(trim(billing_city))                              as billing_city,
        upper(trim(billing_state))                               as billing_state,
        initcap(trim(shipping_city))                             as shipping_city,
        upper(trim(shipping_state))                               as shipping_state,

        -- order-level totals, repeated on every line item via window functions
        count(product_id)          over (partition by order_id) as total_items,
        sum(quantity)               over (partition by order_id) as total_quantity,
        sum(quantity * unit_price)   over (partition by order_id) as total_amount,
        sum(quantity * cost_price)    over (partition by order_id) as total_cost,
        sum(item_discount_amount)      over (partition by order_id) as total_discount,

        last_modified_date_clean

    from calculated
)

select * from final