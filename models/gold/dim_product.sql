{{ config(materialized='table', schema='gold') }}

select
    md5(coalesce(cast(product_id as varchar), '')) as product_key,
    product_id,
    product_name,
    full_description,
    category,
    subcategory,
    product_line,
    brand,
    color,
    size,
    dimensions,
    weight,
    warranty_period,
    supplier_id,
    unit_price,
    cost_price,
    profit_margin_percentage,
    stock_quantity,
    reorder_level,
    is_low_stock,
    is_featured,
    launch_date,
    last_modified_date_clean
from {{ ref('sil_product') }}