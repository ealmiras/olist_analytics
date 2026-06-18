with
reviews as (
    select * from {{ ref('stg_olist__reviews') }}
),
orders as (
    select * from {{ ref('stg_olist__orders') }}
),
customers as (
    select * from {{ ref('stg_olist__customers') }}
),

final as (
    select
        r.review_id,
        r.order_id,
        c.customer_unique_id,
        c.customer_city,
        c.customer_state,
        o.order_status,
        o.order_date,
        o.delivered_customer_at,
        r.review_score,
        r.review_title,
        r.review_message,
        r.review_created_at,
        r.review_answered_at,
        case
            when r.review_title is not null or r.review_message is not null
            then true
            else false
        end as has_written_review,
        datediff(day, o.delivered_customer_at, r.review_created_at) as days_to_review
    from reviews r
    left join orders o on o.order_id = r.order_id
    left join customers c on c.customer_id = o.customer_id
)

select * from final
