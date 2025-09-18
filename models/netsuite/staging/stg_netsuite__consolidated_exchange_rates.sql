{{ config(enabled=var('netsuite_data_model', 'netsuite') == 'netsuite') }}

with base as (

    select * 
    from {{ ref('netsuite', 'stg_netsuite__consolidated_exchange_rates_tmp') }}

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
                source_columns=adapter.get_columns_in_relation(ref('stg_netsuite__consolidated_exchange_rates_tmp')),
                staging_columns=get_consolidated_exchange_rates_columns()
            )
        }}
        
    from base
),

final as (
    
    select 
        consolidated_exchange_rate_id,
        accounting_book_id,
        accounting_period_id,
        average_rate,
        current_rate,
        historical_rate,
        from_subsidiary_id,
        to_subsidiary_id,
        _fivetran_deleted

        --The below macro adds the fields defined within your consolidated_exchange_rates_pass_through_columns variable into the staging model
        {{ netsuite.fill_pass_through_columns(var('consolidated_exchange_rates_pass_through_columns', [])) }}

    from fields
)

select * 
from final
where not coalesce(_fivetran_deleted, false)
