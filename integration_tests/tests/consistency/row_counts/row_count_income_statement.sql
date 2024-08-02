{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

-- this test is to make sure the rows counts are the same between versions
with prod as (
    select 
        account_id,
        accounting_period_id,
        subsidiary_id,
        count(*) as prod_rows,
        sum(converted_amount) as prod_total_sum
    from {{ target.schema }}_netsuite_prod.netsuite2__income_statement
    where date(accounting_period_ending) < date({{ dbt.current_timestamp() }})
    group by 1,2,3
),

dev as (
    select 
        account_id,
        accounting_period_id,
        subsidiary_id,
        count(*) as dev_rows,
        sum(converted_amount) as dev_total_sum
    from {{ target.schema }}_netsuite_dev.netsuite2__income_statement
    where date(accounting_period_ending) < date({{ dbt.current_timestamp() }})
    group by 1,2,3
),

final as (
    select 
        prod.account_id,
        prod.accounting_period_id,
        prod.subsidiary_id,
        round(prod.prod_rows,2) as prod_rows,
        round(dev.dev_rows,2) as dev_rows,
        round(prod.prod_total_sum,2) as prod_total_sum,
        round(dev.dev_total_sum,2) as dev_total_sum
    from prod
    full outer join dev
        on dev.account_id = prod.account_id
        and dev.subsidiary_id = prod.subsidiary_id
        and dev.accounting_period_id = prod.accounting_period_id
)

select *
from final
where prod_rows != dev_rows
    or prod_total_sum != dev_total_sum

