with payments as (
    select * from {{ source('olist', 'payments') }}
)

renamed as (
    select
        order_id,
        payment_type,
        total_installments,
        payment_sequential as installment_number,
        payment_value
    from payments
    where payment_value > 0
)

select * from renamed