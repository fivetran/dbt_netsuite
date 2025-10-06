{%- set using_accounting_period_fiscal_calendars = var('netsuite2__using_accounting_period_fiscal_calendars', true) -%}
{%- set fiscal_calendar_enabled = var('netsuite2__fiscal_calendar_enabled', false) -%}

{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')) }}

with accounting_periods as (
    select *
    from {{ ref('stg_netsuite2__accounting_periods') }}
),

{% if using_accounting_period_fiscal_calendars %}
accounting_period_fiscal_calendars as (
    select *
    from {{ ref('stg_netsuite2__accounting_period_fiscal_cal') }}
),
{% endif %}

{% if fiscal_calendar_enabled %}
fiscal_calendar as (
    select * 
    from {{ ref('stg_netsuite2__fiscal_calendar') }}
),

joined as (
    select
        accounting_periods.*,
        {% if using_accounting_period_fiscal_calendars %}
        accounting_period_fiscal_calendars.fiscal_calendar_id,
        {% else %}
        cast(null as {{ dbt.type_string() }}) as fiscal_calendar_id,
        {% endif %}
        fiscal_calendar.fiscal_month
    from accounting_periods
    {% if using_accounting_period_fiscal_calendars %}
    left join accounting_period_fiscal_calendars
        on accounting_periods.accounting_period_id = accounting_period_fiscal_calendars.accounting_period_id
    {% endif %}
    left join fiscal_calendar
        on {% if using_accounting_period_fiscal_calendars %}fiscal_calendar.fiscal_calendar_id = accounting_period_fiscal_calendars.fiscal_calendar_id{% else %}1=0{% endif %}
),

year_extract as (
    select 
        joined.*,
        {{ get_month_number("fiscal_month") }} as fiscal_start_month,
        extract(year from joined.starting_at) as calendar_year
    from joined
),

adjusted as (
    select 
        *,
        case 
            when extract(month from starting_at) < fiscal_start_month then calendar_year - 1
            else calendar_year
        end as fiscal_year_start
    from year_extract
),

final as (
    select
        *,
        {{ netsuite.date_from_parts('fiscal_year_start', 'fiscal_start_month', '1') }} as fiscal_year_trunc
    from adjusted
)
{% else %}

final as (

    select
        accounting_periods.*,
        {% if using_accounting_period_fiscal_calendars %}
        accounting_period_fiscal_calendars.fiscal_calendar_id,
        {% else %}
        cast(null as {{ dbt.type_string() }}) as fiscal_calendar_id,
        {% endif %}
        cast({{ dbt.date_trunc('year', 'accounting_periods.starting_at') }} as date) as fiscal_year_trunc
    from accounting_periods
    {% if using_accounting_period_fiscal_calendars %}
    left join accounting_period_fiscal_calendars
        on accounting_periods.accounting_period_id = accounting_period_fiscal_calendars.accounting_period_id
    {% endif %}
)
{% endif %}

select *
from final
