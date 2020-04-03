with accounting_periods as (
    select * from {{ source('netsuite', 'accounting_periods') }}
),
subsidiaries as (
    select * from {{ source('netsuite', 'subsidiaries') }}
),

period_id_list_to_current_period as ( -- period ids with all future period ids.  this is needed to calculate cumulative totals by correct exchange rates.
  select
    base.accounting_period_id,
    {{ netsuite.array_agg('multiplier.accounting_period_id', 'multiplier.accounting_period_id') }} as accounting_periods_to_include_for
  from accounting_periods as base
  join accounting_periods as multiplier
    on multiplier.starting >= base.starting
    and multiplier.quarter = base.quarter
    and multiplier.year_0 = base.year_0
    and multiplier.fiscal_calendar_id = base.fiscal_calendar_id
    and multiplier.starting <= current_timestamp()
  where lower(base.quarter) = 'no'
    and lower(base.year_0) = 'no'
    and base.fiscal_calendar_id = (select fiscal_calendar_id from subsidiaries where parent_id is null) -- fiscal calendar will align with parent subsidiary's default calendar
  group by 1
)

select * from period_id_list_to_current_period
