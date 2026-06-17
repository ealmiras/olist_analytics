with
customer_orders as (
    select * from {{ ref('int_customers__order_detail') }}
),
orders as (
    select * from {{ ref('int_order_items__enriched') }}
    where order_status in ('invoiced', 'delivered', 'approved', 'shipped')
),

avg_delivery_by_city as (
    select
        customer_city,
        avg(datediff(day, delivered_carrier_at, delivered_customer_at)) as avg_delivery_time
    from customer_orders
    where order_status = 'delivered'
    group by customer_city
),

date_between_orders as (
    select
        *,
        lead(order_date) over (partition by customer_unique_id order by order_date) as next_order_date,
        case 
            when order_status = 'delivered' then datediff(day, order_date, delivered_customer_at) 
            when order_status = 'shipped' and delivered_carrier_at is not null then avg_city.avg_delivery_time 
            else null
        end as delivery_time
    from customer_orders
    left join avg_delivery_by_city avg_city using (customer_city)
),

customer_unique as (
    select
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state,
        order_date as last_order_date,
        case 
            when count(distinct o.order_id) > 1 
            then avg(datediff(day, order_date, next_order_date)) 
        end as  avg_days_between_orders,
        rank() over(partition by customer_unique_id order by order_date desc) as order_rank_inv
    from customer_orders
    left join date_between_orders using (customer_unique_id, customer_city, order_date, order_status, delivered_carrier_at, delivered_customer_at)
),

final as (
    select
        customer_unique_id,
        customer_city,
        customer_state,
        last_order_date,
        count(distinct o.order_id) as total_orders,
        sum(o.item_price) as total_customer_spend,
        case 
            when count(distinct o.order_id) > 1 
            then 'returning'
            else 'new' 
        end as customer_type,
        min(order_date) as first_order_date,
        max(order_date) as last_order_date,
        avg_days_between_orders,
        avg(delivery_time) as avg_delivery_time
    from customer_unique c
    left join orders o using (customer_unique_id)
    where order_rank_inv = 1
)

select * from final