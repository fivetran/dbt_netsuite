{{
    config(
        enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2'),
        materialized='table'
    )
}}

with customers as (
    select *
    from {{ ref('stg_netsuite2__customers') }}
),

customer_subsidiary_relationship as (
    select *
    from {{ ref('stg_netsuite2__customer_subsidiary_relationships') }}
),

vendors as (
    select *
    from {{ ref('stg_netsuite2__vendors') }}
),

vendor_subsidiary_relationship as (
    select *
    from {{ ref('stg_netsuite2__vendor_subsidiary_relationships') }}
),

currencies as (
    select *
    from {{ ref('stg_netsuite2__currencies') }}
),

subsidiaries as (
    select *
    from {{ ref('stg_netsuite2__subsidiaries') }}
),

customer_subsidiary_relationships_enhanced as (
    select
        'customer' as entity_type,
        customer_subsidiary_relationship._fivetran_synced,
        customer_subsidiary_relationship.customer_subsidiary_relationship_id as entity_subsidiary_relationship_id,
        customer_subsidiary_relationship.customer_id as entity_internal_id,
        customers.entity_id as entity_display_id,
        customer_subsidiary_relationship.is_primary_sub,
        customer_subsidiary_relationship.primary_currency_id as entity_currency_id,
        currencies.symbol as entity_currency_symbol,
        customer_subsidiary_relationship.subsidiary_id,
        subsidiaries.name as subsidiary_name,
        customers.alt_name as entity_alt_name
    from customer_subsidiary_relationship
    left join customers
        on customer_subsidiary_relationship.customer_id = customers.customer_id
    left join currencies
        on customer_subsidiary_relationship.primary_currency_id = currencies.currency_id
    left join subsidiaries
        on customer_subsidiary_relationship.subsidiary_id = subsidiaries.subsidiary_id
),

vendor_subsidiary_relationships_enhanced as (
    select
        'vendor' as entity_type,
        vendor_subsidiary_relationship._fivetran_synced,
        vendor_subsidiary_relationship.vendor_subsidiary_relationship_id as entity_subsidiary_relationship_id,
        vendor_subsidiary_relationship.vendor_id as entity_internal_id,
        vendors.entity_id as entity_display_id,
        vendor_subsidiary_relationship.is_primary_sub,
        vendor_subsidiary_relationship.primary_currency_id as entity_currency_id,
        currencies.symbol as entity_currency_symbol,
        vendor_subsidiary_relationship.subsidiary_id,
        subsidiaries.name as subsidiary_name,
        vendors.alt_name as entity_alt_name
    from vendor_subsidiary_relationship
    left join vendors
        on vendor_subsidiary_relationship.vendor_id = vendors.vendor_id
    left join currencies
        on vendor_subsidiary_relationship.primary_currency_id = currencies.currency_id
    left join subsidiaries
        on vendor_subsidiary_relationship.subsidiary_id = subsidiaries.subsidiary_id
),

final as (
    select
        entity_type,
        _fivetran_synced,
        entity_subsidiary_relationship_id,
        entity_internal_id,
        entity_display_id,
        is_primary_sub,
        entity_currency_id,
        entity_currency_symbol,
        subsidiary_id,
        subsidiary_name,
        entity_alt_name
    from customer_subsidiary_relationships_enhanced

    union all

    select
        entity_type,
        _fivetran_synced,
        entity_subsidiary_relationship_id,
        entity_internal_id,
        entity_display_id,
        is_primary_sub,
        entity_currency_id,
        entity_currency_symbol,
        subsidiary_id,
        subsidiary_name,
        entity_alt_name
    from vendor_subsidiary_relationships_enhanced
)

select *
from final
