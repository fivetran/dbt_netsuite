{{ config(enabled=var('netsuite_data_model', 'netsuite') == 'netsuite') }}

with base as (

    select * 
    from {{ ref('netsuite', 'stg_netsuite__classes_tmp') }}

),

fields as (

    select
        /*
        The below macro is used to generate the correct SQL for package staging models. It takes a list of columns 
        that are expected/needed (staging_columns from dbt_salesforce_source/models/tmp/) and compares it with columns 
        in the source (source_columns from dbt_salesforce_source/macros/).
        For more information refer to our dbt_fivetran_utils documentation (https://github.com/fivetran/dbt_fivetran_utils.git).
        */

        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_netsuite__classes_tmp')),
                staging_columns=get_classes_columns()
            )
        }}
        
    from base
),

final as (
    
    select 
        class_id,
        full_name,
        _fivetran_deleted

        --The below macro adds the fields defined within your classes_pass_through_columns variable into the staging model
        {{ netsuite.fill_pass_through_columns(var('classes_pass_through_columns', [])) }}

    from fields
)

select * 
from final
