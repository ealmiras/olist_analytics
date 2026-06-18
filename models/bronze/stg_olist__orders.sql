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
        case
            when order_delivered_carrier_date < order_purchase_timestamp
            then null
            else order_delivered_carrier_date
        end as delivered_carrier_at,
        case
            when order_delivered_customer_date < order_purchase_timestamp
            then null
            else order_delivered_customer_date
        end as delivered_customer_at,
        order_estimated_delivery_date as estimated_delivery_at
    from source
)

select * from renamed