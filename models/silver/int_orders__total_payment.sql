with
orders as (
    select
        order_id,
        order_date,
        customer_unique_id,
        order_status,
        item_line_number,
        item_price,
        item_freight_value
    from {{ ref('int_order_items__enriched') }}
),
payments as (
    select
        order_id,
        max(payment_value) as payment_value,
        max(installment_number) as installment_number,
        max(total_installments) as total_installments
    from {{ ref('stg_olist__payments') }}
    group by order_id
),

final as (
    select
        oi.order_id,
        oi.order_date,
        oi.customer_unique_id,
        oi.order_status,
        count(oi.item_line_number) as item_count,
        sum(oi.item_price) as total_item_price,
        sum(oi.item_freight_value) as total_freight_value,
        sum(oi.item_price) + sum(oi.item_freight_value) as total_order_value,
        max(p.payment_value) as total_payment_value,
        max(p.total_installments) as total_installments,
        max(p.installment_number) as paid_installments,
        case
            when max(p.installment_number) = max(p.total_installments)
            then 'completed'
            else 'ongoing'
        end as installment_status,
        max(p.payment_value) - (sum(oi.item_price) + sum(oi.item_freight_value)) as payment_difference,
        case
            when abs((sum(oi.item_price) + sum(oi.item_freight_value)) - max(p.payment_value)) < 0.01
            then 'reconciled'
            else 'unreconciled'
        end as reconciliation_status
    from orders oi
    left join payments p on p.order_id = oi.order_id
    group by oi.order_id, oi.order_date, oi.customer_unique_id, oi.order_status
)

select * from final