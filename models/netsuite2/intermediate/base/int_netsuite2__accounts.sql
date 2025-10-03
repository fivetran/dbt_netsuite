{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')) }}

with accounts as (

    select *
    from {{ ref('stg_netsuite2__accounts') }}
),

account_types as (

    select *
    from {{ ref('stg_netsuite2__account_types') }}
),

joined as (

    select 
        accounts.*,
        account_types.type_name,
        account_types.is_balancesheet,
        account_types.is_leftside

    from accounts
    left join account_types
        on accounts.account_type_id = account_types.account_type_id
)

select *
from joined

