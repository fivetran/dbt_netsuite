{%- set multibook_accounting_enabled = var('netsuite2__multibook_accounting_enabled', false) -%}
{%- set using_to_subsidiary = var('netsuite2__using_to_subsidiary', false) -%}
{%- set using_exchange_rate = var('netsuite2__using_exchange_rate', true) -%}
{%- set using_vendor_categories = var('netsuite2__using_vendor_categories', true) -%}
{%- set accounts_pass_through_columns = var('accounts_pass_through_columns', []) -%}
{%- set departments_pass_through_columns = var('departments_pass_through_columns', []) -%}
{%- set locations_pass_through_columns = var('locations_pass_through_columns', []) -%}
{%- set subsidiaries_pass_through_columns = var('subsidiaries_pass_through_columns', []) -%}
{%- set transactions_pass_through_columns = var('transactions_pass_through_columns', []) -%}
{%- set transaction_lines_pass_through_columns = var('transaction_lines_pass_through_columns', []) -%}
{%- set lookback_window_date = netsuite.netsuite_lookback(from_date='max(transaction_line_fivetran_synced_date)', datepart='day', interval=var('lookback_window', 3)) -%}

{{
    config(
        enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2'),
        materialized='table' if target.type in ('bigquery', 'databricks', 'spark') else 'incremental',
        partition_by = {'field': 'transaction_line_fivetran_synced_date', 'data_type': 'date', 'granularity': 'month'}
            if target.type not in ['spark', 'databricks'] else ['transaction_line_fivetran_synced_date'],
        cluster_by = ['transaction_id'],
        unique_key='transaction_details_id',
        incremental_strategy = 'merge' if target.type in ('bigquery', 'databricks', 'spark') else 'delete+insert',
        file_format='delta'
    )
}}

with accounts as (
    select *
    from {{ ref('int_netsuite2__accounts') }}
),

classes as (
    select *
    from {{ ref('stg_netsuite2__classes') }}
),

customers as (
    select *
    from {{ ref('int_netsuite2__customers') }}
),

vendors as (
    select *
    from {{ ref('stg_netsuite2__vendors') }}
),

items as (
    select *
    from {{ ref('stg_netsuite2__items') }}
),

departments as (
    select *
    from {{ ref('stg_netsuite2__departments') }}
),

locations as (
    select *
    from {{ ref('int_netsuite2__locations') }}
),

transactions as (
    select *
    from {{ ref('stg_netsuite2__transactions') }}
),

subsidiaries as (
    select *
    from {{ ref('stg_netsuite2__subsidiaries') }}
),

base_transaction_lines as (
    select *
    from {{ ref('int_netsuite2__transaction_lines') }}
),

