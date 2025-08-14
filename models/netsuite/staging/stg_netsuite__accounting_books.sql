{{ config(enabled=var('netsuite_data_model', 'netsuite') == 'netsuite') }}

with base as (

    select * 
    from {{ ref('stg_netsuite__accounting_books_tmp') }}

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
                source_columns=adapter.get_columns_in_relation(ref('stg_netsuite__accounting_books_tmp')),
                staging_columns=get_accounting_books_columns()
            )
        }}
        
    from base
),

final as (
    
    select 
        accounting_book_id,
        is_primary,
        _fivetran_deleted

    from fields
)

select * 
from final
where not coalesce(_fivetran_deleted, false)
