{%- set multibook_accounting_enabled = var('netsuite2__multibook_accounting_enabled', false) -%}
{%- set using_to_subsidiary = var('netsuite2__using_to_subsidiary', false) -%}
{%- set using_exchange_rate = var('netsuite2__using_exchange_rate', true) -%}
{%- set income_statement_transaction_detail_columns = var('income_statement_transaction_detail_columns', []) -%}
{%- set accounts_pass_through_columns = var('accounts_pass_through_columns', []) -%}
{%- set classes_pass_through_columns = var('classes_pass_through_columns', []) -%}
{%- set departments_pass_through_columns = var('departments_pass_through_columns', []) -%}
{%- set lookback_window = var('lookback_window', 3) -%}

{%- set transaction_level = not var('netsuite2__aggregate_income_statement', false) -%}
{# Incremental materialization can only be turned on when not aggregating #}
{%- set using_incremental = target.type not in ('bigquery', 'databricks', 'spark') and transaction_level -%}
{% set partition_by_field = '_fivetran_synced_date' if transaction_level else 'accounting_period_ending' %}
{% set pass_through_column_count = accounts_pass_through_columns|length + departments_pass_through_columns|length + classes_pass_through_columns|length + (income_statement_transaction_detail_columns|length if transaction_level else 0) %}
{% set variable_column_count = (2 if multibook_accounting_enabled else 0) + (3 if using_to_subsidiary and using_exchange_rate else 0) %}

{{
    config(
        enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2'),
        materialized='incremental' if using_incremental else 'table',
        partition_by = {'field': partition_by_field, 'data_type': 'date', 'granularity': 'month'}
            if target.type not in ['spark', 'databricks'] else [partition_by_field],
        cluster_by = ['transaction_id'] if transaction_level else ['account_id', 'accounting_period_id'],
        unique_key='income_statement_id',
        incremental_strategy = 'merge' if target.type in ('bigquery', 'databricks', 'spark') else 'delete+insert',
        file_format='delta'
    )
}}

with transactions_with_converted_amounts_init as (
    select * 
    from {{ ref('int_netsuite2__tran_with_converted_amounts') }}
    
    where transaction_accounting_period_id = reporting_accounting_period_id
        and is_income_statement 

    {% if is_incremental() %}
        {% if transaction_level %}
            and _fivetran_synced_date >= {{ netsuite.netsuite_lookback(from_date='max(_fivetran_synced_date)', datepart='day', interval=lookback_window) }}
        {% else %}
            and accounting_period_ending >= {{ netsuite.netsuite_lookback(from_date='max(accounting_period_ending)', datepart='day', interval=lookback_window) }}
        {% endif %}
    {% endif %}
), 

{% if transaction_level %}
transactions_with_converted_amounts as (
    select * 
    from transactions_with_converted_amounts_init
),

{% else %}
-- Aggregating: Removes transactions and transaction lines from the model's granularity
transactions_with_converted_amounts as (
    select 
        source_relation,
        account_id,
        account_name,
        account_display_name,
        account_type_name,
        account_type_id,
        account_number,
        account_category

        --The below script allows for accounts table pass through columns.
        {{ netsuite.persist_pass_through_columns(accounts_pass_through_columns) }},

        subsidiary_id,
        reporting_accounting_period_id,
        department_id,
        location_id,
        class_id,

        {% if multibook_accounting_enabled %}
        accounting_book_id,
        accounting_book_name,
        {% endif %}

        {% if using_to_subsidiary and using_exchange_rate %}
        to_subsidiary_id,
        to_subsidiary_name,
        to_subsidiary_currency_symbol,
        {% endif %}

        sum(converted_amount_using_transaction_accounting_period) as converted_amount_using_transaction_accounting_period,
        sum(unconverted_amount) as unconverted_amount

    from transactions_with_converted_amounts_init

    {{ dbt_utils.group_by(n=13 + variable_column_count + accounts_pass_through_columns|length) }}
),
{% endif %}

--Below is only used if income statement transaction detail columns are specified dbt_project.yml file.
{% if income_statement_transaction_detail_columns != [] and transaction_level %}
transaction_details as (
    select * 
    from {{ ref('netsuite2__transaction_details') }}
), 
{% endif %}

accounts as (
    select * 
    from {{ ref('int_netsuite2__accounts') }}
), 

accounting_periods as (
    select * 
    from {{ ref('int_netsuite2__accounting_periods') }}
),

subsidiaries as (
    select * 
    from {{ ref('stg_netsuite2__subsidiaries') }}
),

currencies as (
    select *
    from {{ ref('stg_netsuite2__currencies') }}
),

classes as (
    select * 
    from {{ ref('stg_netsuite2__classes') }}
),

locations as (
    select * 
    from {{ ref('stg_netsuite2__locations') }}
),

departments as (
    select * 
    from {{ ref('stg_netsuite2__departments') }}
),

primary_subsidiary_calendar as (
    select 
        fiscal_calendar_id, 
        source_relation 
    from subsidiaries 
    where parent_id is null
),

income_statement as (
    select
        transactions_with_converted_amounts.source_relation,
        {% if transaction_level %}
        transactions_with_converted_amounts.transaction_id,
        transactions_with_converted_amounts.transaction_line_id,
        transactions_with_converted_amounts._fivetran_synced_date,
        {% endif %}

        {% if multibook_accounting_enabled %}
        transactions_with_converted_amounts.accounting_book_id,
        transactions_with_converted_amounts.accounting_book_name,
        {% endif %}

        {% if using_to_subsidiary and using_exchange_rate %}
        transactions_with_converted_amounts.to_subsidiary_id,
        transactions_with_converted_amounts.to_subsidiary_name,
        transactions_with_converted_amounts.to_subsidiary_currency_symbol,
        {% endif %}

        reporting_accounting_periods.accounting_period_id as accounting_period_id,
        reporting_accounting_periods.ending_at as accounting_period_ending,
        reporting_accounting_periods.accounting_period_full_name,
        reporting_accounting_periods.name as accounting_period_name,
        reporting_accounting_periods.is_adjustment as is_accounting_period_adjustment,
        reporting_accounting_periods.is_closed as is_accounting_period_closed,
        transactions_with_converted_amounts.account_name,
        transactions_with_converted_amounts.account_display_name,
        transactions_with_converted_amounts.account_type_name,
        transactions_with_converted_amounts.account_type_id,
        transactions_with_converted_amounts.account_id,
        transactions_with_converted_amounts.account_number,
        subsidiaries.subsidiary_id,
        subsidiaries.full_name as subsidiary_full_name,
        subsidiaries.name as subsidiary_name,
        subsidiaries_currencies.symbol as subsidiary_currency_symbol

        --The below script allows for accounts table pass through columns.
        {{ netsuite.persist_pass_through_columns(accounts_pass_through_columns, identifier='transactions_with_converted_amounts') }},

        {{ dbt.concat(['transactions_with_converted_amounts.account_number',"'-'", 'transactions_with_converted_amounts.account_name']) }} as account_number_and_name,
        classes.class_id,
        classes.full_name as class_full_name

        --The below script allows for accounts table pass through columns.
        {{ netsuite.persist_pass_through_columns(classes_pass_through_columns, identifier='classes') }},

        locations.location_id,
        locations.full_name as location_full_name,
        departments.department_id,
        departments.full_name as department_full_name

        --The below script allows for departments table pass through columns.
        {{ netsuite.persist_pass_through_columns(departments_pass_through_columns, identifier='departments') }},

        transactions_with_converted_amounts.account_category as account_category,
        case when lower(transactions_with_converted_amounts.account_type_id) = 'income' then 1
            when lower(transactions_with_converted_amounts.account_type_id) = 'cogs' then 2
            when lower(transactions_with_converted_amounts.account_type_id) = 'expense' then 3
            when lower(transactions_with_converted_amounts.account_type_id) = 'othincome' then 4
            when lower(transactions_with_converted_amounts.account_type_id) = 'othexpense' then 5
            else null
            end as income_statement_sort_helper

        --Below is only used if income statement transaction detail columns are specified dbt_project.yml file.
        {% if income_statement_transaction_detail_columns != [] and transaction_level %}

        , transaction_details.{{ income_statement_transaction_detail_columns | join (", transaction_details.") }}

        {% endif %}

        , -sum(converted_amount_using_transaction_accounting_period) as converted_amount,

        -sum(unconverted_amount) as transaction_amount
        
    from transactions_with_converted_amounts

    left join departments
        on departments.department_id = transactions_with_converted_amounts.department_id
        and departments.source_relation = transactions_with_converted_amounts.source_relation

    left join locations
        on locations.location_id = transactions_with_converted_amounts.location_id
        and locations.source_relation = transactions_with_converted_amounts.source_relation

    left join classes
        on classes.class_id = transactions_with_converted_amounts.class_id
        and classes.source_relation = transactions_with_converted_amounts.source_relation

    left join accounting_periods as reporting_accounting_periods
        on reporting_accounting_periods.accounting_period_id = transactions_with_converted_amounts.reporting_accounting_period_id
        and reporting_accounting_periods.source_relation = transactions_with_converted_amounts.source_relation
    
    left join subsidiaries
        on transactions_with_converted_amounts.subsidiary_id = subsidiaries.subsidiary_id
        and transactions_with_converted_amounts.source_relation = subsidiaries.source_relation

    left join currencies subsidiaries_currencies
        on subsidiaries_currencies.currency_id = subsidiaries.currency_id
        and subsidiaries_currencies.source_relation = subsidiaries.source_relation

    --Below is only used if income statement transaction detail columns are specified dbt_project.yml file.
    {% if income_statement_transaction_detail_columns != [] and transaction_level %}
    join transaction_details
        on transaction_details.transaction_id = transactions_with_converted_amounts.transaction_id
        and transaction_details.transaction_line_id = transactions_with_converted_amounts.transaction_line_id
        and transaction_details.source_relation = transactions_with_converted_amounts.source_relation
        
        {% if multibook_accounting_enabled %}
        and transaction_details.accounting_book_id = transactions_with_converted_amounts.accounting_book_id
        {% endif %}

        {% if using_to_subsidiary and using_exchange_rate %}
        and transaction_details.to_subsidiary_id = transactions_with_converted_amounts.to_subsidiary_id
        {% endif %}
    {% endif %}

    join primary_subsidiary_calendar 
        on reporting_accounting_periods.fiscal_calendar_id = primary_subsidiary_calendar.fiscal_calendar_id
        and reporting_accounting_periods.source_relation = primary_subsidiary_calendar.source_relation

    {{ dbt_utils.group_by(n=26 + pass_through_column_count + variable_column_count + (3 if transaction_level else 0)) }}
),

surrogate_key as ( 
    {% set surrogate_key_fields = ['source_relation', 'transaction_line_id', 'transaction_id', 'accounting_period_id', 'account_name'] if transaction_level 
        else ['source_relation', 'accounting_period_id', 'account_name', 'account_id', 'subsidiary_id', 'department_id', 'location_id', 'class_id'] %}
    {% do surrogate_key_fields.append('to_subsidiary_id') if using_to_subsidiary and using_exchange_rate %}
    {% do surrogate_key_fields.append('accounting_book_id') if multibook_accounting_enabled %}

    select 
        *,
        {{ dbt_utils.generate_surrogate_key(surrogate_key_fields) }} as income_statement_id

    from income_statement
)

select *
from surrogate_key
