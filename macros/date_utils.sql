{% macro get_month_number(month_abbr) %}
    {{ adapter.dispatch('get_month_number', 'netsuite') (month_abbr) }}
{% endmacro %}

{% macro default__get_month_number(month_abbr) %}
    case upper({{ month_abbr }})
        when 'JAN' then 1
        when 'FEB' then 2
        when 'MAR' then 3
        when 'APR' then 4
        when 'MAY' then 5
        when 'JUN' then 6
        when 'JUL' then 7
        when 'AUG' then 8
        when 'SEP' then 9
        when 'OCT' then 10
        when 'NOV' then 11
        when 'DEC' then 12
    end
{% endmacro %}

{% macro date_from_parts(year, month, day) %}
    {{ return(adapter.dispatch('date_from_parts', 'netsuite')(year, month, day)) }}
{% endmacro %}

{% macro default__date_from_parts(year, month, day) %}
    date({{ year }}, {{ month }}, {{ day }})
{% endmacro %}

{% macro bigquery__date_from_parts(year, month, day) %}
    date({{ year }}, {{ month }}, {{ day }})
{% endmacro %}

{% macro snowflake__date_from_parts(year, month, day) %}
    to_date(to_timestamp({{ year }} || '-' || lpad({{ month }}, 2, '0') || '-' || lpad({{ day }}, 2, '0')))
{% endmacro %}

{% macro postgres__date_from_parts(year, month, day) %}
    ({{ year }} || '-' || lpad({{ month }}, 2, '0') || '-' || lpad({{ day }}, 2, '0'))::date
{% endmacro %}

{% macro redshift__date_from_parts(year, month, day) %}
    ({{ year }} || '-' || lpad({{ month }}, 2, '0') || '-' || lpad({{ day }}, 2, '0'))::date
{% endmacro %}

{% macro databricks__date_from_parts(year, month, day) %}
    to_date(concat({{ year }}, '-', lpad({{ month }}, 2, '0'), '-', lpad({{ day }}, 2, '0')))
{% endmacro %}