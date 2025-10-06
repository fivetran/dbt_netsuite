{%- set using_customer_subsidiary_relationships = var('netsuite2__using_customer_subsidiary_relationships', true) -%}
{%- set using_vendor_subsidiary_relationships = var('netsuite2__using_vendor_subsidiary_relationships', true) -%}
{%- set using_subsidiaries = var('netsuite2__using_subsidiaries', true) -%}

{{
    config(
        enabled=(
            var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')
            and (using_customer_subsidiary_relationships or using_vendor_subsidiary_relationships)
        ),
        materialized='table'
    )
}}

with currencies as (
    select *
    from {{ ref('stg_netsuite2__currencies') }}
),

{% if using_customer_subsidiary_relationships %}
customers as (
    select *
    from {{ ref('stg_netsuite2__customers') }}
),

customer_subsidiary_relationship as (
    select *
    from {{ ref('stg_netsuite2__customer_subsidiary_relationships') }}
),
{% endif %}

{% if using_vendor_subsidiary_relationships %}
vendors as (
    select *
    from {{ ref('stg_netsuite2__vendors') }}
),

vendor_subsidiary_relationship as (
    select *
    from {{ ref('stg_netsuite2__vendor_subsidiary_relationships') }}
),
{% endif %}

{% if using_subsidiaries %}
subsidiaries as (
    select *
    from {{ ref('stg_netsuite2__subsidiaries') }}
),
{% endif %}

{% if using_customer_subsidiary_relationships %}
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
        {% if using_subsidiaries %}
        subsidiaries.name as subsidiary_name,
        {% else %}
        cast(null as {{ dbt.type_string() }}) as subsidiary_name,
        {% endif %}
        customers.alt_name as entity_alt_name
    from customer_subsidiary_relationship
    left join customers
        on customer_subsidiary_relationship.customer_id = customers.customer_id
    left join currencies
        on customer_subsidiary_relationship.primary_currency_id = currencies.currency_id
    {% if using_subsidiaries %}
    left join subsidiaries
        on customer_subsidiary_relationship.subsidiary_id = subsidiaries.subsidiary_id
    {% endif %}
),
{% endif %}

{% if using_vendor_subsidiary_relationships %}
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
        {% if using_subsidiaries %}
        subsidiaries.name as subsidiary_name,
        {% else %}
        cast(null as {{ dbt.type_string() }}) as subsidiary_name,
        {% endif %}
        vendors.alt_name as entity_alt_name
    from vendor_subsidiary_relationship
    left join vendors
        on vendor_subsidiary_relationship.vendor_id = vendors.vendor_id
    left join currencies
        on vendor_subsidiary_relationship.primary_currency_id = currencies.currency_id
    {% if using_subsidiaries %}
    left join subsidiaries
        on vendor_subsidiary_relationship.subsidiary_id = subsidiaries.subsidiary_id
    {% endif %}
),
{% endif %}

final as (
    {% if using_customer_subsidiary_relationships %}
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
    {% endif %}

    {% if using_customer_subsidiary_relationships and using_vendor_subsidiary_relationships %}
    union all
    {% endif %}

    {% if using_vendor_subsidiary_relationships %}
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
    {% endif %}
)

select *
from final
