{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with prod as (
    select *
    from {{ target.schema }}_netsuite_prod.netsuite2__transaction_details
),

dev as (
    select *
    except(is_reversal, reversal_transaction_id, reversal_date, is_reversal_defer, account_display_name,
    is_eliminate, parent_account_id, customer_id, class_id, location_id, vendor_id, vendor_category_id, 
    currency_id, exchange_rate, department_full_name, subsidiary_full_name, subsidiary_currency_symbol, transaction_line_amount)
    from {{ target.schema }}_netsuite_dev.netsuite2__transaction_details
),

prod_not_in_dev as (
    -- rows from prod not found in dev
    select * from prod
    except distinct
    select * from dev
),

dev_not_in_prod as (
    -- rows from dev not found in prod
    select * from dev
    except distinct
    select * from prod
),

final as (
    select
        *,
        'from prod' as source
    from prod_not_in_dev

    union all -- union since we only care if rows are produced

    select
        *,
        'from dev' as source
    from dev_not_in_prod
)

select *
from final