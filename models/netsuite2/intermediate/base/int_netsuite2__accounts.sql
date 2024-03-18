{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')) }}

with accounts as (

    select *
    from {{ var('netsuite2_accounts') }}
),

account_types as (

    select *
    from {{ var('netsuite2_account_types') }}
),

account_hierarchy as (

    select
        account_id,
        parent_id,
        1 as level,
        account_number || ' - ' || display_name as display_full_name
    
    from accounts
    where 
        parent_id is null

    union all

    select
        accounts.account_id,
        accounts.parent_id,
        account_hierarchy.level + 1,
        account_hierarchy.display_full_name || ' : ' || accounts.account_number || ' - ' || accounts.display_name as display_full_name
    
    from accounts
    join account_hierarchy
        on accounts.parent_id = account_hierarchy.account_id 
),

joined as (

    select 
        accounts.*,
        account_hierarchy.display_full_name,
        account_types.type_name,
        account_types.is_balancesheet,
        account_types.is_leftside

    from accounts
    left join account_types
        on accounts.account_type_id = account_types.account_type_id
    left join account_hierarchy
        on accounts.account_id = account_hierarchy.account_id
)

select *
from joined