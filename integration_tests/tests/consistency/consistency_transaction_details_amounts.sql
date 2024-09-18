{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with prod as (
    select 
        cast(transaction_date as date) as date_day,
        count(*) as prod_row_count,
        sum(converted_amount) as prod_converted_amount,
        sum(transaction_amount) as prod_transaction_amount
    from {{ target.schema }}_netsuite_prod.netsuite2__transaction_details
    where cast(transaction_date as date) < current_date - 1
    group by 1
),

dev as (
    select 
        cast(transaction_date as date) as date_day,
        count(*) as dev_row_count,
        sum(converted_amount) as dev_converted_amount,
        sum(transaction_amount) as dev_transaction_amount
    from {{ target.schema }}_netsuite_dev.netsuite2__transaction_details
    where cast(transaction_date as date) < current_date - 1
    group by 1
),

final as (
    select
        prod.date_day,
        prod.prod_row_count,
        dev.dev_row_count,
        prod.prod_converted_amount,
        dev.dev_converted_amount,
        prod.prod_transaction_amount,
        dev.dev_transaction_amount
    from prod
    full outer join dev
        on dev.date_day = prod.date_day
)


select *
from final 
where abs(prod_transaction_amount - dev_transaction_amount) >= 0.01
or abs(prod_converted_amount - dev_converted_amount) >= 0.01
or abs(prod_row_count - dev_row_count) >= 0.01