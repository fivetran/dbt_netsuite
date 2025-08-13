{% macro get_transactionaccountingline_columns() %}

{% set columns = [
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "account", "datatype": dbt.type_int()},
    {"name": "accountingbook", "datatype": dbt.type_int()},
    {"name": "amount", "datatype": dbt.type_float()},
    {"name": "amountlinked", "datatype": dbt.type_float()},
    {"name": "amountpaid", "datatype": dbt.type_float()},
    {"name": "amountunpaid", "datatype": dbt.type_float()},
    {"name": "credit", "datatype": dbt.type_float()},
    {"name": "date_deleted", "datatype": dbt.type_timestamp()},
    {"name": "debit", "datatype": dbt.type_float()},
    {"name": "exchangerate", "datatype": dbt.type_float()},
    {"name": "netamount", "datatype": dbt.type_float()},
    {"name": "overheadparentitem", "datatype": dbt.type_int()},
    {"name": "paymentamountunused", "datatype": dbt.type_float()},
    {"name": "paymentamountused", "datatype": dbt.type_float()},
    {"name": "posting", "datatype": dbt.type_string()},
    {"name": "transaction", "datatype": dbt.type_int()},
    {"name": "transactionline", "datatype": dbt.type_int()}
] %}

{{ return(columns) }}

{% endmacro %}