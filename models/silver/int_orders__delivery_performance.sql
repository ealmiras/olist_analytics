with
orders as (
    select * from {{ ref('stg_olist__orders') }}
    where order_status = 'delivered'
),

final as (
    select
        order_id,
        order_date,
        delivered_carrier_at,
        delivered_customer_at,
        estimated_delivery_at,
        datediff(DAY, order_date, delivered_carrier_at) as time_to_carrier,
        datediff(DAY, delivered_carrier_at, delivered_customer_at) as time_to_customer,
        datediff(DAY, order_date, delivered_customer_at) as total_delivery_time,
        datediff(DAY, order_date, estimated_delivery_at) as estimated_delivery_time,
        case 
            when delivered_customer_at <= estimated_delivery_at 
            then 'on_time' 
            else 'late' 
        end as delivery_performance
    from orders
)

select * from final