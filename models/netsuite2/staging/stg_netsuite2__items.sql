{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')) }}

with base as (

    select * 
    from {{ ref('netsuite', 'stg_netsuite2__items_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_netsuite2__items_tmp')),
                staging_columns=get_netsuite2_items_columns()
            )
        }}
    from base
),

final as (
    
    select
        _fivetran_synced,
        id as item_id,
        fullname as name,
        itemtype as type_name,
        description as sales_description,
        department as department_id,
        class as class_id,
        location as location_id,
        subsidiary as subsidiary_id,
        assetaccount as asset_account_id,
        expenseaccount as expense_account_id,
        gainlossaccount as gain_loss_account_id,
        incomeaccount as income_account_id,
        intercoexpenseaccount as interco_expense_account_id,
        intercoincomeaccount as interco_income_account_id,
        deferralaccount as deferred_expense_account_id,
        deferredrevenueaccount as deferred_revenue_account_id,
        parent as parent_item_id

        --The below macro adds the fields defined within your items_pass_through_columns variable into the staging model
        {{ netsuite.fill_pass_through_columns(var('items_pass_through_columns', [])) }}

    from fields
    where not coalesce(_fivetran_deleted, false)
)

select * 
from final
