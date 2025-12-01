{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with prod as (
    select 
        case when account_id is null then -999999 else account_id end as account_id,
        count(*) as total_balance_sheet_prod_rows
    from {{ target.schema }}_netsuite_prod.netsuite2__balance_sheet
    group by 1
),

dev as (
    select 
        case when account_id is null then -999999 else account_id end as account_id,
        count(*) as total_balance_sheet_dev_rows
    from {{ target.schema }}_netsuite_dev.netsuite2__balance_sheet
    group by 1
),

final as (
    select
        prod.account_id,
        prod.total_balance_sheet_prod_rows,
        dev.total_balance_sheet_dev_rows
    from prod
    full outer join dev
        on dev.account_id = prod.account_id
)

select *
from final
where total_balance_sheet_prod_rows != total_balance_sheet_dev_rows