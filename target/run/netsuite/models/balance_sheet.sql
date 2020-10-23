

  create or replace view `private-internal`.`dbt_kristin`.`balance_sheet`
  OPTIONS()
  as with transactions_with_converted_amounts as (
    select * from `private-internal`.`dbt_kristin`.`transactions_with_converted_amounts`
), 
accounts as (
    select * from `private-internal`.`netsuite`.`accounts`
), 
accounting_periods as (
    select * from `private-internal`.`netsuite`.`accounting_periods`
), 
subsidiaries as (
    select * from `private-internal`.`netsuite`.`subsidiaries`
)

select
  reporting_accounting_periods.accounting_period_id as accounting_period_id,
  reporting_accounting_periods.ending as accounting_period_ending,
  reporting_accounting_periods.full_name as accounting_period_full_name,
  reporting_accounting_periods.name as accounting_period_name,
  lower(reporting_accounting_periods.is_adjustment) = 'yes' as is_accounting_period_adjustment,
  lower(reporting_accounting_periods.closed) = 'yes' as is_accounting_period_closed,
  transactions_with_converted_amounts.account_category as account_category,
  case
    when (lower(accounts.is_balancesheet) = 'f' and reporting_accounting_periods.year_id = transaction_accounting_periods.year_id) then 'Net Income'
    when lower(accounts.is_balancesheet) = 'f' then 'Retained Earnings'
    else accounts.name
    end as account_name,
  case
    when (lower(accounts.is_balancesheet) = 'f' and reporting_accounting_periods.year_id = transaction_accounting_periods.year_id) then 'Net Income'
    when lower(accounts.is_balancesheet) = 'f' then 'Retained Earnings'
    else accounts.type_name
    end as account_type_name,
  case
    when lower(accounts.is_balancesheet) = 'f' then null
    else accounts.account_id
    end as account_id,
  case
    when lower(accounts.is_balancesheet) = 'f' then null
    else accounts.accountnumber
    end as account_number,
  case
    when lower(accounts.is_balancesheet) = 'f' or lower(transactions_with_converted_amounts.account_category) = 'equity' then -converted_amount_using_transaction_accounting_period
    when lower(accounts.is_leftside) = 'f' then -converted_amount_using_reporting_month
    when lower(accounts.is_leftside) = 't' then converted_amount_using_reporting_month
    else 0
    end as converted_amount,
  case
    when lower(accounts.type_name) = 'bank' then 1
    when lower(accounts.type_name) = 'accounts receivable' then 2
    when lower(accounts.type_name) = 'unbilled receivable' then 3
    when lower(accounts.type_name) = 'other current asset' then 4
    when lower(accounts.type_name) = 'fixed asset' then 5
    when lower(accounts.type_name) = 'other asset' then 6
    when lower(accounts.type_name) = 'deferred expense' then 7
    when lower(accounts.type_name) = 'accounts payable' then 8
    when lower(accounts.type_name) = 'credit card' then 9
    when lower(accounts.type_name) = 'other current liability' then 10
    when lower(accounts.type_name) = 'long term liability' then 11
    when lower(accounts.type_name) = 'deferred revenue' then 12
    when lower(accounts.type_name) = 'equity' then 13
    when (lower(accounts.is_balancesheet) = 'f' and reporting_accounting_periods.year_id = transaction_accounting_periods.year_id) then 15
    when lower(accounts.is_balancesheet) = 'f' then 14
    else null
    end as balance_sheet_sort_helper
from transactions_with_converted_amounts
join accounts on accounts.account_id = transactions_with_converted_amounts.account_id
join accounting_periods as reporting_accounting_periods on reporting_accounting_periods.accounting_period_id = transactions_with_converted_amounts.reporting_accounting_period_id
join accounting_periods as transaction_accounting_periods on transaction_accounting_periods.accounting_period_id = transactions_with_converted_amounts.transaction_accounting_period_id
where reporting_accounting_periods.fiscal_calendar_id = (select fiscal_calendar_id from subsidiaries where parent_id is null)
  and transaction_accounting_periods.fiscal_calendar_id = (select fiscal_calendar_id from subsidiaries where parent_id is null)
  and (lower(accounts.is_balancesheet) = 't'
    or transactions_with_converted_amounts.is_income_statement)

union all

select
  reporting_accounting_periods.accounting_period_id as accounting_period_id,
  reporting_accounting_periods.ending as accounting_period_ending,
  reporting_accounting_periods.full_name as accounting_period_full_name,
  reporting_accounting_periods.name as accounting_period_name,
  lower(reporting_accounting_periods.is_adjustment) = 'yes' as is_accounting_period_adjustment,
  lower(reporting_accounting_periods.closed) = 'yes' as is_accounting_period_closed,
  'Equity' as account_category,
  'Cumulative Translation Adjustment' as account_name,
  'Cumulative Translation Adjustment' as account_type_name,
  null as account_id,
  null as account_number,
  case
    when lower(account_category) = 'equity' or is_income_statement then converted_amount_using_transaction_accounting_period
    else converted_amount_using_reporting_month
    end as converted_amount,
  16 as balance_sheet_sort_helper
from transactions_with_converted_amounts
join accounts on accounts.account_id = transactions_with_converted_amounts.account_id
join accounting_periods as reporting_accounting_periods on reporting_accounting_periods.accounting_period_id = transactions_with_converted_amounts.reporting_accounting_period_id
where reporting_accounting_periods.fiscal_calendar_id = (select fiscal_calendar_id from subsidiaries where parent_id is null)
  and (lower(accounts.is_balancesheet) = 't'
    or transactions_with_converted_amounts.is_income_statement);

