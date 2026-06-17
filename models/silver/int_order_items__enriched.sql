with 
order_items as (
    select * from {{ ref('stg_olist__order_items') }}
),
orders as (
    select * from {{ ref('stg_olist__orders') }}
),
products as (
    select * from {{ ref('stg_olist__products') }}
),
sellers as (
    select * from {{ ref('stg_olist__sellers') }}
),
customers as (
    select * from {{ ref('stg_olist__customers') }}
),

final as (
    select
        oi.order_id,
        o.order_date,
        c.customer_unique_id,
        o.order_status,
        oi.item_line_number,
        oi.product_id,
        p.product_category_name,
        oi.seller_id,
        s.seller_city,
        oi.item_price,
        oi.to_be_shipped_at_limit,
        o.delivered_carrier_at,
        o.delivered_customer_at,
        o.estimated_delivery_at,
        oi.item_freight_value
    from order_items oi
    left join orders o on o.order_id = oi.order_id
    left join products p on p.product_id = oi.product_id
    left join sellers s on s.seller_id = oi.seller_id
    left join customers c on c.customer_id = o.customer_id
)

select * from final