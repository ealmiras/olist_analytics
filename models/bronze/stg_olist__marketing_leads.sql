with leads as (
    select * from {{ source('olist', 'marketing_qualified_leads') }}
),

renamed as (
    select
        mql_id as lead_id,
        first_contact_date as lead_created_at,
        landing_page_id,
        case when origin is null then 'unknown' else origin end as lead_origin
    from leads
)

select * from renamed