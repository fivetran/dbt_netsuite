{% macro get_transactions_columns() %}

{% set columns = [
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "accounting_period_id", "datatype": dbt.type_float()},
    {"name": "currency_id", "datatype": dbt.type_float()},
    {"name": "due_date", "datatype": dbt.type_timestamp()},
    {"name": "is_advanced_intercompany", "datatype": dbt.type_string()},
    {"name": "is_intercompany", "datatype": dbt.type_string()},
    {"name": "status", "datatype": dbt.type_string()},
    {"name": "trandate", "datatype": dbt.type_timestamp()},
    {"name": "transaction_id", "datatype": dbt.type_float()},
    {"name": "transaction_type", "datatype": dbt.type_string()}
] %}

{{ fivetran_utils.add_pass_through_columns(columns, var('transactions_pass_through_columns')) }}

{{ return(columns) }}

{% endmacro %}

{% macro get_netsuite2_transactions_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "id", "datatype": dbt.type_int()},
    {"name": "transactionnumber", "datatype": dbt.type_string()},
    {"name": "type", "datatype": dbt.type_string()},
    {"name": "memo", "datatype": dbt.type_string()},
    {"name": "trandate", "datatype": dbt.type_timestamp()},
    {"name": "status", "datatype": dbt.type_string()},
    {"name": "createdby", "datatype": dbt.type_int()},
    {"name": "createddate", "datatype": dbt.type_timestamp()},
    {"name": "duedate", "datatype": dbt.type_timestamp()},
    {"name": "closedate", "datatype": dbt.type_timestamp()},
    {"name": "currency", "datatype": dbt.type_int()},
    {"name": "entity", "datatype": dbt.type_int()},
    {"name": "lastmodifiedby", "datatype": dbt.type_int()},
    {"name": "postingperiod", "datatype": dbt.type_int()},
    {"name": "posting", "datatype": dbt.type_string()},
    {"name": "nexus", "datatype": dbt.type_int()},
    {"name": "taxregoverride", "datatype": dbt.type_string()},
    {"name": "taxdetailsoverride", "datatype": dbt.type_string()},
    {"name": "taxpointdate", "datatype": dbt.type_timestamp()},
    {"name": "taxpointdateoverride", "datatype": dbt.type_string()},
    {"name": "intercoadj", "datatype": dbt.type_string()},
    {"name": "isreversal", "datatype": dbt.type_string()},
    {"name": "reversal", "datatype": dbt.type_int()},
    {"name": "reversaldate", "datatype": dbt.type_timestamp()},
    {"name": "reversaldefer", "datatype": dbt.type_string()}, 
    {"name": "_fivetran_deleted", "datatype": "boolean"}
] %}

{{ fivetran_utils.add_pass_through_columns(columns, var('transactions_pass_through_columns')) }}

{{ return(columns) }}

{% endmacro %}

