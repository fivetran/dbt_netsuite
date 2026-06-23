{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with prod as (
    select {{ dbt_utils.star(from=ref('netsuite2__income_statement'), except=['converted_amount', 'transaction_amount'] + var('netsuite_consistency_exclude_columns', [])) }},
            round(converted_amount, 2) as converted_amount,
            round(transaction_amount, 2) as transaction_amount
    from {{ target.schema }}_netsuite_prod.netsuite2__income_statement
    where date_trunc(accounting_period_ending, month) < date_trunc(current_date(), month) - 1
        {# {% if var('netsuite2__include_deleted_transactions', false) and not var('netsuite2__aggregate_income_statement', false) %}
        and not is_transaction_deleted
        {% endif %} #}
),

dev as (
    select {{ dbt_utils.star(from=ref('netsuite2__income_statement'), except=['converted_amount', 'transaction_amount'] + var('netsuite_consistency_exclude_columns', [])) }},
            round(converted_amount, 2) as converted_amount,
            round(transaction_amount, 2) as transaction_amount
    from {{ target.schema }}_netsuite_dev.netsuite2__income_statement
    where date_trunc(accounting_period_ending, month) < date_trunc(current_date(), month) - 1
        {% if var('netsuite2__include_deleted_transactions', false) and not var('netsuite2__aggregate_income_statement', false) %}
        and not is_transaction_deleted
        {% endif %}
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