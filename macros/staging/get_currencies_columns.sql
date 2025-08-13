{% macro get_currencies_columns() %}

{% set columns = [
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "currency_extid", "datatype": dbt.type_string()},
    {"name": "currency_id", "datatype": dbt.type_float()},
    {"name": "date_deleted", "datatype": dbt.type_timestamp()},
    {"name": "date_last_modified", "datatype": dbt.type_timestamp()},
    {"name": "is_inactive", "datatype": dbt.type_string()},
    {"name": "name", "datatype": dbt.type_string()},
    {"name": "precision_0", "datatype": dbt.type_float()},
    {"name": "symbol", "datatype": dbt.type_string()}
] %}

{{ return(columns) }}

{% endmacro %}

{% macro get_netsuite2_currencies_columns() %}

{% set columns = [
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "currencyprecision", "datatype": dbt.type_int()},
    {"name": "date_deleted", "datatype": dbt.type_timestamp()},
    {"name": "displaysymbol", "datatype": dbt.type_string()},
    {"name": "exchangerate", "datatype": dbt.type_float()},
    {"name": "externalid", "datatype": dbt.type_string()},
    {"name": "fxrateupdatetimezone", "datatype": dbt.type_int()},
    {"name": "id", "datatype": dbt.type_int()},
    {"name": "includeinfxrateupdates", "datatype": dbt.type_string()},
    {"name": "isbasecurrency", "datatype": dbt.type_string()},
    {"name": "isinactive", "datatype": dbt.type_string()},
    {"name": "lastmodifieddate", "datatype": dbt.type_timestamp()},
    {"name": "name", "datatype": dbt.type_string()},
    {"name": "overridecurrencyformat", "datatype": dbt.type_string()},
    {"name": "symbol", "datatype": dbt.type_string()},
    {"name": "symbolplacement", "datatype": dbt.type_int()}
] %}

{{ return(columns) }}

{% endmacro %}
