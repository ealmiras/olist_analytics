with order_payments as (
    select * from {{ ref('int_orders__total_payment') }}
),

final as (
    select
        order_id,
        order_date,
        order_status,
        total_item_price,
        total_freight_value,
        total_order_value,
        total_payment_value,
        total_payment_value - total_order_value as payment_difference,
        case 
            when abs(total_order_value - total_payment_value) < 0.01 
            then 'reconciled' 
            else 'unreconciled' 
        end as reconciliation_status
    from order_payments
    where order_status in ('invoiced', 'delivered', 'approved', 'shipped')
)

select * from final