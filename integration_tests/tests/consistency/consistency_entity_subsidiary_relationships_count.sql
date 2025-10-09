{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with prod as (
    select
        1 as join_key,
        count(*) as total_entity_subsidiary_relationships_prod_rows
    from {{ target.schema }}_netsuite_prod.netsuite2__entity_subsidiary_relationships
    group by 1
),

dev as (
    select
        1 as join_key,
        count(*) as total_entity_subsidiary_relationships_dev_rows
    from {{ target.schema }}_netsuite_dev.netsuite2__entity_subsidiary_relationships
    group by 1
),

final as (
    select
        total_entity_subsidiary_relationships_prod_rows,
        total_entity_subsidiary_relationships_dev_rows
    from prod
    full outer join dev
        on dev.join_key = prod.join_key
)

select *
from final
where total_entity_subsidiary_relationships_prod_rows != total_entity_subsidiary_relationships_dev_rows