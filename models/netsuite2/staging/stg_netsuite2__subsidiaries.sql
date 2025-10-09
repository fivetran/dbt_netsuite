{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')) }}

with base as (

    select * 
    from {{ ref('stg_netsuite2__subsidiaries_tmp') }}
),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_netsuite2__subsidiaries_tmp')),
                staging_columns=get_netsuite2_subsidiaries_columns()
            )
        }}

        {{ netsuite.apply_source_relation() }}
    from base
),

final as (

    select
        source_relation,
        _fivetran_synced,
        id as subsidiary_id,
        name,
        fullname as full_name,
        email as email_address,
        mainaddress as main_address_id,
        country,
        state,
        fiscalcalendar as fiscal_calendar_id,
        parent as parent_id,
        iselimination = 'T' as is_elimination,
        currency as currency_id

        --The below macro adds the fields defined within your subsidiaries_pass_through_columns variable into the staging model
        {{ netsuite.fill_pass_through_columns(var('subsidiaries_pass_through_columns', [])) }}

    from fields
    where not coalesce(_fivetran_deleted, false)
)

select * 
from final
