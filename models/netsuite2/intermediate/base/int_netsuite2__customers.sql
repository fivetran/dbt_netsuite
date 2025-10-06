{%- set using_entity_address = var('netsuite2__using_entity_address', true) -%}

{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')) }}

with customers as (

    select *
    from {{ ref('stg_netsuite2__customers') }}
),

{% if using_entity_address %}
entity_address as (

    select *
    from {{ ref('stg_netsuite2__entity_address') }}
),
{% endif %}

joined as (

    select
        customers.*
        {% if using_entity_address %},
        entity_address.city,
        entity_address.state,
        entity_address.zipcode,
        entity_address.country
        {% else %},
        cast(null as {{ dbt.type_string() }}) as city,
        cast(null as {{ dbt.type_string() }}) as state,
        cast(null as {{ dbt.type_string() }}) as zipcode,
        cast(null as {{ dbt.type_string() }}) as country
        {% endif %}

    from customers
    {% if using_entity_address %}
    left join entity_address
        on coalesce(customers.default_billing_address_id, customers.default_shipping_address_id) = entity_address.nkey
    {% endif %}
)

select *
from joined