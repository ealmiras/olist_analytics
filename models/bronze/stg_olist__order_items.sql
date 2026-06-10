with order_items as (
    select * from {{ source('olist', 'order_items') }}
),

renamed as (
    select
        order_id,
        order_item_id as item_line_number,
        product_id,
        seller_id,
        shipping_limit_date as to_be_shipped_at_limit,
        price as item_price,
        freight_value as item_freight_value
    from order_items
)

select * from renamed