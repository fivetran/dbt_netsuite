{{ config(
    enabled="{{ target.type == 'snowflake' }}"
) }}

select
  accounting_period_id,
  reporting_accounting_period_id.value as reporting_accounting_period_id
from period_id_list_to_current_period,
  lateral flatten (input => accounting_periods_to_include_for) reporting_accounting_period_id