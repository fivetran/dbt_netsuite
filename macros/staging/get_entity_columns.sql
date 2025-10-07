{% macro get_entity_columns() %}

{% set columns = [
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "contact", "datatype": dbt.type_int()},
    {"name": "customer", "datatype": dbt.type_int()}, 
    {"name": "employee", "datatype": dbt.type_int()},
    {"name": "entitytitle", "datatype": dbt.type_string()},
    {"name": "id", "datatype": dbt.type_int()},
    {"name": "isperson", "datatype": dbt.type_string()},
    {"name": "parent", "datatype": dbt.type_int()},
    {"name": "project", "datatype": dbt.type_int()},
    {"name": "type", "datatype": dbt.type_string()},
    {"name": "vendor", "datatype": dbt.type_int()}
] %}

{{ fivetran_utils.add_pass_through_columns(columns, var('entities_pass_through_columns')) }}

{{ return(columns) }}

{% endmacro %}
