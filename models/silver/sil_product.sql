with source_data as (
    select *
    from {{ ref('snp_product') }}
    where dbt_valid_to is null
),

extracted as (
    select
        product_id_clean                                        as product_id,
        raw_json_payload:name::string                           as product_name,
        raw_json_payload:short_description::string              as short_description,
        raw_json_payload:technical_specs::string                as technical_specs,
        raw_json_payload:category::string                       as category,
        raw_json_payload:subcategory::string                    as subcategory,
        raw_json_payload:product_line::string                   as product_line,
        raw_json_payload:brand::string                          as brand,
        raw_json_payload:color::string                          as color,
        raw_json_payload:size::string                           as size,
        raw_json_payload:dimensions::string                     as dimensions,
        raw_json_payload:weight::string                         as weight,
        raw_json_payload:warranty_period::string                as warranty_period,
        raw_json_payload:supplier_id::string                    as supplier_id,
        raw_json_payload:unit_price::float                      as unit_price,
        raw_json_payload:cost_price::float                      as cost_price,
        raw_json_payload:stock_quantity::number                 as stock_quantity,
        raw_json_payload:reorder_level::number                  as reorder_level,
        raw_json_payload:is_featured::boolean                   as is_featured,
        raw_json_payload:launch_date::string                    as launch_date,
        last_modified_date_clean
    from source_data
),

cleaned as (
    select
        upper(trim(product_id))                              as product_id,
        initcap(trim(product_name))                          as product_name,

        initcap(trim(product_name)) || ' - ' ||
        initcap(trim(short_description)) || ' - ' ||
        trim(technical_specs)                                as full_description,

        initcap(trim(category))                              as category,
        initcap(trim(subcategory))                           as subcategory,
        initcap(trim(product_line))                          as product_line,
        initcap(trim(brand))                                 as brand,
        initcap(trim(color))                                 as color,
        initcap(trim(size))                                  as size,
        trim(dimensions)                                     as dimensions,
        trim(weight)                                         as weight,
        trim(warranty_period)                                as warranty_period,
        upper(trim(supplier_id))                             as supplier_id,

        unit_price,
        cost_price,

        case
            when unit_price > 0 then round(((unit_price - cost_price) / unit_price) * 100, 2)
            else null
        end                                                   as profit_margin_percentage,

        stock_quantity,
        reorder_level,
        (stock_quantity < reorder_level)                      as is_low_stock,

        is_featured,
        try_to_date(launch_date)                              as launch_date,

        last_modified_date_clean

    from extracted
)

select * from cleaned