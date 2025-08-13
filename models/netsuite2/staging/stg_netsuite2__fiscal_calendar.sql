{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2') and var('netsuite2__fiscal_calendar_enabled', false)) }}

with base as (

    select * 
    from {{ ref('stg_netsuite2__fiscal_calendar_tmp') }}
),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_netsuite2__fiscal_calendar_tmp')),
                staging_columns=get_fiscalcalendar_columns()
            )
        }}
    from base
),

final as (
    
    select 
        id as fiscal_calendar_id,
        externalid as external_id,
        fiscalmonth as fiscal_month,
        isdefault as is_default,
        name,
        date_deleted,
        _fivetran_deleted,
        _fivetran_synced
    from fields
    where not coalesce(_fivetran_deleted, false)
)

select *
from final
