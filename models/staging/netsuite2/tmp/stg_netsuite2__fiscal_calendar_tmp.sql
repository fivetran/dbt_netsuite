{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2') and var('netsuite2__fiscal_calendar_enabled', false)) }}

select * 
from {{ var('netsuite2_fiscal_calendar') }}
