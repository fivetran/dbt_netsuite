{{ config(enabled=var('netsuite_data_model', 'netsuite') == 'netsuite') }}

with transaction_lines_w_accounting_period as (
    select * 
    from {{ ref('int_netsuite__transaction_lines_w_accounting_period') }}
), 

accountxperiod_exchange_rate_map as (
    select * 
    from {{ ref('int_netsuite__accountxperiod_exchange_rate_map') }}
), 

transaction_and_reporting_periods as (
    select * 
    from {{ ref('int_netsuite__transaction_and_reporting_periods') }}
), 

accounts as (
    select * 
    from {{ var('netsuite_accounts') }}
),

transactions_in_every_calculation_period_w_exchange_rates as (
  select
    transaction_lines_w_accounting_period.*,
    reporting_accounting_period_id,
    exchange_reporting_period.exchange_rate as exchange_rate_reporting_period,
    exchange_transaction_period.exchange_rate as exchange_rate_transaction_period
  from transaction_lines_w_accounting_period

  join transaction_and_reporting_periods 
    on transaction_and_reporting_periods.accounting_period_id = transaction_lines_w_accounting_period.transaction_accounting_period_id 

  join accountxperiod_exchange_rate_map as exchange_reporting_period
    on exchange_reporting_period.accounting_period_id = transaction_and_reporting_periods.reporting_accounting_period_id
      and exchange_reporting_period.account_id = transaction_lines_w_accounting_period.account_id
      and exchange_reporting_period.from_subsidiary_id = transaction_lines_w_accounting_period.subsidiary_id
      
  join accountxperiod_exchange_rate_map as exchange_transaction_period
    on exchange_transaction_period.accounting_period_id = transaction_and_reporting_periods.accounting_period_id
      and exchange_transaction_period.account_id = transaction_lines_w_accounting_period.account_id
      and exchange_transaction_period.from_subsidiary_id = transaction_lines_w_accounting_period.subsidiary_id
), 

transactions_with_converted_amounts as (
  select
    transactions_in_every_calculation_period_w_exchange_rates.*,
    unconverted_amount * exchange_rate_transaction_period as converted_amount_using_transaction_accounting_period,
    unconverted_amount * exchange_rate_reporting_period as converted_amount_using_reporting_month,
    case
      when lower(accounts.type_name) in ('income','other income','expense','other expense','other income','cost of goods sold') then true
      else false 
        end as is_income_statement,
    case
      when lower(accounts.type_name) in ('accounts receivable', 'bank', 'deferred expense', 'fixed asset', 'other asset', 'other current asset', 'unbilled receivable') then 'Asset'
      when lower(accounts.type_name) in ('cost of goods sold', 'expense', 'other expense') then 'Expense'
      when lower(accounts.type_name) in ('income', 'other income') then 'Income'
      when lower(accounts.type_name) in ('accounts payable', 'credit card', 'deferred revenue', 'long term liability', 'other current liability') then 'Liability'
      when lower(accounts.type_name) in ('equity', 'retained earnings', 'net income') then 'Equity'
      else null 
        end as account_category
  from transactions_in_every_calculation_period_w_exchange_rates

  join accounts 
    on accounts.account_id = transactions_in_every_calculation_period_w_exchange_rates.account_id 
)

select * 
from transactions_with_converted_amounts