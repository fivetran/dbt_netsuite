{% macro get_accountingperiodfiscalcalendars_columns() %}

{% set columns = [
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_id", "datatype": dbt.type_string()},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "accountingperiod", "datatype": dbt.type_int()},
    {"name": "date_deleted", "datatype": dbt.type_timestamp()},
    {"name": "fiscalcalendar", "datatype": dbt.type_int()},
    {"name": "parent", "datatype": dbt.type_int()}
] %}

{{ return(columns) }}

{% endmacro %}
