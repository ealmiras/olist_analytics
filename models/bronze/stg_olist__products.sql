with products as (
    select * from {{ source('olist', 'products') }}
),
translations as (
    select * from {{ ref('product_category_translations') }}
),

renamed as (
    select
        p.product_id,
        p.product_category_name,
        t.product_category_name_english,
        p.product_name_length,
        p.product_description_length,
        p.product_photos_qty,
        p.product_weight_g,
        p.product_length_cm,
        p.product_height_cm,
        p.product_width_cm
    from products p
    left join translations t on t.product_category_name = p.product_category_name
)

select * from renamed