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
classes as (
    select * from {{ source('netsuite', 'classes') }}
),
locations as (
    select * from {{ source('netsuite', 'locations') }}
),
departments as (
    select * from {{ source('netsuite', 'departments') }}
)

select
  reporting_accounting_periods.accounting_period_id as accounting_period_id,
  reporting_accounting_periods.ending as accounting_period_ending,
  reporting_accounting_periods.full_name as accounting_period_full_name,
  reporting_accounting_periods.name as accounting_period_name,
  lower(reporting_accounting_periods.is_adjustment) = 'yes' as is_accounting_period_adjustment,
  lower(reporting_accounting_periods.closed) = 'yes' as is_accounting_period_closed,
  accounts.name as account_name,
  accounts.type_name as account_type_name,
  accounts.account_id as account_id,
  accounts.accountnumber as account_number,
  {{ dbt_utils.concat(['accounts.accountnumber',"'-'", 'accounts.name']) }} as account_number_and_name,
  classes.full_name as class_full_name,
  coalesce(parent_class.full_name, classes.full_name) as parent_class_full_name,
  locations.full_name as location_full_name,
  departments.full_name as department_full_name,
  -converted_amount_using_transaction_accounting_period as converted_amount,
  transactions_with_converted_amounts.account_category as account_category,
  case when lower(accounts.type_name) = 'income' then 1
    when lower(accounts.type_name) = 'cost of goods sold' then 2
    when lower(accounts.type_name) = 'expense' then 3
    when lower(accounts.type_name) = 'other income' then 4
    when lower(accounts.type_name) = 'other expense' then 5
    else null
    end as income_statement_sort_helper,
  subsidiaries.subsidiary_id,
  subsidiaries.full_name as subsidiary_full_name,
  subsidiaries.name as subsidiary_name
from transactions_with_converted_amounts
join transaction_lines as transaction_lines
  on transaction_lines.transaction_line_id = transactions_with_converted_amounts.transaction_line_id
  and transaction_lines.transaction_id = transactions_with_converted_amounts.transaction_id
left join classes on classes.class_id = transaction_lines.class_id
left join classes as parent_class on parent_class.class_id = classes.parent_id
left join locations on locations.location_id = transaction_lines.location_id
left join departments on departments.department_id = transaction_lines.department_id
join accounts on accounts.account_id = transactions_with_converted_amounts.account_id
join accounting_periods as reporting_accounting_periods on reporting_accounting_periods.accounting_period_id = transactions_with_converted_amounts.reporting_accounting_period_id
join subsidiaries on transactions_with_converted_amounts.subsidiary_id = subsidiaries.subsidiary_id
where reporting_accounting_periods.fiscal_calendar_id  = (select fiscal_calendar_id from subsidiaries where parent_id is null)
  and transactions_with_converted_amounts.transaction_accounting_period_id = transactions_with_converted_amounts.reporting_accounting_period_id
  and transactions_with_converted_amounts.is_income_statement