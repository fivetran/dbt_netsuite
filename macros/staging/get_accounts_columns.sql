{% macro get_accounts_columns() %}

{% set columns = [
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "account_id", "datatype": dbt.type_float()},
    {"name": "accountnumber", "datatype": dbt.type_string()},
    {"name": "general_rate_type", "datatype": dbt.type_string()},
    {"name": "is_balancesheet", "datatype": dbt.type_string()},
    {"name": "is_leftside", "datatype": dbt.type_string()},
    {"name": "name", "datatype": dbt.type_string()},
    {"name": "parent_id", "datatype": dbt.type_float()},
    {"name": "type_name", "datatype": dbt.type_string()}
] %}

{{ fivetran_utils.add_pass_through_columns(columns, var('accounts_pass_through_columns')) }}

{{ return(columns) }}

{% endmacro %}

{% macro get_netsuite2_accounts_columns() %}

{% set columns = [

    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "id", "datatype": dbt.type_int()},
    {"name": "externalid", "datatype": dbt.type_string()},
    {"name": "parent", "datatype": dbt.type_int()},
    {"name": "acctnumber", "datatype": dbt.type_string()},
    {"name": "accttype", "datatype": dbt.type_string()},
    {"name": "sspecacct", "datatype": dbt.type_string()},
    {"name": "fullname", "datatype": dbt.type_string()},
    {"name": "accountsearchdisplaynamecopy", "datatype": dbt.type_string()},
    {"name": "description", "datatype": dbt.type_string()},
    {"name": "deferralacct", "datatype": dbt.type_int()},
    {"name": "cashflowrate", "datatype": dbt.type_string()},
    {"name": "generalrate", "datatype": dbt.type_string()},
    {"name": "currency", "datatype": dbt.type_int()},
    {"name": "class", "datatype": dbt.type_int()},
    {"name": "department", "datatype": dbt.type_int()},
    {"name": "location", "datatype": dbt.type_int()},
    {"name": "includechildren", "datatype": dbt.type_string()},
    {"name": "isinactive", "datatype": dbt.type_string()},
    {"name": "issummary", "datatype": dbt.type_string()},
    {"name": "eliminate", "datatype": dbt.type_string()}
] %}

{{ fivetran_utils.add_pass_through_columns(columns, var('accounts_pass_through_columns')) }}

{{ return(columns) }}

{% endmacro %}
