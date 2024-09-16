{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with prod as (

    select 
        transaction_details_id,
        converted_amount as prod_converted_amount,
        transaction_amount as prod_transaction_amount
    from {{ target.schema }}_netsuite_prod.netsuite2__transaction_details
),

dev as (

    select 
        transaction_details_id,
        converted_amount as dev_converted_amount,
        transaction_amount as dev_transaction_amount
    from {{ target.schema }}_netsuite_dev.netsuite2__transaction_details

),

final as (

    select
        prod.transaction_details_id,
        prod.prod_converted_amount,
        dev.dev_converted_amount,
        prod.prod_transaction_amount,
        dev.dev_transaction_amount
    from prod
    full outer join dev
        on dev.transaction_details_id = prod.transaction_details_id
)

select *
from final 
where abs(prod_transaction_amount - dev_transaction_amount) >= 0.01
or abs(prod_converted_amount - dev_converted_amount) >= 0.01