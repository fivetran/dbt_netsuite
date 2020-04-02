{{ config(
    enabled=(target.type == 'bigquery')
) }}

with period_id_list_to_current_period as (
    select * from {{ref('transactions_with_converted_amounts__all_periods')}}
)
select
  accounting_period_id,
  reporting_accounting_period_id
from period_id_list_to_current_period
cross join unnest(period_id_list_to_current_period.accounting_periods_to_include_for) AS reporting_accounting_period_id
