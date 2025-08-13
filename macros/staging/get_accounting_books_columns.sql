{% macro get_accounting_books_columns() %}

{% set columns = [
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "accounting_book_extid", "datatype": dbt.type_string()},
    {"name": "accounting_book_id", "datatype": dbt.type_float()},
    {"name": "accounting_book_name", "datatype": dbt.type_string()},
    {"name": "base_book_id", "datatype": dbt.type_float()},
    {"name": "date_created", "datatype": dbt.type_timestamp()},
    {"name": "date_deleted", "datatype": dbt.type_timestamp()},
    {"name": "date_last_modified", "datatype": dbt.type_timestamp()},
    {"name": "effective_period_id", "datatype": dbt.type_float()},
    {"name": "form_template_component_id", "datatype": dbt.type_string()},
    {"name": "form_template_id", "datatype": dbt.type_float()},
    {"name": "is_adjustment_only", "datatype": dbt.type_string()},
    {"name": "is_arrangement_level_reclass", "datatype": dbt.type_string()},
    {"name": "is_consolidated", "datatype": dbt.type_string()},
    {"name": "is_contingent_revenue_handling", "datatype": dbt.type_string()},
    {"name": "is_include_child_subsidiaries", "datatype": dbt.type_string()},
    {"name": "is_primary", "datatype": dbt.type_string()},
    {"name": "is_two_step_revenue_allocation", "datatype": dbt.type_string()},
    {"name": "status", "datatype": dbt.type_string()},
    {"name": "unbilled_receivable_grouping", "datatype": dbt.type_string()}
] %}

{{ return(columns) }}

{% endmacro %}

{% macro get_netsuite2_accounting_books_columns() %}

{% set columns = [
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "basebook", "datatype": dbt.type_int()},
    {"name": "contingentrevenuehandling", "datatype": dbt.type_string()},
    {"name": "date_deleted", "datatype": dbt.type_timestamp()},
    {"name": "effectiveperiod", "datatype": dbt.type_int()},
    {"name": "externalid", "datatype": dbt.type_string()},
    {"name": "id", "datatype": dbt.type_int()},
    {"name": "isadjustmentonly", "datatype": dbt.type_string()},
    {"name": "isconsolidated", "datatype": dbt.type_string()},
    {"name": "isprimary", "datatype": dbt.type_string()},
    {"name": "lastmodifieddate", "datatype": dbt.type_timestamp()},
    {"name": "name", "datatype": dbt.type_string()},
    {"name": "subsidiariesstring", "datatype": dbt.type_string()},
    {"name": "twosteprevenueallocation", "datatype": dbt.type_string()},
    {"name": "unbilledreceivablegrouping", "datatype": dbt.type_string()}
] %}

{{ return(columns) }}

{% endmacro %}
