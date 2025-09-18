{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')) }}

with base as (

    select * 
    from {{ ref('netsuite', 'stg_netsuite2__departments_tmp') }}
),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_netsuite2__departments_tmp')),
                staging_columns=get_netsuite2_departments_columns()
            )
        }}
    from base
),

final as (
    
    select
        _fivetran_synced,
        id as department_id,
        parent as parent_id,
        name,
        fullname as full_name,
        subsidiary as subsidiary_id,
        isinactive = 'T' as is_inactive,
        _fivetran_deleted

        --The below macro adds the fields defined within your departments_pass_through_columns variable into the staging model
        {{ netsuite.fill_pass_through_columns(var('departments_pass_through_columns', [])) }}

    from fields
)

select * 
from final
