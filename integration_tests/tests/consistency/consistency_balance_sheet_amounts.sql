{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with prod as (
    select 
        case when account_id is null then -999999 else account_id end as account_id,
        date_trunc(accounting_period_ending, month) as prod_account_period_month,
        count(*) as prod_row_count,
        sum(converted_amount) as prod_converted_amount 
    from {{ target.schema }}_netsuite_prod.netsuite2__balance_sheet
    where date_trunc(accounting_period_ending, month) < date_trunc(current_date(), month) - 1 
    group by 1, 2
),

dev as (
    select 
        case when account_id is null then -999999 else account_id end as account_id,
        date_trunc(accounting_period_ending, month) as dev_account_period_month,
        count(*) as dev_row_count,
        sum(converted_amount) as dev_converted_amount 
    from {{ target.schema }}_netsuite_dev.netsuite2__balance_sheet
    where date_trunc(accounting_period_ending, month) < date_trunc(current_date(), month) - 1 
    group by 1, 2
),

final as (
    select
        prod.account_id,
        prod.prod_account_period_month,
        dev.dev_account_period_month,
        prod.prod_row_count,
        dev.dev_row_count,
        prod.prod_converted_amount,
        dev.dev_converted_amount
    from prod
    full outer join dev
        on dev.account_id = prod.account_id
        and dev.dev_account_period_month = prod.prod_account_period_month
)


select *
from final 
where abs(prod_converted_amount - dev_converted_amount) >= 0.01
or abs(prod_row_count - dev_row_count) >= 0.01