transaction_lines as (
    select
        *,
        cast(_fivetran_synced as date) as transaction_line_fivetran_synced_date
    from base_transaction_lines

    {% if is_incremental() %}
    where cast(_fivetran_synced as date) >= {{ lookback_window_date }}

    --- Include transaction lines with updated dimensional attributes
        or transaction_line_id in (
            -- Include transaction lines where accounts were updated
            select distinct base_transaction_lines.transaction_line_id
            from base_transaction_lines
            join accounts
                on accounts.account_id = base_transaction_lines.account_id
                and accounts.source_relation = base_transaction_lines.source_relation
                and cast(accounts._fivetran_synced as date) >= {{ lookback_window_date }}

            union all

            -- Include transaction lines where customers were updated (entity_id)
            select distinct base_transaction_lines.transaction_line_id
            from base_transaction_lines
            join customers
                on customers.customer_id = base_transaction_lines.entity_id
                and customers.source_relation = base_transaction_lines.source_relation
                and cast(customers._fivetran_synced as date) >= {{ lookback_window_date }}

            union all

            -- Include transaction lines where vendors were updated (entity_id)
            select distinct base_transaction_lines.transaction_line_id
            from base_transaction_lines
            join vendors
                on vendors.vendor_id = base_transaction_lines.entity_id
                and vendors.source_relation = base_transaction_lines.source_relation
                and cast(vendors._fivetran_synced as date) >= {{ lookback_window_date }}

            union all

            -- Include transaction lines where items were updated
            select distinct base_transaction_lines.transaction_line_id
            from base_transaction_lines
            join items
                on items.item_id = base_transaction_lines.item_id
                and items.source_relation = base_transaction_lines.source_relation
                and cast(items._fivetran_synced as date) >= {{ lookback_window_date }}

            union all

            -- Include transaction lines where departments were updated
            select distinct base_transaction_lines.transaction_line_id
            from base_transaction_lines
            join departments
                on departments.department_id = base_transaction_lines.department_id
                and departments.source_relation = base_transaction_lines.source_relation
                and cast(departments._fivetran_synced as date) >= {{ lookback_window_date }}

            union all

            -- Include transaction lines where locations were updated
            select distinct base_transaction_lines.transaction_line_id
            from base_transaction_lines
            join locations
                on locations.location_id = base_transaction_lines.location_id
                and locations.source_relation = base_transaction_lines.source_relation
                and cast(locations._fivetran_synced as date) >= {{ lookback_window_date }}

            union all

            -- Include transaction lines where subsidiaries were updated
            select distinct base_transaction_lines.transaction_line_id
            from base_transaction_lines
            join subsidiaries
                on subsidiaries.subsidiary_id = base_transaction_lines.subsidiary_id
                and subsidiaries.source_relation = base_transaction_lines.source_relation
                and cast(subsidiaries._fivetran_synced as date) >= {{ lookback_window_date }}

            union all

            -- Include transaction lines where transactions were updated
            select distinct base_transaction_lines.transaction_line_id
            from base_transaction_lines
            join transactions
                on transactions.transaction_id = base_transaction_lines.transaction_id
                and transactions.source_relation = base_transaction_lines.source_relation
                and cast(transactions._fivetran_synced as date) >= {{ lookback_window_date }}

            union all

            -- Include transaction lines where classes were updated
            select distinct base_transaction_lines.transaction_line_id
            from base_transaction_lines
            join classes
                on classes.class_id = base_transaction_lines.class_id
                and classes.source_relation = base_transaction_lines.source_relation
                and cast(classes._fivetran_synced as date) >= {{ lookback_window_date }}
        )
    {% endif %}
),

transactions_with_converted_amounts as (
    select * 
    from {{ ref('int_netsuite2__tran_with_converted_amounts') }}
),

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

transactions as (
    select * 
    from {{ ref('stg_netsuite2__transactions') }}
),

customers as (
    select * 
    from {{ ref('int_netsuite2__customers') }}
),

items as (
    select *
    from {{ ref('stg_netsuite2__items') }}
),

