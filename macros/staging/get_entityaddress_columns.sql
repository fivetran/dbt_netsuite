{% macro get_entityaddress_columns() %}

{% set columns = [
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "addr1", "datatype": dbt.type_string()},
    {"name": "addr2", "datatype": dbt.type_string()},
    {"name": "addr3", "datatype": dbt.type_string()},
    {"name": "addressee", "datatype": dbt.type_string()},
    {"name": "addrphone", "datatype": dbt.type_string()},
    {"name": "addrtext", "datatype": dbt.type_string()},
    {"name": "attention", "datatype": dbt.type_string()},
    {"name": "city", "datatype": dbt.type_string()},
    {"name": "country", "datatype": dbt.type_string()},
    {"name": "date_deleted", "datatype": dbt.type_timestamp()},
    {"name": "dropdownstate", "datatype": dbt.type_string()},
    {"name": "lastmodifieddate", "datatype": dbt.type_timestamp()},
    {"name": "nkey", "datatype": dbt.type_int()},
    {"name": "override", "datatype": dbt.type_string()},
    {"name": "recordowner", "datatype": dbt.type_int()},
    {"name": "state", "datatype": dbt.type_string()},
    {"name": "zip", "datatype": dbt.type_string()}
] %}

{{ return(columns) }}

{% endmacro %}
