{% macro active_order_statuses() %}
    ('invoiced', 'delivered', 'approved', 'shipped')
{% endmacro %}
