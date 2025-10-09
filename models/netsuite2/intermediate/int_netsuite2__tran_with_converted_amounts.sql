{%- set using_exchange_rate = var('netsuite2__using_exchange_rate', true) -%}
{%- set multibook_accounting_enabled = var('netsuite2__multibook_accounting_enabled', false) -%}
{%- set using_to_subsidiary = var('netsuite2__using_to_subsidiary', false) -%}

{{
  config(
    enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')
  )
}}

with transaction_lines_w_accounting_period as (
  select * 
  from {{ ref('int_netsuite2__tran_lines_w_accounting_period') }}
), 

{% if using_exchange_rate %}
accountxperiod_exchange_rate_map as (
  select * 
  from {{ ref('int_netsuite2__acctxperiod_exchange_rate_map') }}
), 
{% endif %}

transaction_and_reporting_periods as (
  select * 
  from {{ ref('int_netsuite2__tran_and_reporting_periods') }}
), 

accounts as (
  select * 
  from {{ ref('int_netsuite2__accounts') }}
),

transactions_in_every_calculation_period_w_exchange_rates as (
  select
    transaction_lines_w_accounting_period.*,
    transaction_and_reporting_periods.reporting_accounting_period_id
    
    {% if using_exchange_rate %}
    , exchange_reporting_period.exchange_rate as exchange_rate_reporting_period
    , exchange_transaction_period.exchange_rate as exchange_rate_transaction_period
    {% endif %}

    {% if using_to_subsidiary and using_exchange_rate %}
    , exchange_reporting_period.to_subsidiary_id
    , exchange_reporting_period.to_subsidiary_name
    , exchange_reporting_period.to_subsidiary_currency_symbol
    {% endif %}

  from transaction_lines_w_accounting_period

  left join transaction_and_reporting_periods
    on transaction_and_reporting_periods.accounting_period_id = transaction_lines_w_accounting_period.transaction_accounting_period_id
      and transaction_and_reporting_periods.source_relation = transaction_lines_w_accounting_period.source_relation 

  {% if using_exchange_rate %}
  left join accountxperiod_exchange_rate_map as exchange_reporting_period
    on exchange_reporting_period.accounting_period_id = transaction_and_reporting_periods.reporting_accounting_period_id
      and exchange_reporting_period.account_id = transaction_lines_w_accounting_period.account_id
      and exchange_reporting_period.from_subsidiary_id = transaction_lines_w_accounting_period.subsidiary_id
      and exchange_reporting_period.source_relation = transaction_lines_w_accounting_period.source_relation

      {% if multibook_accounting_enabled %}
      and exchange_reporting_period.accounting_book_id = transaction_lines_w_accounting_period.accounting_book_id
      and exchange_reporting_period.source_relation = transaction_lines_w_accounting_period.source_relation
      {% endif %}
      
  left join accountxperiod_exchange_rate_map as exchange_transaction_period
    on exchange_transaction_period.accounting_period_id = transaction_and_reporting_periods.accounting_period_id
      and exchange_transaction_period.account_id = transaction_lines_w_accounting_period.account_id
      and exchange_transaction_period.from_subsidiary_id = transaction_lines_w_accounting_period.subsidiary_id
      and exchange_transaction_period.source_relation = transaction_lines_w_accounting_period.source_relation
      
      {% if multibook_accounting_enabled %}
      and exchange_transaction_period.accounting_book_id = transaction_lines_w_accounting_period.accounting_book_id
      {% endif %}

      {% if using_to_subsidiary %}
      and exchange_transaction_period.to_subsidiary_id = exchange_reporting_period.to_subsidiary_id
      {% endif %}
  {% endif %}
), 

transactions_with_converted_amounts as (
  select
    transactions_in_every_calculation_period_w_exchange_rates.*,
    {% if using_exchange_rate %}
    unconverted_amount * exchange_rate_transaction_period as converted_amount_using_transaction_accounting_period,
    unconverted_amount * exchange_rate_reporting_period as converted_amount_using_reporting_month,
    {% else %}
    unconverted_amount as converted_amount_using_transaction_accounting_period,
    unconverted_amount as converted_amount_using_reporting_month,
    {% endif %}
    case
      when lower(accounts.account_type_id) in ('income','othincome','expense','othexpense','cogs') then true
      else false 
        end as is_income_statement,
    case
      when lower(accounts.account_type_id) in ('acctrec', 'bank', 'deferexpense', 'fixedasset', 'othasset', 'othcurrasset', 'unbilledrec') then 'Asset'
      when lower(accounts.account_type_id) in ('cogs', 'expense', 'othexpense') then 'Expense'
      when lower(accounts.account_type_id) in ('income', 'othincome') then 'Income'
      when lower(accounts.account_type_id) in ('acctpay', 'credcard', 'deferrevenue', 'longtermliab', 'othcurrliab') then 'Liability'
      when lower(accounts.account_type_id) in ('equity', 'retained_earnings', 'net_income') then 'Equity'
      when lower(accounts.account_type_id) in ('nonposting', 'stat') then 'Other'
      else null 
        end as account_category
  from transactions_in_every_calculation_period_w_exchange_rates

  left join accounts
    on accounts.account_id = transactions_in_every_calculation_period_w_exchange_rates.account_id
    and accounts.source_relation = transactions_in_every_calculation_period_w_exchange_rates.source_relation 
),

surrogate_key as ( 
  {% set surrogate_key_fields = ['transaction_line_id', 'transaction_id', 'account_id', 'reporting_accounting_period_id'] %} -- add 'source_relation' when combining with union schema
  {% do surrogate_key_fields.append('to_subsidiary_id') if using_to_subsidiary and using_exchange_rate %}
  {% do surrogate_key_fields.append('accounting_book_id') if multibook_accounting_enabled %}

  select 
    *,
    {{ dbt_utils.generate_surrogate_key(surrogate_key_fields) }} as tran_with_converted_amounts_id
  from transactions_with_converted_amounts
)

select * 
from surrogate_key