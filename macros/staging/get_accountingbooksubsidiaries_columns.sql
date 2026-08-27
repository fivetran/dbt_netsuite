{% macro get_accountingbooksubsidiaries_columns() %}

{% set columns = [
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_id", "datatype": dbt.type_string()},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "accountingbook", "datatype": dbt.type_int()},
    {"name": "date_deleted", "datatype": dbt.type_timestamp()},
    {"name": "status", "datatype": dbt.type_string()},
    {"name": "subsidiary", "datatype": dbt.type_int()}
] %}

{{ return(columns) }}

{% endmacro %}