locations as (
    select * 
    from {{ ref('int_netsuite2__locations') }}
    {{ netsuite.persist_pass_through_columns(departments_pass_through_columns, identifier='departments') }},

    subsidiaries.subsidiary_id,
    subsidiaries.full_name as subsidiary_full_name,
    subsidiaries.name as subsidiary_name,
    subsidiaries_currencies.symbol as subsidiary_currency_symbol

    --The below script allows for subsidiaries table pass through columns.
    {{ netsuite.persist_pass_through_columns(subsidiaries_pass_through_columns, identifier='subsidiaries') }},

    case
      when lower(accounts.account_type_id) in ('income', 'othincome') then -transactions_with_converted_amounts.converted_amount_using_transaction_accounting_period
      else transactions_with_converted_amounts.converted_amount_using_transaction_accounting_period
        end as converted_amount,
    case
      when lower(accounts.account_type_id) in ('income', 'othincome') then -transaction_lines.amount
      else transaction_lines.amount
        end as transaction_amount,
    case
      when lower(accounts.account_type_id) in ('income', 'othincome') then -transaction_lines.netamount
      else transaction_lines.netamount
        end as transaction_line_amount  
  from transaction_lines

  join transactions
    on transactions.transaction_id = transaction_lines.transaction_id
    and transactions.source_relation = transaction_lines.source_relation

  left join transactions_with_converted_amounts
    on transactions_with_converted_amounts.transaction_line_id = transaction_lines.transaction_line_id
      and transactions_with_converted_amounts.transaction_id = transaction_lines.transaction_id
      and transactions_with_converted_amounts.source_relation = transaction_lines.source_relation

      and transactions_with_converted_amounts.transaction_accounting_period_id = transactions_with_converted_amounts.reporting_accounting_period_id
      and transactions_with_converted_amounts.source_relation = transactions_with_converted_amounts.source_relation

      {% if multibook_accounting_enabled %}
      and transactions_with_converted_amounts.accounting_book_id = transaction_lines.accounting_book_id
      {% endif %}

  left join accounts
    on accounts.account_id = transaction_lines.account_id
    and accounts.source_relation = transaction_lines.source_relation

  left join accounts as parent_account
    on parent_account.account_id = accounts.parent_id
    and parent_account.source_relation = accounts.source_relation

  left join accounting_periods
    on accounting_periods.accounting_period_id = transactions.accounting_period_id
    and accounting_periods.source_relation = transactions.source_relation

  left join customers customers__transactions
    on customers__transactions.customer_id = transactions.entity_id
    and customers__transactions.source_relation = transactions.source_relation

  left join customers customers__transaction_lines
    on customers__transaction_lines.customer_id = transaction_lines.entity_id
    and customers__transaction_lines.source_relation = transaction_lines.source_relation

  left join classes
    on classes.class_id = transaction_lines.class_id
    and classes.source_relation = transaction_lines.source_relation

  left join items
    on items.item_id = transaction_lines.item_id
    and items.source_relation = transaction_lines.source_relation

  left join locations
    on locations.location_id = transaction_lines.location_id
    and locations.source_relation = transaction_lines.source_relation

  left join nexuses
    on nexuses.nexus_id = transactions.nexus_id
    and nexuses.source_relation = transactions.source_relation

  left join vendors vendors__nexuses
    on vendors__nexuses.vendor_id = nexuses.tax_agency_id
    and vendors__nexuses.source_relation = nexuses.source_relation

  left join vendors vendors__transactions
    on vendors__transactions.vendor_id = transactions.entity_id
    and vendors__transactions.source_relation = transactions.source_relation

  left join vendors vendors__transaction_lines
    on vendors__transaction_lines.vendor_id = transaction_lines.entity_id
    and vendors__transaction_lines.source_relation = transaction_lines.source_relation

  {% if using_vendor_categories %}
  left join vendor_categories vendor_categories__transactions
    on vendor_categories__transactions.vendor_category_id = vendors__transactions.vendor_category_id
    and vendor_categories__transactions.source_relation = vendors__transactions.source_relation

  left join vendor_categories vendor_categories__transaction_lines
    on vendor_categories__transaction_lines.vendor_category_id = vendors__transaction_lines.vendor_category_id
    and vendor_categories__transaction_lines.source_relation = vendors__transaction_lines.source_relation
  {% endif %}

  left join currencies
    on currencies.currency_id = transactions.currency_id
    and currencies.source_relation = transactions.source_relation

  left join departments
    on departments.department_id = transaction_lines.department_id
    and departments.source_relation = transaction_lines.source_relation

  join subsidiaries
    on subsidiaries.subsidiary_id = transaction_lines.subsidiary_id
    and subsidiaries.source_relation = transaction_lines.source_relation

  left join currencies subsidiaries_currencies
    on subsidiaries_currencies.currency_id = subsidiaries.currency_id
    and subsidiaries_currencies.source_relation = subsidiaries.source_relation
  
  left join primary_subsidiary_calendar
    on accounting_periods.fiscal_calendar_id = primary_subsidiary_calendar.fiscal_calendar_id
    and accounting_periods.source_relation = primary_subsidiary_calendar.source_relation
    
  where accounting_periods.fiscal_calendar_id is null
    or primary_subsidiary_calendar.fiscal_calendar_id is not null
),

surrogate_key as ( 
    {% set surrogate_key_fields = ['source_relation', 'transaction_line_id', 'transaction_id'] %}
    {% do surrogate_key_fields.append('to_subsidiary_id') if using_to_subsidiary and using_exchange_rate %}
    {% do surrogate_key_fields.append('accounting_book_id') if multibook_accounting_enabled %}

    select 
        *,
        {{ dbt_utils.generate_surrogate_key(surrogate_key_fields) }} as transaction_details_id

    from transaction_details
)

select *
from surrogate_key