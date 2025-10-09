{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')) }}

with base as (

    select * 
    from {{ ref('stg_netsuite2__transaction_lines_tmp') }}
),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_netsuite2__transaction_lines_tmp')),
                staging_columns=get_netsuite2_transaction_lines_columns()
            )
        }}

        {{ netsuite.apply_source_relation() }}
    from base
),

final as (

    select
        source_relation,
        _fivetran_synced,
        id as transaction_line_id,
        transaction as transaction_id,
        linesequencenumber as transaction_line_number,
        memo,
        entity as entity_id,
        item as item_id,
        class as class_id,
        location as location_id,
        subsidiary as subsidiary_id,
        department as department_id,
        isclosed = 'T' as is_closed,
        isbillable = 'T' as is_billable,
        iscogs = 'T' as is_cogs,
        cleared = 'T' as is_cleared,
        commitmentfirm = 'T' as is_commitment_firm,
        mainline = 'T' as is_main_line,
        taxline = 'T' as is_tax_line,
        eliminate = 'T' as is_eliminate,
        netamount

        --The below macro adds the fields defined within your transaction_lines_pass_through_columns variable into the staging model
        {{ netsuite.fill_pass_through_columns(var('transaction_lines_pass_through_columns', [])) }}

    from fields
)

select * 
from final
