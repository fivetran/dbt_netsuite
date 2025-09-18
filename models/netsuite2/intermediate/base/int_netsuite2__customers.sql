{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')) }}

with customers as (

    select *
    from {{ ref('netsuite', 'stg_netsuite2__customers') }}
),

entity_address as (

    select *
    from {{ ref('netsuite', 'stg_netsuite2__entity_address') }}
),

joined as (

    select 
        customers.*,
        entity_address.city,
        entity_address.state,
        entity_address.zipcode,
        entity_address.country

    from customers
    left join entity_address
        on coalesce(customers.default_billing_address_id, customers.default_shipping_address_id) = entity_address.nkey
)

select *
from joined