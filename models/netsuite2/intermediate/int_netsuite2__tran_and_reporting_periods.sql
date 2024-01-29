{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')) }}

with accounting_periods as (
    select * 
    from {{ ref('int_netsuite2__accounting_periods') }}
),

subsidiaries as (
    select * 
    from {{ var('netsuite2_subsidiaries') }}
),

primary_subsidiary_calendar as (
    select 
      fiscal_calendar_id, 
      source_relation 
    from subsidiaries 
    where parent_id is null
),

transaction_and_reporting_periods as ( 
  select
    base.accounting_period_id as accounting_period_id,
    base.source_relation,
    multiplier.accounting_period_id as reporting_accounting_period_id,
    base.source_relation
  from accounting_periods as base

  join accounting_periods as multiplier
    on multiplier.starting_at >= base.starting_at
      and multiplier.is_quarter = base.is_quarter
      and multiplier.is_year = base.is_year -- this was year_0 in netsuite1
      and multiplier.fiscal_calendar_id = base.fiscal_calendar_id
      and multiplier.source_relation = base.source_relation
      and cast(multiplier.starting_at as {{ dbt.type_timestamp() }}) <= {{ current_timestamp() }} 

  join primary_subsidiary_calendar
    on base.fiscal_calendar_id = primary_subsidiary_calendar.fiscal_calendar_id
    and base.source_relation = primary_subsidiary_calendar.source_relation

  where not base.is_quarter
    and not base.is_year
)

select * 
from transaction_and_reporting_periods