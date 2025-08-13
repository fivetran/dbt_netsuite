{% macro get_vendorcategory_columns() %}

{% set columns = [
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "date_deleted", "datatype": dbt.type_timestamp()},
    {"name": "externalid", "datatype": dbt.type_string()},
    {"name": "id", "datatype": dbt.type_int()},
    {"name": "isinactive", "datatype": dbt.type_string()},
    {"name": "istaxagency", "datatype": dbt.type_string()},
    {"name": "lastmodifieddate", "datatype": dbt.type_timestamp()},
    {"name": "name", "datatype": dbt.type_string()}
] %}

{{ return(columns) }}

{% endmacro %}
