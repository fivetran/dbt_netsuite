{{ config(enabled=var('netsuite_data_model', 'netsuite') == 'netsuite') }}

with base as (

    select * 
    from {{ ref('stg_netsuite__transaction_lines_tmp') }}

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
                source_columns=adapter.get_columns_in_relation(ref('stg_netsuite__transaction_lines_tmp')),
                staging_columns=get_transaction_lines_columns()
            )
        }}
        
    from base
),

final as (
    
    select 
        transaction_id,
        transaction_line_id,
        subsidiary_id,
        account_id,
        company_id,
        item_id,
        amount,
        non_posting_line,
        class_id,
        location_id,
        department_id,
        memo

        --The below macro adds the fields defined within your transaction_lines_pass_through_columns variable into the staging model
        {{ netsuite.fill_pass_through_columns(var('transaction_lines_pass_through_columns', [])) }}

    from fields
)

select * 
from final
