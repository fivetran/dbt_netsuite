with accounts as (

    select *
    from {{ var('accounts' )}}
),

account_types as (

    select *
    from {{ var('account_types')}}
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