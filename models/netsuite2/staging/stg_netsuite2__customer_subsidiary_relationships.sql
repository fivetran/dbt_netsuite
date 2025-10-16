{{
    config(
        enabled=(
            var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')
            and var('netsuite2__using_customer_subsidiary_relationships', true)
        )
    )
}}

with base as (

    select *
    from {{ ref('stg_netsuite2__customer_subsidiary_relationships_tmp') }}
),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_netsuite2__customer_subsidiary_relationships_tmp')),
                staging_columns=get_netsuite2_customer_subsidiary_relationships_columns()
            )
        }}

        {{ netsuite.apply_source_relation() }}
        from base
),

final as (

    select
        source_relation,
        _fivetran_synced,
        id as customer_subsidiary_relationship_id,
        entity as customer_id,
        isprimarysub as is_primary_sub,
        primarycurrency as primary_currency_id,
        subsidiary as subsidiary_id
    from fields
    where not coalesce(_fivetran_deleted, false)
)

select *
from final

