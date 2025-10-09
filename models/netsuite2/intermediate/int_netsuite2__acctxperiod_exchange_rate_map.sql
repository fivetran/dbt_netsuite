{%- set multibook_accounting_enabled = var('netsuite2__multibook_accounting_enabled', false) -%}
{%- set using_to_subsidiary = var('netsuite2__using_to_subsidiary', false) -%}

{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2') and var('netsuite2__using_exchange_rate', true)) }}

with accounts as (
    select * 
    from {{ ref('int_netsuite2__accounts') }}
), 

{% if multibook_accounting_enabled %}
accounting_books as (
    select * 
    from {{ ref('stg_netsuite2__accounting_books') }}
),
{% endif %}

subsidiaries as (
    select * 
    from {{ ref('stg_netsuite2__subsidiaries') }}
),

consolidated_exchange_rates as (
    select *
    from {{ ref('stg_netsuite2__consolidated_exchange_rates') }}
),

currencies as (
    select *
    from {{ ref('stg_netsuite2__currencies') }}
),

{% if not using_to_subsidiary %}
primary_subsidiaries as (
  select 
    subsidiary_id,
    source_relation
  from subsidiaries where parent_id is null
),
{% endif %}

period_exchange_rate_map as ( -- exchange rates used, by accounting period, to convert to parent subsidiary
  select
    consolidated_exchange_rates.source_relation,
    consolidated_exchange_rates.accounting_period_id,

    {% if multibook_accounting_enabled %}
    consolidated_exchange_rates.accounting_book_id,
    {% endif %}

    consolidated_exchange_rates.source_relation,
    consolidated_exchange_rates.average_rate,
    consolidated_exchange_rates.current_rate,
    consolidated_exchange_rates.historical_rate,
    consolidated_exchange_rates.from_subsidiary_id,
    consolidated_exchange_rates.to_subsidiary_id,
    to_subsidiaries.name as to_subsidiary_name,
    currencies.symbol as to_subsidiary_currency_symbol
  from consolidated_exchange_rates
  
  left join subsidiaries as to_subsidiaries
    on consolidated_exchange_rates.to_subsidiary_id = to_subsidiaries.subsidiary_id
    and consolidated_exchange_rates.source_relation = to_subsidiaries.source_relation

  left join currencies
    on currencies.currency_id = to_subsidiaries.currency_id
    and currencies.source_relation = to_subsidiaries.source_relation

  {% if not using_to_subsidiary %}
  join primary_subsidiaries
    on consolidated_exchange_rates.to_subsidiary_id = primary_subsidiaries.subsidiary_id
    and consolidated_exchange_rates.source_relation = primary_subsidiaries.source_relation
  {% endif %}
), 

accountxperiod_exchange_rate_map as ( -- account table with exchange rate details by accounting period
  select
    period_exchange_rate_map.source_relation,
    period_exchange_rate_map.accounting_period_id,

    {% if multibook_accounting_enabled %}
    period_exchange_rate_map.accounting_book_id,
    {% endif %}
    
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
        end as exchange_rate,
    accounts.source_relation
  from accounts
  
  join period_exchange_rate_map
    on accounts.source_relation = period_exchange_rate_map.source_relation
)

select *
from accountxperiod_exchange_rate_map