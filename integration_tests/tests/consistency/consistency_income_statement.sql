{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with prod as (
    select *
    from {{ target.schema }}_netsuite_prod.netsuite2__income_statement
),

dev as (
    select *
    except(account_display_name, class_id, location_id, department_id)--this test has been modified for the purposes of validating this PR. Remove this line before merging.
    from {{ target.schema }}_netsuite_dev.netsuite2__income_statement
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