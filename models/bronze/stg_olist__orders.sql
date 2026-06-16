with source as (
    select * from {{ source('olist', 'orders') }}
),

renamed as (
    select
        order_id,
        customer_id,
        order_status,
        order_purchase_timestamp as order_date,
        order_approved_at as approved_at,
        order_delivered_carrier_date as delivered_carrier_at,
        order_delivered_customer_date as delivered_customer_at,
        order_estimated_delivery_date as estimated_delivery_at
    from source
)

select * from renamed