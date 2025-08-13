{% macro get_accounttype_columns() %}

{% set columns = [
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "balancesheet", "datatype": dbt.type_string()},
    {"name": "date_deleted", "datatype": dbt.type_timestamp()},
    {"name": "defaultcashflowratetype", "datatype": dbt.type_string()},
    {"name": "defaultgeneralratetype", "datatype": dbt.type_string()},
    {"name": "eliminationalgo", "datatype": dbt.type_string()},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "includeinrevaldefault", "datatype": dbt.type_string()},
    {"name": "internalid", "datatype": dbt.type_int()},
    {"name": "left", "datatype": dbt.type_string(), "quote": True},
    {"name": "longname", "datatype": dbt.type_string()},
    {"name": "seqnum", "datatype": dbt.type_int()},
    {"name": "usercanchangerevaloption", "datatype": dbt.type_string()}
] %}

{{ return(columns) }}

{% endmacro %}
