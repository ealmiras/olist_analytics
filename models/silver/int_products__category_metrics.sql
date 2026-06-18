with
order_items as (
    select * from {{ ref('int_order_items__enriched') }}
    where order_status in ('invoiced', 'delivered', 'approved', 'shipped')
),

final as (
    select
        product_category_name,
        count(distinct order_id)   as total_orders,
        count(distinct product_id) as total_products,
        count(distinct seller_id)  as total_sellers,
        avg(item_price)            as avg_item_price,
        avg(item_freight_value)    as avg_freight_value,
        sum(item_price)            as total_revenue
    from order_items
    group by product_category_name
)

select * from final
