{{
    config(
        enabled=(
            var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')
            and var('netsuite2__multibook_accounting_enabled', true)
        )
    )
}}

{{
    netsuite.netsuite_union_connections(
        connection_dictionary=var('netsuite2_sources'),
        single_source_name='netsuite2',
        single_table_name='accounting_book'
    )
}}
