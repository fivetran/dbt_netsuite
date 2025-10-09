{%- set using_subsidiaries = var('netsuite2__using_subsidiaries', true) -%}

{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')) }}

with accounting_periods as (
    select * 
    from {{ ref('int_netsuite2__accounting_periods') }}
),

{% if using_subsidiaries %}
subsidiaries as (
    select *
    from {{ ref('stg_netsuite2__subsidiaries') }}
),
{% endif %}

transaction_and_reporting_periods as ( 
  select
    base.accounting_period_id as source_relation,
    base.accounting_period_id as accounting_period_id,
    multiplier.accounting_period_id as reporting_accounting_period_id
  from accounting_periods as base

  join accounting_periods as multiplier
    on multiplier.starting_at >= base.starting_at
      and multiplier.is_quarter = base.is_quarter
      and multiplier.is_year = base.is_year -- this was year_0 in netsuite1
      and multiplier.fiscal_calendar_id = base.fiscal_calendar_id
      and cast(multiplier.starting_at as {{ dbt.type_timestamp() }}) <= {{ current_timestamp() }}
      and multiplier.source_relation = base.source_relation 

  where not base.is_quarter
    and not base.is_year
    {% if using_subsidiaries %}
    and base.fiscal_calendar_id = (select fiscal_calendar_id from subsidiaries where parent_id is null) -- fiscal calendar will align with parent subsidiary's default calendar
    {% endif %}
)

select * 
from transaction_and_reporting_periods