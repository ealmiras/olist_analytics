with
customer_orders as (
    select * from {{ ref('int_customers__order_detail') }}
),
order_spend as (
    select
        customer_unique_id,
        order_id,
        sum(item_price) as order_spend
    from {{ ref('int_order_items__enriched') }}
    where order_status in {{ active_order_statuses() }}
    group by customer_unique_id, order_id
),

avg_delivery_by_city as (
    select
        customer_city,
        avg(datediff(day, delivered_carrier_at, delivered_customer_at)) as avg_delivery_time
    from customer_orders
    where order_status = 'delivered'
    group by customer_city
),

orders_with_metrics as (
    select
        o.customer_unique_id,
        o.customer_city,
        o.customer_state,
        o.order_id,
        o.order_date,
        os.order_spend,
        lead(o.order_date) over (partition by o.customer_unique_id order by o.order_date) as next_order_date,
        case
            when o.order_status = 'delivered' then datediff(day, o.order_date, o.delivered_customer_at)
            when o.order_status = 'shipped' and o.delivered_carrier_at is not null then avg_city.avg_delivery_time
            else null
        end as delivery_time
    from customer_orders o
    left join avg_delivery_by_city avg_city using (customer_city)
    left join order_spend os on os.order_id = o.order_id
),

final as (
    select
        customer_unique_id,
        max_by(customer_city, order_date)  as customer_city,
        max_by(customer_state, order_date) as customer_state,
        count(distinct order_id)           as total_orders,
        sum(order_spend)                   as total_customer_spend,
        case
            when count(distinct order_id) > 1 then 'returning'
            else 'new'
        end                                as customer_type,
        min(order_date)                    as first_order_date,
        max(order_date)                    as last_order_date,
        case
            when count(distinct order_id) > 1
            then avg(datediff(day, order_date, next_order_date))
        end                                as avg_days_between_orders,
        avg(delivery_time)                 as avg_delivery_time
    from orders_with_metrics
    group by customer_unique_id
)

select * from final
