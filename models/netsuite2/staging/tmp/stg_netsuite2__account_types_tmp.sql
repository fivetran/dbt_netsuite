{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')) }}

{{
    netsuite.union_netsuite_connections(
        connection_dictionary=var('netsuite_sources'), 
        single_source_name='netsuite', 
        single_table_name='account_type'
    )
}}