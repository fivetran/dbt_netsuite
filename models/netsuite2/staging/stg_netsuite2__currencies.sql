{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')) }}

with base as (

    select * 
    from {{ ref('stg_netsuite2__currencies_tmp') }}
),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_netsuite2__currencies_tmp')),
                staging_columns=get_netsuite2_currencies_columns()
            )
        }}

        {{ netsuite.apply_source_relation() }}
    from base
),

final as (

    select
        source_relation,
        _fivetran_synced,
        id as currency_id,
        name,
        symbol
    from fields
    where not coalesce(_fivetran_deleted, false)
)

select * 
from final

