with
customers as (
    select * from {{ ref('stg_olist__customers') }}
),
geolocation as (
    select * from {{ ref('stg_olist__geolocation') }}
),

-- geolocation has multiple entries per zip code prefix; average to a single centroid
geo_deduped as (
    select
        zip_code_prefix,
        avg(latitude) as latitude,
        avg(longitude) as longitude
    from geolocation
    group by zip_code_prefix
),

final as (
    select
        c.customer_id,
        c.customer_unique_id,
        c.customer_zip_code_prefix,
        c.customer_city,
        c.customer_state,
        g.latitude,
        g.longitude
    from customers c
    left join geo_deduped g on g.zip_code_prefix = c.customer_zip_code_prefix
)

select * from final
