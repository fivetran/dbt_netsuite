{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')) }}

with base as (

    select * 
    from {{ ref('stg_netsuite2__accounts_tmp') }}
),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_netsuite2__accounts_tmp')),
                staging_columns=get_netsuite2_accounts_columns()
            )
        }}
    from base
),

final as (
    
    select
        _fivetran_synced,
        id as account_id, 
        externalid as account_external_id,
        parent as parent_id,
        acctnumber as account_number,
        accttype as account_type_id,
        sspecacct as special_account_type_id,
        fullname as name,
        accountsearchdisplaynamecopy as display_name,
        description as account_description,
        deferralacct as deferral_account_id,
        cashflowrate as cash_flow_rate_type,
        generalrate as general_rate_type,
        currency as currency_id,
        class as class_id,
        department as department_id,
        location as location_id,
        includechildren = 'T' as is_including_child_subs,
        isinactive = 'T' as is_inactive,
        issummary = 'T' as is_summary,
        eliminate = 'T' as is_eliminate,
        _fivetran_deleted

        --The below macro adds the fields defined within your accounts_pass_through_columns variable into the staging model
        {{ netsuite.fill_pass_through_columns(var('accounts_pass_through_columns', [])) }}

        
    from fields
)

select * 
from final
