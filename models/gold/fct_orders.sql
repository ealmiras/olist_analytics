with
orders as (
    select * from {{ ref('int_customers__order_detail') }}
),
payments as (
    select * from {{ ref('int_orders__total_payment') }}
),
delivery as (
    select * from {{ ref('int_orders__delivery_performance') }}
),
reviews as (
    select
        order_id,
        review_score,
        has_written_review,
        days_to_review
    from {{ ref('int_reviews__order_enriched') }}
    qualify row_number() over (partition by order_id order by review_created_at desc) = 1
),

final as (
    select
        o.order_id,
        o.customer_unique_id,
        o.customer_city,
        o.customer_state,
        o.order_status,
        o.order_date,
        o.approved_at,
        o.delivered_carrier_at,
        o.delivered_customer_at,
        o.estimated_delivery_at,
        p.item_count,
        p.total_item_price,
        p.total_freight_value,
        p.total_order_value,
        p.total_payment_value,
        p.total_installments,
        p.installment_status,
        p.reconciliation_status,
        d.time_to_carrier,
        d.time_to_customer,
        d.total_delivery_time,
        d.delivery_performance,
        r.review_score,
        r.has_written_review,
        r.days_to_review
    from orders o
    left join payments  p on p.order_id = o.order_id
    left join delivery  d on d.order_id = o.order_id
    left join reviews   r on r.order_id = o.order_id
)

select * from final
