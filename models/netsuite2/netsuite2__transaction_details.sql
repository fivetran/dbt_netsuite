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

with transaction_lines as (
    select 
      *,
      cast(_fivetran_synced as date) as transaction_line_fivetran_synced_date

    from {{ ref('int_netsuite2__transaction_lines') }}

    {% if is_incremental() %}
    where cast(_fivetran_synced as date) >= {{ netsuite.netsuite_lookback(from_date='max(transaction_line_fivetran_synced_date)', datepart='day', interval=var('lookback_window', 3)) }}
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
),

nexuses as (
    select *
    from {{ ref('stg_netsuite2__nexuses') }}
),

vendors as (
    select * 
    from {{ ref('stg_netsuite2__vendors') }}
),

{% if var('netsuite2__using_vendor_categories', true) %}
vendor_categories as (
    select * 
    from {{ ref('stg_netsuite2__vendor_categories') }}
),
{% endif %}

departments as (
    select * 
    from {{ ref('stg_netsuite2__departments') }}
),

currencies as (
    select * 
    from {{ ref('stg_netsuite2__currencies') }}
),

classes as (
    select *
    from {{ ref('stg_netsuite2__classes') }}
),

transaction_details as (
  select

    {% if var('netsuite2__multibook_accounting_enabled', false) %}
    transaction_lines.accounting_book_id,
    transaction_lines.accounting_book_name,
    {% endif %}

    {% if var('netsuite2__using_to_subsidiary', false) and var('netsuite2__using_exchange_rate', true) %}
    transactions_with_converted_amounts.to_subsidiary_id,
    transactions_with_converted_amounts.to_subsidiary_name,
    transactions_with_converted_amounts.to_subsidiary_currency_symbol,
    {% endif %}

    transaction_lines.transaction_line_id,
    transaction_lines.memo as transaction_memo,
    not transaction_lines.is_posting as is_transaction_non_posting,
    transaction_lines.is_main_line,
    transaction_lines.is_tax_line,
    transaction_lines.is_closed,
    transactions.transaction_id,
    transactions.status as transaction_status,
    transactions.transaction_date,
    transactions.due_date_at as transaction_due_date,
    transactions.transaction_type as transaction_type,
    transactions.nexus_id,
    nexuses.country as nexus_country,
    nexuses.state as nexus_state,
    nexuses.tax_agency_id,
    vendors__nexuses.alt_name as tax_agency_alt_name,
    transactions.is_nexus_override,
    transactions.is_tax_details_override,
    transactions.tax_point_date,
    transactions.tax_point_date_override,
    transaction_lines.transaction_line_fivetran_synced_date,
    transactions.transaction_number,
    coalesce(transaction_lines.entity_id, transactions.entity_id) as entity_id,
    transactions.is_intercompany_adjustment as is_transaction_intercompany_adjustment,
    transactions.is_reversal,
    transactions.reversal_transaction_id,
    transactions.reversal_date,
    transactions.is_reversal_defer

    --The below script allows for transactions table pass through columns.
    
    {{ netsuite.persist_pass_through_columns(var('transactions_pass_through_columns', []), identifier='transactions') }}

    --The below script allows for transaction lines table pass through columns.
    
    {{ netsuite.persist_pass_through_columns(var('transaction_lines_pass_through_columns', []), identifier='transaction_lines') }},

    accounting_periods.ending_at as accounting_period_ending,
    accounting_periods.name as accounting_period_name,
    accounting_periods.accounting_period_id as accounting_period_id,
    accounting_periods.is_adjustment as is_accounting_period_adjustment,
    accounting_periods.is_closed as is_accounting_period_closed,
    accounts.name as account_name,
    accounts.display_name as account_display_name,
    accounts.type_name as account_type_name,
    accounts.account_type_id,
    accounts.account_id as account_id,
    accounts.account_number

    --The below script allows for accounts table pass through columns.
    {{ netsuite.persist_pass_through_columns(var('accounts_pass_through_columns', []), identifier='accounts') }},

    accounts.is_leftside as is_account_leftside,
    lower(accounts.account_type_id) = 'acctpay' as is_accounts_payable,
    lower(accounts.account_type_id) = 'acctrec' as is_accounts_receivable,
    accounts.is_eliminate as is_account_intercompany,
    transaction_lines.is_eliminate,
    coalesce(parent_account.account_id, accounts.account_id) as parent_account_id,
    coalesce(parent_account.name, accounts.name) as parent_account_name,
    lower(accounts.account_type_id) in ('expense', 'othexpense', 'deferexpense') as is_expense_account,
    lower(accounts.account_type_id) in ('income', 'othincome') as is_income_account,
    case 
      when lower(transactions.transaction_type) in ('custinvc', 'custcred') then customers__transactions.customer_id
      else customers__transaction_lines.customer_id
        end as customer_id,
    case 
      when lower(transactions.transaction_type) in ('custinvc', 'custcred') then customers__transactions.alt_name
      else customers__transaction_lines.alt_name
        end as customer_alt_name,
    case 
      when lower(transactions.transaction_type) in ('custinvc', 'custcred') then customers__transactions.company_name
      else customers__transaction_lines.company_name
        end as company_name,
    case 
      when lower(transactions.transaction_type) in ('custinvc', 'custcred') then customers__transactions.city
      else customers__transaction_lines.city
        end as customer_city,
    case 
      when lower(transactions.transaction_type) in ('custinvc', 'custcred') then customers__transactions.state
      else customers__transaction_lines.state
        end as customer_state,
    case 
      when lower(transactions.transaction_type) in ('custinvc', 'custcred') then customers__transactions.zipcode
      else customers__transaction_lines.zipcode
        end as customer_zipcode,
    case 
      when lower(transactions.transaction_type) in ('custinvc', 'custcred') then customers__transactions.country
      else customers__transaction_lines.country
        end as customer_country,
    case 
      when lower(transactions.transaction_type) in ('custinvc', 'custcred') then customers__transactions.date_first_order_at
      else customers__transaction_lines.date_first_order_at
        end as customer_date_first_order,
    case 
      when lower(transactions.transaction_type) in ('custinvc', 'custcred') then customers__transactions.customer_external_id
      else customers__transaction_lines.customer_external_id
        end as customer_external_id,
    classes.class_id,
    classes.full_name as class_full_name,
    transaction_lines.item_id,
    items.name as item_name,
    items.type_name as item_type_name,
    items.sales_description,
    locations.location_id,
    locations.name as location_name,
    locations.city as location_city,
    locations.country as location_country

    -- The below script allows for locations table pass through columns.
    {{ netsuite.persist_pass_through_columns(var('locations_pass_through_columns', []), identifier='locations') }},

    {% if var('netsuite2__using_vendor_categories', true) %}
    case 
      when lower(transactions.transaction_type) in ('vendbill', 'vendcred') then vendor_categories__transactions.vendor_category_id
      else vendor_categories__transaction_lines.vendor_category_id
        end as vendor_category_id,
    case 
      when lower(transactions.transaction_type) in ('vendbill', 'vendcred') then vendor_categories__transactions.name
      else vendor_categories__transaction_lines.name
        end as vendor_category_name,
    {% endif %}
    case 
      when lower(transactions.transaction_type) in ('vendbill', 'vendcred') then vendors__transactions.vendor_id
      else vendors__transaction_lines.vendor_id
        end as vendor_id,
    case 
      when lower(transactions.transaction_type) in ('vendbill', 'vendcred') then vendors__transactions.alt_name
      else vendors__transaction_lines.alt_name
        end as vendor_alt_name,
    case 
      when lower(transactions.transaction_type) in ('vendbill', 'vendcred') then vendors__transactions.company_name
      else vendors__transaction_lines.company_name
        end as vendor_name,
    case 
      when lower(transactions.transaction_type) in ('vendbill', 'vendcred') then vendors__transactions.create_date_at
      else vendors__transaction_lines.create_date_at
        end as vendor_create_date,
    currencies.currency_id,
    currencies.name as currency_name,
    currencies.symbol as currency_symbol,
    transaction_lines.department_id,
    transaction_lines.exchange_rate,
    departments.full_name as department_full_name,
    departments.name as department_name

    --The below script allows for departments table pass through columns.
    {{ netsuite.persist_pass_through_columns(var('departments_pass_through_columns', []), identifier='departments') }},

    subsidiaries.subsidiary_id,
    subsidiaries.full_name as subsidiary_full_name,
    subsidiaries.name as subsidiary_name,
    subsidiaries_currencies.symbol as subsidiary_currency_symbol

    --The below script allows for subsidiaries table pass through columns.
    {{ netsuite.persist_pass_through_columns(var('subsidiaries_pass_through_columns', []), identifier='subsidiaries') }},

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

  left join transactions_with_converted_amounts
    on transactions_with_converted_amounts.transaction_line_id = transaction_lines.transaction_line_id
      and transactions_with_converted_amounts.transaction_id = transaction_lines.transaction_id
      and transactions_with_converted_amounts.transaction_accounting_period_id = transactions_with_converted_amounts.reporting_accounting_period_id

      {% if var('netsuite2__multibook_accounting_enabled', false) %}
      and transactions_with_converted_amounts.accounting_book_id = transaction_lines.accounting_book_id
      {% endif %}

  left join accounts 
    on accounts.account_id = transaction_lines.account_id

  left join accounts as parent_account 
    on parent_account.account_id = accounts.parent_id

  left join accounting_periods 
    on accounting_periods.accounting_period_id = transactions.accounting_period_id

  left join customers customers__transactions
    on customers__transactions.customer_id = transactions.entity_id

  left join customers customers__transaction_lines
    on customers__transaction_lines.customer_id = transaction_lines.entity_id

  left join classes
    on classes.class_id = transaction_lines.class_id

  left join items 
    on items.item_id = transaction_lines.item_id

  left join locations 
    on locations.location_id = transaction_lines.location_id

  left join nexuses
    on nexuses.nexus_id = transactions.nexus_id

  left join vendors vendors__nexuses
    on vendors__nexuses.vendor_id = nexuses.tax_agency_id

  left join vendors vendors__transactions
    on vendors__transactions.vendor_id = transactions.entity_id

  left join vendors vendors__transaction_lines
    on vendors__transaction_lines.vendor_id = transaction_lines.entity_id

  {% if var('netsuite2__using_vendor_categories', true) %}
  left join vendor_categories vendor_categories__transactions
    on vendor_categories__transactions.vendor_category_id = vendors__transactions.vendor_category_id

  left join vendor_categories vendor_categories__transaction_lines
    on vendor_categories__transaction_lines.vendor_category_id = vendors__transaction_lines.vendor_category_id
  {% endif %}

  left join currencies 
    on currencies.currency_id = transactions.currency_id

  left join departments 
    on departments.department_id = transaction_lines.department_id

  join subsidiaries 
    on subsidiaries.subsidiary_id = transaction_lines.subsidiary_id
 
  left join currencies subsidiaries_currencies
    on subsidiaries_currencies.currency_id = subsidiaries.currency_id
  
  where (accounting_periods.fiscal_calendar_id is null
    or accounting_periods.fiscal_calendar_id  = (select fiscal_calendar_id from subsidiaries where parent_id is null))
),

surrogate_key as ( 
    {% set surrogate_key_fields = ['transaction_line_id', 'transaction_id'] %}
    {% do surrogate_key_fields.append('to_subsidiary_id') if var('netsuite2__using_to_subsidiary', false) and var('netsuite2__using_exchange_rate', true) %}
    {% do surrogate_key_fields.append('accounting_book_id') if var('netsuite2__multibook_accounting_enabled', false) %}

    select 
        *,
        {{ dbt_utils.generate_surrogate_key(surrogate_key_fields) }} as transaction_details_id

    from transaction_details
)

select *
from surrogate_key
