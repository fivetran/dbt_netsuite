{{
    config(
        enabled=(
            var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')
            and var('netsuite2__using_accounting_period_fiscal_calendars', true)
        )
    )
}}

{{
    netsuite.union_netsuite_connections(
        connection_dictionary=var('netsuite2_sources'),
        single_source_name='netsuite2',
        single_table_name='accounting_period_fiscal_calendars'
    )
}}
