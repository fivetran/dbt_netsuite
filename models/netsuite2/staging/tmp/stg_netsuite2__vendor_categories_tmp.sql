{{
    config(
        enabled=(
            var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')
            and var('netsuite2__using_vendor_categories', true)
        )
    )
}}

{{
    fivetran_utils.union_connections(
        connection_dictionary='netsuite2_sources',
        single_source_name='netsuite2',
        single_table_name='vendor_category',
        default_identifier='vendorcategory'
    )
}}
