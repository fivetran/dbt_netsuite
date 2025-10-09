{{
    config(
        enabled=(
            var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')
            and var('netsuite2__using_entity_address', true)
        )
    )
}}

with base as (

    select * 
    from {{ ref('stg_netsuite2__entity_address_tmp') }}
),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_netsuite2__entity_address_tmp')),
                staging_columns=get_entityaddress_columns()
            )
        }}

        {{ netsuite.apply_source_relation() }}
    from base
),

final as (

    select
        source_relation, 
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
