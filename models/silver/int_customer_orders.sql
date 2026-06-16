with 
orders as (
    select * from {{ ref('stg_olist__orders') }}
),
customers as (
    select * from {{ ref('stg_olist__customers') }}
),

joined as (
    select
        o.order_id,
        o.customer_id,
        c.customer_unique_id,
        c.customer_zip_code_prefix,
        c.customer_city,
        c.customer_state,
        o.order_status,
        o.order_date,
        o.approved_at,
        o.delivered_carrier_at,
        o.delivered_customer_at,
        o.estimated_delivery_at
    from orders o
    left join customers c on o.customer_id = c.customer_id
)

select * from joined