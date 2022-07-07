{{ config(enabled=var('data_model', 'netsuite') == 'netsuite2') }}

with accounting_periods as (
    select * 
    from {{ ref('int_netsuite__accounting_periods') }}
),

subsidiaries as (
    select * 
    from {{ var('subsidiaries') }}
),

transaction_and_reporting_periods as ( 
  select
    base.accounting_period_id as accounting_period_id,
    multiplier.accounting_period_id as reporting_accounting_period_id
  from accounting_periods as base

  join accounting_periods as multiplier
    on multiplier.starting_at >= base.starting_at
      and multiplier.is_quarter = base.is_quarter
      and multiplier.is_year = base.is_year -- this was year_0 in netsuite1
      and multiplier.fiscal_calendar_id = base.fiscal_calendar_id
      and multiplier.starting_at <= {{ current_timestamp() }} 

  where not base.is_quarter
    and not base.is_year
    and base.fiscal_calendar_id = (select fiscal_calendar_id from subsidiaries where parent_id is null) -- fiscal calendar will align with parent subsidiary's default calendar
)

select * 
from transaction_and_reporting_periods