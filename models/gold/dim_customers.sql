with
customers as (
    select * from {{ ref('int_customers__geolocation') }}
),

final as (
    select
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state,
        latitude,
        longitude
    from customers
    qualify row_number() over (partition by customer_unique_id order by customer_id desc) = 1
)

select * from final
