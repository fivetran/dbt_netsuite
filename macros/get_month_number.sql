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
        else 1 -- Used as an exception case to default to a calendar year start if the month_abbr does not match our expected values.
    end
{% endmacro %}