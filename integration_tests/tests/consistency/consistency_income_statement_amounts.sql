{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with prod as (
    select 
        accounting_period_id, 
        sum(converted_amount) as prod_converted_amount 
    from {{ target.schema }}_netsuite_prod.netsuite2__income_statement
    where cast(accounting_period_ending as date) < current_date - 1
    group by 1
),

dev as (
    select 
        accounting_period_id,
        sum(converted_amount) as dev_converted_amount 
    from {{ target.schema }}_netsuite_dev.netsuite2__income_statement
    where cast(accounting_period_ending as date) < current_date - 1
    group by 1
),

final as (
    select
        prod.accounting_period_id, 
        prod.prod_converted_amount,
        dev.dev_converted_amount
    from prod
    full outer join dev
        on dev.accounting_period_id = prod.accounting_period_id
)


select *
from final  
where abs(prod_converted_amount - dev_converted_amount) >= 0.01 