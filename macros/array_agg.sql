{% macro array_agg(field_to_agg, order_by) -%}

{{ adapter_macro('netsuite.array_agg', field_to_agg, order_by) }}

{%- endmacro %}

{% macro default__array_agg(field_to_agg, order_by) %}
    array_agg({{ field_to_agg }} order by {{ order_by }})

{% endmacro %}

{% macro snowflake__array_agg(field_to_agg, order_by) %}
    array_agg({{ field_to_agg }}) within group (order by {{ order_by }})

{% endmacro %}
