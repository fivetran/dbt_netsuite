{% macro get_fiscalcalendar_columns() %}

{% set columns = [
    {"name": "id", "datatype": dbt.type_int()},
    {"name": "externalid", "datatype": dbt.type_string()},
    {"name": "fiscalmonth", "datatype": dbt.type_string()},
    {"name": "isdefault", "datatype": dbt.type_string()},
    {"name": "name", "datatype": dbt.type_string()},
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "date_deleted", "datatype": dbt.type_timestamp()},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()}
] %}

{{ return(columns) }}

{% endmacro %}
