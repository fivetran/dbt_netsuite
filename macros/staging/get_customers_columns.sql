{% macro get_customers_columns() %}

{% set columns = [
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "city", "datatype": dbt.type_string()},
    {"name": "companyname", "datatype": dbt.type_string()},
    {"name": "country", "datatype": dbt.type_string()},
    {"name": "customer_extid", "datatype": dbt.type_string()},
    {"name": "customer_id", "datatype": dbt.type_float()},
    {"name": "date_first_order", "datatype": dbt.type_timestamp()},
    {"name": "state", "datatype": dbt.type_string()},
    {"name": "zipcode", "datatype": dbt.type_string()}
] %}

{{ fivetran_utils.add_pass_through_columns(columns, var('customers_pass_through_columns')) }}

{{ return(columns) }}

{% endmacro %}

{% macro get_netsuite2_customers_columns() %}

{% set columns = [
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "id", "datatype": dbt.type_int()},
    {"name": "entityid", "datatype": dbt.type_string()},
    {"name": "externalid", "datatype": dbt.type_string()},
    {"name": "parent", "datatype": dbt.type_int()},
    {"name": "isperson", "datatype": dbt.type_string()},
    {"name": "altname", "datatype": dbt.type_string()},
    {"name": "companyname", "datatype": dbt.type_string()},
    {"name": "firstname", "datatype": dbt.type_string()},
    {"name": "lastname", "datatype": dbt.type_string()},
    {"name": "email", "datatype": dbt.type_string()},
    {"name": "phone", "datatype": dbt.type_string()},
    {"name": "defaultbillingaddress", "datatype": dbt.type_int()},
    {"name": "defaultshippingaddress", "datatype": dbt.type_int()},
    {"name": "receivablesaccount", "datatype": dbt.type_int()},
    {"name": "currency", "datatype": dbt.type_int()},
    {"name": "firstorderdate", "datatype": dbt.type_timestamp()}
] %}

{{ fivetran_utils.add_pass_through_columns(columns, var('customers_pass_through_columns')) }}

{{ return(columns) }}

{% endmacro %}
