{%- set multibook_accounting_enabled = var('netsuite2__multibook_accounting_enabled', false) -%}
{%- set using_to_subsidiary = var('netsuite2__using_to_subsidiary', false) -%}
{%- set using_exchange_rate = var('netsuite2__using_exchange_rate', true) -%}
{%- set using_incremental = var('netsuite2__using_incremental', false) -%}
{%- set income_statement_transaction_detail_columns = var('income_statement_transaction_detail_columns', []) -%}
{%- set accounts_pass_through_columns = var('accounts_pass_through_columns', []) -%}
{%- set classes_pass_through_columns = var('classes_pass_through_columns', []) -%}
{%- set departments_pass_through_columns = var('departments_pass_through_columns', []) -%}
{%- set lookback_window = var('lookback_window', 3) -%}

{{
    config(
        enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2'),
        materialized='incremental' if using_incremental else 'table',
        partition_by = {'field': '_fivetran_synced_date', 'data_type': 'date', 'granularity': 'month'}
            if target.type not in ['spark', 'databricks'] else ['_fivetran_synced_date'],
        unique_key='income_statement_id',
        incremental_strategy = 'merge' if target.type in ('bigquery', 'databricks', 'spark') else 'delete+insert',
        file_format='delta'
    )
}}

with transactions_with_converted_amounts as (
    select * 
    from {{ ref('int_netsuite2__tran_with_converted_amounts') }}

    {% if is_incremental() %}
    where _fivetran_synced_date >= {{ netsuite.netsuite_lookback(from_date='max(_fivetran_synced_date)', datepart='day', interval=lookback_window)  }}
    {% endif %}
), 

--Below is only used if income statement transaction detail columns are specified dbt_project.yml file.
{% if income_statement_transaction_detail_columns != [] %}
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

transaction_lines as (
    select * 
    from {{ ref('int_netsuite2__transaction_lines') }}
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
        transactions_with_converted_amounts.transaction_id,
        transactions_with_converted_amounts.transaction_line_id,
        transactions_with_converted_amounts._fivetran_synced_date,

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
        accounts.name as account_name,
        accounts.display_name as account_display_name,
        accounts.type_name as account_type_name,
        accounts.account_type_id,
        accounts.account_id as account_id,
        accounts.account_number,
        subsidiaries.subsidiary_id,
        subsidiaries.full_name as subsidiary_full_name,
        subsidiaries.name as subsidiary_name,
        subsidiaries_currencies.symbol as subsidiary_currency_symbol

        --The below script allows for accounts table pass through columns.
        {{ netsuite.persist_pass_through_columns(accounts_pass_through_columns, identifier='accounts') }},

        {{ dbt.concat(['accounts.account_number',"'-'", 'accounts.name']) }} as account_number_and_name,
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
        case when lower(accounts.account_type_id) = 'income' then 1
            when lower(accounts.account_type_id) = 'cogs' then 2
            when lower(accounts.account_type_id) = 'expense' then 3
            when lower(accounts.account_type_id) = 'othincome' then 4
            when lower(accounts.account_type_id) = 'othexpense' then 5
            else null
            end as income_statement_sort_helper

        --Below is only used if income statement transaction detail columns are specified dbt_project.yml file.
        {% if income_statement_transaction_detail_columns != [] %}

        , transaction_details.{{ income_statement_transaction_detail_columns | join (", transaction_details.") }}

        {% endif %}

        , -converted_amount_using_transaction_accounting_period as converted_amount,

        -unconverted_amount as transaction_amount
        
    from transactions_with_converted_amounts

    join transaction_lines as transaction_lines
        on transaction_lines.transaction_line_id = transactions_with_converted_amounts.transaction_line_id
            and transaction_lines.transaction_id = transactions_with_converted_amounts.transaction_id
            and transaction_lines.source_relation = transactions_with_converted_amounts.source_relation

            {% if multibook_accounting_enabled %}
            and transaction_lines.accounting_book_id = transactions_with_converted_amounts.accounting_book_id
            {% endif %}

    left join departments
        on departments.department_id = transaction_lines.department_id
        and departments.source_relation = transaction_lines.source_relation
    
    left join accounts
        on accounts.account_id = transactions_with_converted_amounts.account_id
        and accounts.source_relation = transactions_with_converted_amounts.source_relation

    left join locations
        on locations.location_id = transaction_lines.location_id
        and locations.source_relation = transaction_lines.source_relation

    left join classes
        on classes.class_id = transaction_lines.class_id
        and classes.source_relation = transaction_lines.source_relation

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
    {% if income_statement_transaction_detail_columns != [] %}
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

    where transactions_with_converted_amounts.transaction_accounting_period_id = transactions_with_converted_amounts.reporting_accounting_period_id
        and transactions_with_converted_amounts.is_income_statement
),

surrogate_key as ( 
    {% set surrogate_key_fields = ['source_relation', 'transaction_line_id', 'transaction_id', 'accounting_period_id', 'account_name'] %}
    {% do surrogate_key_fields.append('to_subsidiary_id') if using_to_subsidiary and using_exchange_rate %}
    {% do surrogate_key_fields.append('accounting_book_id') if multibook_accounting_enabled %}

    select 
        *,
        {{ dbt_utils.generate_surrogate_key(surrogate_key_fields) }} as income_statement_id

    from income_statement
)

select *
from surrogate_key
