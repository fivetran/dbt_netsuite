{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')) }}

with base as (

    select * 
    from {{ ref('stg_netsuite2__vendors_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_netsuite2__vendors_tmp')),
                staging_columns=get_netsuite2_vendors_columns()
            )
        }}
    from base
),

final as (
    
    select
        _fivetran_synced,
        id as vendor_id,
        entityid as entity_id,
        altname as alt_name,
        companyname as company_name,
        datecreated as create_date_at,
        category as vendor_category_id

        --The below macro adds the fields defined within your vendors_pass_through_columns variable into the staging model
        {{ netsuite.fill_pass_through_columns(var('vendors_pass_through_columns', [])) }}

    from fields
    where not coalesce(_fivetran_deleted, false)
)

select * 
from final