{{ config(enabled=var('netsuite_data_model', 'netsuite') == 'netsuite') }}

select * 
from {{ var('netsuite_accounting_periods') }}
