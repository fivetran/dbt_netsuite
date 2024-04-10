{% macro netsuite_lookback(from_date, datepart, interval, safety_date='2010-01-01') %}

{{ adapter.dispatch('netsuite_lookback', 'netsuite') (from_date, datepart, interval, safety_date='2010-01-01') }}

{%- endmacro %}

{% macro default__netsuite_lookback(from_date, datepart, interval, safety_date='2010-01-01')  %}

    -- Capture the latest timestamp in a call statement instead of a subquery for optimizing BQ costs on incremental runs
    {% set sql_statement %}
        select {{ from_date }} from {{ this }}
    {%- endset -%}

    -- the query_result is stored as a dataframe. Therefore, we want to now store it as a singular value.
    {%- set result = dbt_utils.get_single_value(sql_statement, default=safety_date) -%}

    {{ dbt.dateadd(datepart=datepart, interval=-interval, from_date_or_timestamp="'" ~ result ~ "'") }}

{% endmacro %}