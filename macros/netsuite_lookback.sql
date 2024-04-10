{% macro netsuite_lookback(from_date, datepart, interval, safety_date='2010-01-01') %}

{{ adapter.dispatch('netsuite_lookback', 'netsuite') (from_date, datepart, interval, safety_date='2010-01-01') }}

{%- endmacro %}

{% macro default__netsuite_lookback(from_date, datepart, interval, safety_date='2010-01-01')  %}

    coalesce(
        (select {{ dbt.dateadd(datepart=datepart, interval=-interval, from_date_or_timestamp=from_date) }} 
            from {{ this }}), 
        {{ "'" ~ safety_date ~ "'" }}
        )

{% endmacro %}

{% macro bigquery__netsuite_lookback(from_date, datepart, interval, safety_date='2010-01-01')  %}

    -- Capture the latest timestamp in a call statement instead of a subquery for optimizing BQ costs on incremental runs
    {%- call statement('date_agg', fetch_result=True) -%}
        select {{ from_date }} from {{ this }}
    {%- endcall -%}

    -- the query_result is stored as a dataframe. Therefore, we want to now store it as a singular value.
    {%- set date_agg = load_result('date_agg')['data'][0][0] %}

    coalesce(
        {{ dbt.dateadd(datepart=datepart, interval=-interval, from_date_or_timestamp="'" ~ date_agg ~ "'") }}, 
        {{ "'" ~ safety_date ~ "'" }}
        )

{% endmacro %}