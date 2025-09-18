{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')) }}

with base as (

    select * 
    from {{ ref('stg_netsuite2__transactions_tmp') }}
),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_netsuite2__transactions_tmp')),
                staging_columns=get_netsuite2_transactions_columns()
            )
        }}
    from base
),

final as (
    
    select
        _fivetran_synced,
        cast(_fivetran_synced as date) as _fivetran_synced_date,
        id as transaction_id,
        transactionnumber as transaction_number,
        type as transaction_type,
        memo,
        cast(trandate as date) as transaction_date,
        status,
        createddate as created_at,
        cast(duedate as date) as due_date_at,
        cast(closedate as date) as closed_at,
        currency as currency_id,
        entity as entity_id,
        postingperiod as accounting_period_id,
        posting = 'T' as is_posting,
        nexus as nexus_id,
        taxregoverride = 'T' as is_nexus_override,
        taxdetailsoverride = 'T' as is_tax_details_override,
        cast(taxpointdate as date) as tax_point_date,
        taxpointdateoverride = 'T' as tax_point_date_override,
        intercoadj = 'T' as is_intercompany_adjustment,
        isreversal = 'T' as is_reversal,
        reversal as reversal_transaction_id,
        cast(reversaldate as date) as reversal_date,
        reversaldefer = 'T' as is_reversal_defer

        --The below macro adds the fields defined within your transactions_pass_through_columns variable into the staging model
        {{ netsuite.fill_pass_through_columns(var('transactions_pass_through_columns', [])) }}

    from fields
    where not coalesce(_fivetran_deleted, false)
)

select * 
from final

