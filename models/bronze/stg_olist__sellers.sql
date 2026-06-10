with sellers as (
    select * from {{ source('olist', 'sellers') }}
)

renamed as (
    select
        seller_id,
        seller_zip_code_prefix,
        seller_city,
        seller_state
    from sellers
)

select * from renamed