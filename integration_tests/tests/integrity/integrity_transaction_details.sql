{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

{# This test is to check if the transaction_details has the same number of transactions 
as the source transaction lines table after joining with the transactions source.
This is important when making incremental logic changes. #}

with stg_transaction_count as (
    select count(distinct tl.transaction_id) as stg_count
    from {{ target.schema }}_netsuite_dev.stg_netsuite2__transaction_lines tl
    join {{ target.schema }}_netsuite_dev.stg_netsuite2__transactions tr
        using(transaction_id)
),

transaction_details_count as (
    select count(distinct transaction_id) as final_count
    from {{ target.schema }}_netsuite_dev.netsuite2__transaction_details
),

final as (
    select *
    from stg_transaction_count
    join transaction_details_count
        on stg_count != final_count
)

select *
from final