{{ config(enabled=(var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2') and var('netsuite2__using_exchange_rate', true))) }}

select *
from {{ var('netsuite2_consolidated_exchange_rates') }}