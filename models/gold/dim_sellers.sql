with
sellers as (
    select * from {{ ref('int_sellers__closed_leads') }}
),

final as (
    select
        seller_id,
        seller_zip_code_prefix,
        seller_city,
        seller_state,
        lead_id,
        lead_origin,
        lead_created_at,
        closed_date,
        business_segment,
        lead_type,
        lead_behaviour_profile,
        has_company,
        has_gtin
    from sellers
)

select * from final
