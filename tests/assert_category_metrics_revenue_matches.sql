-- Fails if total_revenue in int_products__category_metrics doesn't match
-- the sum of item_price from int_order_items__enriched for active orders.
-- Catches drift if either model's aggregation logic changes independently.

with 
category_metrics as (
    select
        product_category_name,
        total_revenue
    from {{ ref('int_products__category_metrics') }}
),

order_items_agg as (
    select
        product_category_name,
        sum(item_price) as total_revenue
    from {{ ref('int_order_items__enriched') }}
    where order_status in {{ active_order_statuses() }}
    group by product_category_name
),

comparison as (
    select
        abs(coalesce(cm.total_revenue, 0) - coalesce(oi.total_revenue, 0)) as difference
    from category_metrics cm
    full outer join order_items_agg oi
        on cm.product_category_name = oi.product_category_name
        or (cm.product_category_name is null and oi.product_category_name is null)
)

select *
from comparison
where difference > 0.01
