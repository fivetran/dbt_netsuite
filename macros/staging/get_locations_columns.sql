{% macro get_locations_columns() %}

{% set columns = [
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "city", "datatype": dbt.type_string()},
    {"name": "country", "datatype": dbt.type_string()},
    {"name": "full_name", "datatype": dbt.type_string()},
    {"name": "location_id", "datatype": dbt.type_float()},
    {"name": "name", "datatype": dbt.type_string()}
] %}

{{ fivetran_utils.add_pass_through_columns(columns, var('locations_pass_through_columns')) }}

{{ return(columns) }}

{% endmacro %}

{% macro get_netsuite2_locations_columns() %}

{% set columns = [
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "id", "datatype": dbt.type_int()},
    {"name": "name", "datatype": dbt.type_string()},
    {"name": "fullname", "datatype": dbt.type_string()},
    {"name": "mainaddress", "datatype": dbt.type_int()},
    {"name": "parent", "datatype": dbt.type_int()},
    {"name": "subsidiary", "datatype": dbt.type_string()}
] %}

{{ fivetran_utils.add_pass_through_columns(columns, var('locations_pass_through_columns')) }}

{{ return(columns) }}

{% endmacro %}
