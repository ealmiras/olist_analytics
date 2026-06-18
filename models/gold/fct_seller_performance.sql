with
sellers as (
    select * from {{ ref('int_sellers__closed_leads') }}
),
order_items as (
    select
        seller_id,
        count(distinct order_id)  as total_orders,
        count(distinct product_id) as total_products,
        sum(item_price)            as total_revenue,
        avg(item_price)            as avg_item_price,
        avg(item_freight_value)    as avg_freight_value
    from {{ ref('int_order_items__enriched') }}
    where order_status in {{ active_order_statuses() }}
    group by seller_id
),

final as (
    select
        s.seller_id,
        s.seller_city,
        s.seller_state,
        s.lead_origin,
        s.business_segment,
        s.lead_type,
        s.lead_behaviour_profile,
        s.lead_created_at,
        s.closed_date,
        oi.total_orders,
        oi.total_products,
        oi.total_revenue,
        oi.avg_item_price,
        oi.avg_freight_value
    from sellers s
    left join order_items oi on oi.seller_id = s.seller_id
)

select * from final
