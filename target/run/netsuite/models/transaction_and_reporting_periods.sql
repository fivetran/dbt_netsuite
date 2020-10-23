

  create or replace view `private-internal`.`dbt_kristin`.`transaction_and_reporting_periods`
  OPTIONS()
  as with accounting_periods as (
    select * from `private-internal`.`netsuite`.`accounting_periods`
),
subsidiaries as (
    select * from `private-internal`.`netsuite`.`subsidiaries`
),
transaction_and_reporting_periods as ( 

  select
    base.accounting_period_id as accounting_period_id,
    multiplier.accounting_period_id as reporting_accounting_period_id
  from accounting_periods as base
  join accounting_periods as multiplier
    on multiplier.starting >= base.starting
    and multiplier.quarter = base.quarter
    and multiplier.year_0 = base.year_0
    and multiplier.fiscal_calendar_id = base.fiscal_calendar_id
    and multiplier.starting <= CURRENT_TIMESTAMP()
  where lower(base.quarter) = 'no'
    and lower(base.year_0) = 'no'
    and base.fiscal_calendar_id = (select fiscal_calendar_id from subsidiaries where parent_id is null) -- fiscal calendar will align with parent subsidiary's default calendar
)
select * from transaction_and_reporting_periods;

