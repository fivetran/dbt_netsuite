{% macro get_netsuite2_vendor_subsidiary_relationship_columns() %}

{% set columns = [
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "balance", "datatype": dbt.type_float()},
    {"name": "balancebase", "datatype": dbt.type_float()},
    {"name": "balancecurrency", "datatype": dbt.type_float()},
    {"name": "creditlimit", "datatype": dbt.type_float()},
    {"name": "date_deleted", "datatype": dbt.type_timestamp()},
    {"name": "entity", "datatype": dbt.type_int()},
    {"name": "externalid", "datatype": dbt.type_string()},
    {"name": "id", "datatype": dbt.type_int()},
    {"name": "isprimarysub", "datatype": dbt.type_string()},
    {"name": "lastmodifieddate", "datatype": dbt.type_timestamp()},
    {"name": "name", "datatype": dbt.type_string()},
    {"name": "prepaymentbalance", "datatype": dbt.type_float()},
    {"name": "prepaymentbalancebase", "datatype": dbt.type_float()},
    {"name": "primarycurrency", "datatype": dbt.type_int()},
    {"name": "subsidiary", "datatype": dbt.type_int()},
    {"name": "unbilledorders", "datatype": dbt.type_float()},
    {"name": "unbilledordersbase", "datatype": dbt.type_float()},
] %}

{{ return(columns) }}

{% endmacro %}

