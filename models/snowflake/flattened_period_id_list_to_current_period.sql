{{ config(
    enabled=(target.type == 'snowflake')
) }}

with period_id_list_to_current_period as (
    select * from {{ref('transactions_with_converted_amounts__all_periods')}}
)
select
  accounting_period_id,
  reporting_accounting_period_id.value as reporting_accounting_period_id
from period_id_list_to_current_period,
  lateral flatten (input => accounting_periods_to_include_for) reporting_accounting_period_id