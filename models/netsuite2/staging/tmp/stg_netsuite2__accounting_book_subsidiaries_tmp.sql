{{ config(enabled=(var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2') and var('netsuite2__multibook_accounting_enabled', true))) }}

select * 
from {{ var('netsuite2_accounting_book_subsidiaries') }}
