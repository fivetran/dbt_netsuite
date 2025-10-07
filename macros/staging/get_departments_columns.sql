{% macro get_departments_columns() %}

{% set columns = [
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "department_id", "datatype": dbt.type_float()},
    {"name": "full_name", "datatype": dbt.type_string()},
    {"name": "name", "datatype": dbt.type_string()}
] %}

{{ fivetran_utils.add_pass_through_columns(columns, var('departments_pass_through_columns')) }}

{{ return(columns) }}

{% endmacro %}

{% macro get_netsuite2_departments_columns() %}

{% set columns = [
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "fullname", "datatype": dbt.type_string()},
    {"name": "id", "datatype": dbt.type_int()},
    {"name": "isinactive", "datatype": dbt.type_string()},
    {"name": "name", "datatype": dbt.type_string()},
    {"name": "parent", "datatype": dbt.type_int()},
    {"name": "subsidiary", "datatype": dbt.type_string()}
] %}

{{ fivetran_utils.add_pass_through_columns(columns, var('departments_pass_through_columns')) }}

{{ return(columns) }}

{% endmacro %}
