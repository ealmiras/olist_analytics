-- Fails if any customer_unique_id present in int_customers__order_detail
-- is missing from fct_customers, or vice versa.
-- Guards against customers being silently dropped or invented by the gold aggregation.

with 
order_detail as (
    select distinct customer_unique_id
    from {{ ref('int_customers__order_detail') }}
),

fct as (
    select distinct customer_unique_id
    from {{ ref('fct_customers') }}
),

missing_from_fct as (
    select customer_unique_id, 'missing from fct_customers' as issue
    from order_detail
    where customer_unique_id not in (select customer_unique_id from fct)
),

extra_in_fct as (
    select customer_unique_id, 'not in int_customers__order_detail' as issue
    from fct
    where customer_unique_id not in (select customer_unique_id from order_detail)
)

select * from missing_from_fct
union all
select * from extra_in_fct
