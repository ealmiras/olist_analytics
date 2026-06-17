with
sellers as (
    select * from {{ ref('stg_olist__sellers') }}
),
leads as (
    select * from {{ ref('stg_olist__marketing_leads') }}
),
closed_deals as (
    select * from {{ ref('stg_olist__closed_deals') }}
),

final as (
    select
        s.seller_id,
        s.seller_zip_code_prefix,
        s.seller_city,
        s.seller_state,
        l.lead_id,
        l.lead_created_at,
        l.landing_page_id,
        l.lead_origin,
        cd.closed_date,
        cd.business_segment,
        cd.lead_type,
        cd.lead_behaviour_profile,
        cd.has_company,
        cd.has_gtin
    from sellers s
    left join closed_deals cd on s.seller_id = cd.seller_id
    left join leads l on l.lead_id = cd.lead_id
)

select * from final