with
customer_orders as (
    select
        customer_id,
        customer_unique_id,
        customer_city,
        order_id,
        purchased_at,
        delivered_carrier_at,
        delivered_customer_at,
        order_status
    from {{ ref('int_customers__order_detail') }}
    where order_status in ('delivered', 'shipped') and purchased_at is not null
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
        lead(purchased_at) over (partition by customer_unique_id order by purchased_at) as next_order_date,
        case 
            when order_status = 'delivered' then datediff(day, purchased_at, delivered_customer_at) 
            when order_status = 'shipped' and delivered_carrier_at is not null then avg_city.avg_delivery_time 
            else null
        end as delivery_time
    from customer_orders
    left join avg_delivery_by_city avg_city using (customer_city)
),

final as (
select
    customer_unique_id,
    customer_city,
    case 
        when count(distinct order_id) > 1 
        then 'returning'
        else 'new' 
    end as customer_type,
    count(distinct order_id) as total_orders,
    min(purchased_at) as first_order_date,
    max(purchased_at) as last_order_date,
    case 
        when count(distinct order_id) > 1 
        then avg(datediff(day, purchased_at, next_order_date)) 
    end as  avg_days_between_orders,
    avg(delivery_time) as avg_delivery_time
from date_between_orders
group by customer_unique_id, customer_city
order by last_order_date desc
)

select * from final