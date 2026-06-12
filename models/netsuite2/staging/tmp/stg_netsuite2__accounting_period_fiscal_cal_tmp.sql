{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')) }}

{{
    fivetran_utils.union_connections(
        connection_dictionary='netsuite2_sources',
        single_source_name='netsuite2',
        single_table_name='accounting_period_fiscal_calendars',
        default_identifier='accountingperiodfiscalcalendars'
    )
}}
