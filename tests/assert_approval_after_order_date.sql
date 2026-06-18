-- Fails if any order was approved before it was placed.

select
    order_id,
    order_date,
    approved_at
from {{ ref('stg_olist__orders') }}
where approved_at is not null
  and approved_at < order_date
