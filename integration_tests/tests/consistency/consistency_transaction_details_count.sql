{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with prod as (
    select 
        1 as join_key,
        count(*) as total_transaction_detail_prod_rows
    from {{ target.schema }}_netsuite_prod.netsuite2__transaction_details
    group by 1
),

dev as (
    select 
        1 as join_key,
        count(*) as total_transaction_detail_dev_rows
    from {{ target.schema }}_netsuite_dev.netsuite2__transaction_details
    group by 1
),

final as (
    select
        total_transaction_detail_prod_rows,
        total_transaction_detail_dev_rows
    from prod
    full outer join dev
        on dev.join_key = prod.join_key
)

select *
from final
where total_transaction_detail_prod_rows != total_transaction_detail_dev_rows