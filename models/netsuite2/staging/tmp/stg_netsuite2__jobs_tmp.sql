{{ config(enabled=(var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2') and var('netsuite2__using_jobs', true))) }}

select * 
from {{ var('netsuite2_jobs') }}
