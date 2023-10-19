{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2') and var('netsuite2__using_exchange_rate', true)) }}

with accounts as (
    select * 
    from {{ ref('int_netsuite2__accounts') }}
), 

{% if var('netsuite2__multibook_accounting_enabled', true) %}
accounting_books as (
    select * 
    from {{ var('netsuite2_accounting_books') }}
),
{% endif %}

subsidiaries as (
    select * 
    from {{ var('netsuite2_subsidiaries') }}
),

consolidated_exchange_rates as (
    select *
    from {{ var('netsuite2_consolidated_exchange_rates') }}
),

currencies as (
    select *
    from {{ var('netsuite2_currencies') }}
),

period_exchange_rate_map as ( -- exchange rates used, by accounting period, to convert to parent subsidiary
  select
    consolidated_exchange_rates.accounting_period_id,
    consolidated_exchange_rates.accounting_book_id,
    consolidated_exchange_rates.average_rate,
    consolidated_exchange_rates.current_rate,
    consolidated_exchange_rates.historical_rate,
    consolidated_exchange_rates.from_subsidiary_id,
    consolidated_exchange_rates.to_subsidiary_id,
    to_subsidiaries.name as to_subsidiary_name,
    currencies.symbol as to_subsidiary_currency_symbol
  from consolidated_exchange_rates
  
  left join subsidiaries to_subsidiaries
    on consolidated_exchange_rates.to_subsidiary_id = to_subsidiaries.subsidiary_id

  left join currencies
    on currencies.currency_id = to_subsidiaries.currency

), 

accountxperiod_exchange_rate_map as ( -- account table with exchange rate details by accounting period
  select
    period_exchange_rate_map.accounting_period_id,
    period_exchange_rate_map.accounting_book_id,
    period_exchange_rate_map.from_subsidiary_id,
    period_exchange_rate_map.to_subsidiary_id,
    period_exchange_rate_map.to_subsidiary_name,
    period_exchange_rate_map.to_subsidiary_currency_symbol,
    accounts.account_id,
    case 
      when lower(accounts.general_rate_type) = 'historical' then period_exchange_rate_map.historical_rate
      when lower(accounts.general_rate_type) = 'current' then period_exchange_rate_map.current_rate
      when lower(accounts.general_rate_type) = 'average' then period_exchange_rate_map.average_rate
      else null
        end as exchange_rate
  from accounts
  
  cross join period_exchange_rate_map
)

select *
from accountxperiod_exchange_rate_map