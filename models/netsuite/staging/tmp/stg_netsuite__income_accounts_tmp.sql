{{ config(enabled=var('netsuite_data_model', 'netsuite') == 'netsuite') }}

select * 
from {{ var('netsuite_income_accounts') }}
