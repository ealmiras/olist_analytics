with closed_deals as (
    select * from {{ source('olist', 'closed_deals') }}
)

renamed as (
    select
        mql_id as lead_id,
        seller_id,
        sdr_id as sales_dev_rep_id,
        sr_id as sales_rep_id,
        won_date as closed_date,
        business_segment,
        lead_type,
        lead_behaviour_profile,
        has_company,
        has_gtin
    from closed_deals
)

select * from renamed