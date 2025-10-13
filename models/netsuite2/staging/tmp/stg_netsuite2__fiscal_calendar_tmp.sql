{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')) }}

{{
    netsuite.netsuite_union_connections(
        connection_dictionary=var('netsuite2_sources'),
        single_source_name='netsuite2',
        single_table_name='fiscal_calendar',
        default_identifier='fiscalcalendar'
    )
}}