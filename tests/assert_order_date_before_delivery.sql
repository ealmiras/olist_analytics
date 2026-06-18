-- Fails if any order has a delivery timestamp earlier than when it was placed.
-- Checks both carrier handoff and customer delivery against order_date.

select
    order_id,
    order_date,
    delivered_carrier_at,
    delivered_customer_at
from {{ ref('int_customers__order_detail') }}
where
    (delivered_carrier_at  is not null and delivered_carrier_at  < order_date)
    or
    (delivered_customer_at is not null and delivered_customer_at < order_date)
