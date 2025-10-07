{% macro get_transaction_lines_columns() %}

{% set columns = [
    {"name": "account_id", "datatype": dbt.type_float()},
    {"name": "amount", "datatype": dbt.type_float()},
    {"name": "class_id", "datatype": dbt.type_float()},
    {"name": "company_id", "datatype": dbt.type_float()},
    {"name": "department_id", "datatype": dbt.type_float()},
    {"name": "item_id", "datatype": dbt.type_float()},
    {"name": "location_id", "datatype": dbt.type_float()},
    {"name": "memo", "datatype": dbt.type_string()},
    {"name": "non_posting_line", "datatype": dbt.type_string()},
    {"name": "subsidiary_id", "datatype": dbt.type_float()},
    {"name": "transaction_id", "datatype": dbt.type_float()},
    {"name": "transaction_line_id", "datatype": dbt.type_float()}
] %}

{{ fivetran_utils.add_pass_through_columns(columns, var('transaction_lines_pass_through_columns')) }}

{{ return(columns) }}

{% endmacro %}

{% macro get_netsuite2_transaction_lines_columns() %}

{% set columns = [
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "id", "datatype": dbt.type_int()},
    {"name": "transaction", "datatype": dbt.type_int()},
    {"name": "linesequencenumber", "datatype": dbt.type_int()},
    {"name": "memo", "datatype": dbt.type_string()},
    {"name": "entity", "datatype": dbt.type_int()},
    {"name": "item", "datatype": dbt.type_int()},
    {"name": "class", "datatype": dbt.type_int()},
    {"name": "location", "datatype": dbt.type_int()},
    {"name": "subsidiary", "datatype": dbt.type_int()},
    {"name": "department", "datatype": dbt.type_int()},
    {"name": "isclosed", "datatype": dbt.type_string()},
    {"name": "isbillable", "datatype": dbt.type_string()},
    {"name": "iscogs", "datatype": dbt.type_string()},
    {"name": "cleared", "datatype": dbt.type_string()},
    {"name": "commitmentfirm", "datatype": dbt.type_string()},
    {"name": "mainline", "datatype": dbt.type_string()},
    {"name": "taxline", "datatype": dbt.type_string()},
    {"name": "eliminate", "datatype": dbt.type_string()},
    {"name": "netamount", "datatype": dbt.type_float()}
] %}

{{ fivetran_utils.add_pass_through_columns(columns, var('transaction_lines_pass_through_columns')) }}

{{ return(columns) }}

{% endmacro %}
