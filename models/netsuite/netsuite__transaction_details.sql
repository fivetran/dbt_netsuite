{{ config(enabled=var('netsuite_data_model', 'netsuite') == 'netsuite') }}

with transactions_with_converted_amounts as (
    select * 
    from {{ref('int_netsuite__transactions_with_converted_amounts')}}
),

accounts as (
    select * 
    from {{ var('netsuite_accounts') }}
),

accounting_periods as (
    select * 
    from {{ var('netsuite_accounting_periods') }}
),

subsidiaries as (
    select * 
    from {{ var('netsuite_subsidiaries') }}
),

transaction_lines as (
    select * 
    from {{ var('netsuite_transaction_lines') }}
),

transactions as (
    select * 
    from {{ var('netsuite_transactions') }}
),

income_accounts as (
    select * 
    from {{ var('netsuite_income_accounts') }}
),

expense_accounts as (
    select * 
    from {{ var('netsuite_expense_accounts') }}
),

customers as (
    select * 
    from {{ var('netsuite_customers') }}
),

items as (
    select * 
    from {{ var('netsuite_items') }}
),

locations as (
    select * 
    from {{ var('netsuite_locations') }}
),

vendors as (
    select * 
    from {{ var('netsuite_vendors') }}
),

vendor_types as (
    select * 
    from {{ var('netsuite_vendor_types') }}
),

departments as (
    select * 
    from {{ var('netsuite_departments') }}
),

currencies as (
    select * 
    from {{ var('netsuite_currencies') }}
),

classes as (
    select *
    from {{ var('netsuite_classes') }}
),

transaction_details as (
  select
    transaction_lines.transaction_line_id,
    transaction_lines.memo as transaction_memo,
    lower(transaction_lines.non_posting_line) = 'yes' as is_transaction_non_posting,
    transactions.transaction_id,
    transactions.status as transaction_status,
    transactions.transaction_date,
    transactions.due_date_at as transaction_due_date,
    transactions.transaction_type as transaction_type,
    (lower(transactions.is_advanced_intercompany) = 'yes' or lower(transactions.is_intercompany) = 'yes') as is_transaction_intercompany,

    --The below script allows for transactions table pass through columns.
    {% if var('transactions_pass_through_columns') %}

    transactions.{{ var('transactions_pass_through_columns') | join (", transactions.")}} ,

    {% endif %}

    --The below script allows for transaction lines table pass through columns.
    {% if var('transaction_lines_pass_through_columns') %}
    
    transaction_lines.{{ var('transaction_lines_pass_through_columns') | join (", transaction_lines.")}} ,

    {% endif %}

    accounting_periods.ending_at as accounting_period_ending,
    accounting_periods.full_name as accounting_period_full_name,
    accounting_periods.name as accounting_period_name,
    lower(accounting_periods.is_adjustment) = 'yes' as is_accounting_period_adjustment,
    lower(accounting_periods.is_closed) = 'yes' as is_accounting_period_closed,
    accounts.name as account_name,
    accounts.type_name as account_type_name,
    accounts.account_id as account_id,
    accounts.account_number,

    --The below script allows for accounts table pass through columns.
    {% if var('accounts_pass_through_columns') %}
    
    accounts.{{ var('accounts_pass_through_columns') | join (", accounts.")}} ,

    {% endif %}

    lower(accounts.is_leftside) = 't' as is_account_leftside,
    lower(accounts.type_name) like 'accounts payable%' as is_accounts_payable,
    lower(accounts.type_name) like 'accounts receivable%' as is_accounts_receivable,
    lower(accounts.name) like '%intercompany%' as is_account_intercompany,
    coalesce(parent_account.name, accounts.name) as parent_account_name,
    income_accounts.income_account_id is not null as is_income_account,
    expense_accounts.expense_account_id is not null as is_expense_account,
    customers.company_name,
    customers.city as customer_city,
    customers.state as customer_state,
    customers.zipcode as customer_zipcode,
    customers.country as customer_country,
    customers.date_first_order_at as customer_date_first_order,
    customers.customer_external_id,
    classes.full_name as class_full_name,
    items.name as item_name,
    items.type_name as item_type_name,
    items.sales_description,
    locations.name as location_name,
    locations.city as location_city,
    locations.country as location_country,
    vendor_types.name as vendor_type_name,
    vendors.company_name as vendor_name,
    vendors.create_date_at as vendor_create_date,
    currencies.name as currency_name,
    currencies.symbol as currency_symbol,
    departments.name as department_name,

    --The below script allows for departments table pass through columns.
    {% if var('departments_pass_through_columns') %}
    
    departments.{{ var('departments_pass_through_columns') | join (", departments.")}} ,

    {% endif %}

    subsidiaries.name as subsidiary_name,
    case
      when lower(accounts.type_name) = 'income' or lower(accounts.type_name) = 'other income' then -converted_amount_using_transaction_accounting_period
      else converted_amount_using_transaction_accounting_period
        end as converted_amount,
    case
      when lower(accounts.type_name) = 'income' or lower(accounts.type_name) = 'other income' then -transaction_lines.amount
      else transaction_lines.amount
        end as transaction_amount
  from transaction_lines

  join transactions
    on transactions.transaction_id = transaction_lines.transaction_id

  left join transactions_with_converted_amounts as transactions_with_converted_amounts
    on transactions_with_converted_amounts.transaction_line_id = transaction_lines.transaction_line_id
      and transactions_with_converted_amounts.transaction_id = transaction_lines.transaction_id
      and transactions_with_converted_amounts.transaction_accounting_period_id = transactions_with_converted_amounts.reporting_accounting_period_id

  left join accounts 
    on accounts.account_id = transaction_lines.account_id

  left join accounts as parent_account 
    on parent_account.account_id = accounts.parent_id

  left join accounting_periods 
    on accounting_periods.accounting_period_id = transactions.accounting_period_id
  left join income_accounts 
    on income_accounts.income_account_id = accounts.account_id

  left join expense_accounts 
    on expense_accounts.expense_account_id = accounts.account_id

  left join customers 
    on customers.customer_id = transaction_lines.company_id
  
  left join classes
    on classes.class_id = transaction_lines.class_id

  left join items 
    on items.item_id = transaction_lines.item_id

  left join locations 
    on locations.location_id = transaction_lines.location_id

  left join vendors 
    on vendors.vendor_id = transaction_lines.company_id

  left join vendor_types 
    on vendor_types.vendor_type_id = vendors.vendor_type_id

  left join currencies 
    on currencies.currency_id = transactions.currency_id

  left join departments 
    on departments.department_id = transaction_lines.department_id

  join subsidiaries 
    on subsidiaries.subsidiary_id = transaction_lines.subsidiary_id
    
  where (accounting_periods.fiscal_calendar_id is null
    or accounting_periods.fiscal_calendar_id  = (select fiscal_calendar_id from subsidiaries where parent_id is null))
)

select *
from transaction_details