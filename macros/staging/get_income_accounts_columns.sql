{% macro get_income_accounts_columns() %}

{% set columns = [
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "account_number", "datatype": dbt.type_string()},
    {"name": "comments", "datatype": dbt.type_string()},
    {"name": "current_balance", "datatype": dbt.type_float()},
    {"name": "date_deleted", "datatype": dbt.type_timestamp()},
    {"name": "date_last_modified", "datatype": dbt.type_timestamp()},
    {"name": "desription", "datatype": dbt.type_string()},
    {"name": "full_name", "datatype": dbt.type_string()},
    {"name": "income_account_extid", "datatype": dbt.type_string()},
    {"name": "income_account_id", "datatype": dbt.type_float()},
    {"name": "is_including_child_subs", "datatype": dbt.type_string()},
    {"name": "is_summary", "datatype": dbt.type_string()},
    {"name": "isinactive", "datatype": dbt.type_string()},
    {"name": "legal_name", "datatype": dbt.type_string()},
    {"name": "name", "datatype": dbt.type_string()},
    {"name": "parent_id", "datatype": dbt.type_float()}
] %}

{{ return(columns) }}

{% endmacro %}
