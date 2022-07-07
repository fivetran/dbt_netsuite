{{ config(enabled=var('data_model', 'netsuite') == 'netsuite2') }}

with accounting_periods as (

    select *
    from {{ var('accounting_periods') }}
),

accounting_period_fiscal_calendars as (

    select *
    from {{ var('accounting_period_fiscal_calendars') }}
),

joined as (

    select 
        accounting_periods.*,
        accounting_period_fiscal_calendars.fiscal_calendar_id

    from accounting_periods
    left join accounting_period_fiscal_calendars
        on accounting_periods.accounting_period_id = accounting_period_fiscal_calendars.accounting_period_id
)

select *
from joined