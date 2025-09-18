{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')) }}

with base as (

    select * 
    from {{ ref('netsuite', 'stg_netsuite2__locations_tmp') }}
),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_netsuite2__locations_tmp')),
                staging_columns=get_netsuite2_locations_columns()
            )
        }}
    from base
),

final as (
    
    select
        _fivetran_synced,
        id as location_id,
        name,
        fullname as full_name,
        mainaddress as main_address_id,
        parent as parent_id,
        subsidiary as subsidiary_id

        --The below macro adds the fields defined within your locations_pass_through_columns variable into the staging model
        {{ netsuite.fill_pass_through_columns(var('locations_pass_through_columns', [])) }}

    from fields
    where not coalesce(_fivetran_deleted, false)
)

select * 
from final
