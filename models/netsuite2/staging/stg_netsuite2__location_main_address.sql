{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')) }}

with base as (

    select * 
    from {{ ref('stg_netsuite2__location_main_address_tmp') }}
),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_netsuite2__location_main_address_tmp')),
                staging_columns=get_locationmainaddress_columns()
            )
        }}
    from base
),

final as (
    
    select 
        _fivetran_synced,
        addr1,
        addr2,
        addr3,
        addressee,
        addrtext as full_address,
        city,
        country,
        coalesce(state, dropdownstate) as state,
        nkey,
        zip as zipcode
    from fields
    where not coalesce(_fivetran_deleted, false)
)

select *
from final
