{% macro get_netsuite2_customer_subsidiary_relationship_columns() %}

{% set columns = [
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "balance", "datatype": dbt.type_float()},
    {"name": "date_deleted", "datatype": dbt.type_timestamp()},
    {"name": "depositbalance", "datatype": dbt.type_float()},
    {"name": "entity", "datatype": dbt.type_int()},
    {"name": "externalid", "datatype": dbt.type_string()},
    {"name": "id", "datatype": dbt.type_int()},
    {"name": "isprimarysub", "datatype": dbt.type_string()},
    {"name": "lastmodifieddate", "datatype": dbt.type_timestamp()},
    {"name": "name", "datatype": dbt.type_string()},
    {"name": "primarycurrency", "datatype": dbt.type_int()},
    {"name": "subsidiary", "datatype": dbt.type_int()},
    {"name": "unbilledorders", "datatype": dbt.type_float()}
] %}

{{ return(columns) }}

{% endmacro %}

