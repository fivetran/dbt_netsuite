{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')) }}

with accounting_periods as (

    select *
    from {{ var('netsuite2_accounting_periods') }}
),

accounting_period_fiscal_calendars as (

    select *
    from {{ var('netsuite2_accounting_period_fiscal_calendars') }}
),

accounting_period_hierarchy as (

    select
        accounting_period_id,
        parent_id,
        1 as level,
        name as full_name
    from accounting_periods
    where
        parent_id is null

    union all

    select
        accounting_periods.accounting_period_id,
        accounting_periods.parent_id,
        accounting_period_hierarchy.level + 1,
        accounting_period_hierarchy.full_name || ' : ' || accounting_periods.name as full_name
    from accounting_periods
    join accounting_period_hierarchy
        on accounting_periods.parent_id = accounting_period_hierarchy.accounting_period_id
),

joined as (

    select 
        accounting_periods.*,
        accounting_period_fiscal_calendars.fiscal_calendar_id,
        accounting_period_hierarchy.full_name

    from accounting_periods
    left join accounting_period_fiscal_calendars
        on accounting_periods.accounting_period_id = accounting_period_fiscal_calendars.accounting_period_id
    left join accounting_period_hierarchy
        on accounting_periods.accounting_period_id = accounting_period_hierarchy.accounting_period_id
)

select *
from joined