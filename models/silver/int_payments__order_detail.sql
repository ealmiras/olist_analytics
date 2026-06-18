with
payments as (
    select * from {{ ref('stg_olist__payments') }}
),
orders as (
    select * from {{ ref('stg_olist__orders') }}
),

final as (
    select
        p.order_id,
        o.order_status,
        o.order_date,
        p.payment_type,
        p.installment_number,
        p.total_installments,
        p.payment_value
    from payments p
    left join orders o on o.order_id = p.order_id
)

select * from final
