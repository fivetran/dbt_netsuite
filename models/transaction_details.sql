with transactions_with_converted_amounts as (
    select * from {{ref('transactions_with_converted_amounts')}}
),
accounts as (
    select * from {{ source('netsuite', 'accounts') }}
),
accounting_periods as (
    select * from {{ source('netsuite', 'accounting_periods') }}
),
subsidiaries as (
    select * from {{ source('netsuite', 'subsidiaries') }}
),
transaction_lines as (
    select * from {{ source('netsuite', 'transaction_lines') }}
),
transactions as (
    select * from {{ source('netsuite', 'transactions') }}
),
income_accounts as (
    select * from {{ source('netsuite', 'income_accounts') }}
),
expense_accounts as (
    select * from {{ source('netsuite', 'expense_accounts') }}
),
customers as (
    select * from {{ source('netsuite', 'customers') }}
),
items as (
    select * from {{ source('netsuite', 'items') }}
),
locations as (
    select * from {{ source('netsuite', 'locations') }}
),
vendors as (
    select * from {{ source('netsuite', 'vendors') }}
),
vendor_types as (
    select * from {{ source('netsuite', 'vendor_types') }}
),
departments as (
    select * from {{ source('netsuite', 'departments') }}
),
currencies as (
    select * from {{ source('netsuite', 'currencies') }}
),
classes as (
    select * from {{ source('netsuite', 'classes') }}
)

select
  transaction_lines.transaction_line_id,
  transaction_lines.memo as transaction_memo,
  lower(transaction_lines.non_posting_line) = 'yes' as is_transaction_non_posting,
  transactions.transaction_id,
  transactions.status as transaction_status,
  transactions.trandate as transaction_date,
  transactions.due_date as transaction_due_date,
  transactions.transaction_type as transaction_type,
  (lower(transactions.is_advanced_intercompany) = 'yes' or lower(transactions.is_intercompany) = 'yes') as is_transaction_intercompany,
  accounting_periods.ending as accounting_period_ending,
  accounting_periods.full_name as accounting_period_full_name,
  accounting_periods.name as accounting_period_name,
  lower(accounting_periods.is_adjustment) = 'yes' as is_accounting_period_adjustment,
  lower(accounting_periods.closed) = 'yes' as is_accounting_period_closed,
  accounts.name as account_name,
  accounts.type_name as account_type_name,
  accounts.account_id as account_id,
  accounts.accountnumber as account_number,
  lower(accounts.is_leftside) = 't' as is_account_leftside,
  lower(accounts.type_name) like 'accounts payable%' as is_accounts_payable,
  lower(accounts.type_name) like 'accounts receivable%' as is_accounts_receivable,
  lower(accounts.name) like '%intercompany%' as is_account_intercompany,
  coalesce(parent_account.name, accounts.name) as parent_account_name,
  income_accounts.income_account_id is not null as is_income_account,
  expense_accounts.expense_account_id is not null as is_expense_account,
  customers.companyname as customer_company_name,
  customers.city as customer_city,
  customers.state as customer_state,
  customers.zipcode as customer_zipcode,
  customers.country as customer_country,
  customers.date_first_order as customer_date_first_order,
  customers.customer_extid,
  items.name as item_name,
  items.type_name as item_type_name,
  items.salesdescription as item_sales_description,
  locations.name as location_name,
  locations.city as location_city,
  locations.country as location_country,
  vendor_types.name as vendor_type_name,
  vendors.companyname as vendor_name,
  vendors.create_date as vendor_create_date,
  currencies.name as currency_name,
  currencies.symbol as currency_symbol,
  departments.name as department_name,
  subsidiaries.name as subsidiary_name,
  case
    when lower(accounts.type_name) = 'income' or lower(accounts.type_name) = 'other income' then -converted_amount_using_transaction_accounting_period
    else converted_amount_using_transaction_accounting_period
    end as converted_amount,
  case
    when lower(accounts.type_name) = 'income' or lower(accounts.type_name) = 'other income' then -transaction_lines.amount
    else transaction_lines.amount
    end as transaction_amount,
  transaction_lines.class_id as class_id,
  classes.full_name as class_full_name
from transaction_lines
join transactions on transactions.transaction_id = transaction_lines.transaction_id
  and not transactions._fivetran_deleted
left join transactions_with_converted_amounts as transactions_with_converted_amounts
  on transactions_with_converted_amounts.transaction_line_id = transaction_lines.transaction_line_id
  and transactions_with_converted_amounts.transaction_id = transaction_lines.transaction_id
  and transactions_with_converted_amounts.transaction_accounting_period_id = transactions_with_converted_amounts.reporting_accounting_period_id
left join accounts on accounts.account_id = transaction_lines.account_id
left join accounts as parent_account on parent_account.account_id = accounts.parent_id
left join accounting_periods on accounting_periods.accounting_period_id = transactions.accounting_period_id
left join income_accounts on income_accounts.income_account_id = accounts.account_id
left join expense_accounts on expense_accounts.expense_account_id = accounts.account_id
left join customers on customers.customer_id = transaction_lines.company_id
  and not customers._fivetran_deleted
left join items on items.item_id = transaction_lines.item_id
  and not items._fivetran_deleted
left join locations on locations.location_id = transaction_lines.location_id
left join vendors on vendors.vendor_id = transaction_lines.company_id
  and not vendors._fivetran_deleted
left join vendor_types on vendor_types.vendor_type_id = vendors.vendor_type_id
  and not vendor_types._fivetran_deleted
left join currencies on currencies.currency_id = transactions.currency_id
  and not currencies._fivetran_deleted
left join departments on departments.department_id = transaction_lines.department_id
left join classes on classes.class_id = transaction_lines.class_id
join subsidiaries on subsidiaries.subsidiary_id = transaction_lines.subsidiary_id
where (accounting_periods.fiscal_calendar_id is null
  or accounting_periods.fiscal_calendar_id  = (select fiscal_calendar_id from subsidiaries where parent_id is null))
