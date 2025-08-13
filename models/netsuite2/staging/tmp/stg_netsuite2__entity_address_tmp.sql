{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')) }}

select * 
from {{ var('netsuite2_entity_address') }}
