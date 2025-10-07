{{ config(enabled=(var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2') and var('netsuite2__multibook_accounting_enabled', true))) }}

with base as (

    select * 
    from {{ ref('stg_netsuite2__accounting_book_subsidiaries_tmp') }}
),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_netsuite2__accounting_book_subsidiaries_tmp')),
                staging_columns=get_accountingbooksubsidiaries_columns()
            )
        }}
    from base
),

final as (
    
    select 
        _fivetran_id,
        _fivetran_synced,
        accountingbook as accounting_book_id,
        status,
        subsidiary as subsidiary_id

    from fields
    where not coalesce(_fivetran_deleted, false)
)

select *
from final
