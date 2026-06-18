-- Fails if any customer has a first_order_date after their last_order_date.
-- Would indicate a bug in the min/max aggregation in fct_customers.

select
    customer_unique_id,
    first_order_date,
    last_order_date
from {{ ref('fct_customers') }}
where first_order_date > last_order_date
