{% macro get_employee_columns() %}

{% set columns = [
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "accountnumber", "datatype": dbt.type_string()},
    {"name": "aliennumber", "datatype": dbt.type_string()},
    {"name": "approvallimit", "datatype": dbt.type_float()},
    {"name": "approver", "datatype": dbt.type_int()},
    {"name": "class", "datatype": dbt.type_int()},
    {"name": "comments", "datatype": dbt.type_string()},
    {"name": "currency", "datatype": dbt.type_int()},
    {"name": "department", "datatype": dbt.type_int()},
    {"name": "email", "datatype": dbt.type_string()},
    {"name": "employeestatus", "datatype": dbt.type_int()},
    {"name": "employeetype", "datatype": dbt.type_int()},
    {"name": "entityid", "datatype": dbt.type_string()},
    {"name": "expenselimit", "datatype": dbt.type_string()},
    {"name": "firstname", "datatype": dbt.type_string()},
    {"name": "giveaccess", "datatype": dbt.type_string()},
    {"name": "hiredate", "datatype": dbt.type_timestamp()},
    {"name": "id", "datatype": dbt.type_int()},
    {"name": "isinactive", "datatype": dbt.type_string()},
    {"name": "lastname", "datatype": dbt.type_string()},
    {"name": "location", "datatype": dbt.type_int()},
    {"name": "middlename", "datatype": dbt.type_string()},
    {"name": "purchaseorderapprovallimit", "datatype": dbt.type_float()},
    {"name": "purchaseorderlimit", "datatype": dbt.type_float()},
    {"name": "subsidiary", "datatype": dbt.type_int()},
    {"name": "supervisor", "datatype": dbt.type_int()}
] %}

{{ return(columns) }}

{% endmacro %}
