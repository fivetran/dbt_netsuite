{% macro date_from_parts(year, month, day) %}
    {{ return(adapter.dispatch('date_from_parts', 'netsuite')(year, month, day)) }}
{% endmacro %}

{% macro default__date_from_parts(year, month, day) %}
    date({{ year }}, {{ month }}, {{ day }})
{% endmacro %}

{% macro snowflake__date_from_parts(year, month, day) %}
    date_from_parts({{ year }}, lpad({{ month }}, 2, '0'), lpad({{ day }}, 2, '0'))
{% endmacro %}

{% macro postgres__date_from_parts(year, month, day) %}
    ({{ year }}::text || '-' || lpad({{ month }}::text, 2, '0') || '-' || lpad({{ day }}::text, 2, '0'))::date
{% endmacro %}

{% macro redshift__date_from_parts(year, month, day) %}
    ({{ year }} || '-' || lpad({{ month }}, 2, '0') || '-' || lpad({{ day }}, 2, '0'))::date
{% endmacro %}

{% macro databricks__date_from_parts(year, month, day) %}
    make_date({{ year }}, lpad({{ month }}, 2, '0'), lpad({{ day }}, 2, '0'))
{% endmacro %}