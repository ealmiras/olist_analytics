with
leads as (
    select * from {{ ref('int_sellers__closed_leads') }}
),

final as (
    select
        lead_id,
        seller_id,
        lead_origin,
        landing_page_id,
        lead_created_at,
        closed_date,
        business_segment,
        lead_type,
        lead_behaviour_profile,
        has_company,
        has_gtin,
        case
            when closed_date is not null then true
            else false
        end as is_converted,
        case
            when closed_date is not null
            then datediff(day, lead_created_at, closed_date)
        end as days_to_close
    from leads
    where lead_id is not null
)

select * from final
