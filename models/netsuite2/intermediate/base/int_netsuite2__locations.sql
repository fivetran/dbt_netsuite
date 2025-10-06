{%- set using_location_main_address = var('netsuite2__using_location_main_address', true) -%}

{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')) }}

with locations as (

    select *
    from {{ ref('stg_netsuite2__locations') }}
),

{% if using_location_main_address %}
location_main_address as (

    select *
    from {{ ref('stg_netsuite2__location_main_address') }}
),
{% endif %}

joined as (

    select
        locations.*
        {% if using_location_main_address %},
        location_main_address.city,
        location_main_address.state,
        location_main_address.zipcode,
        location_main_address.country
        {% else %},
        cast(null as {{ dbt.type_string() }}) as city,
        cast(null as {{ dbt.type_string() }}) as state,
        cast(null as {{ dbt.type_string() }}) as zipcode,
        cast(null as {{ dbt.type_string() }}) as country
        {% endif %}

    from locations
    {% if using_location_main_address %}
    left join location_main_address
        on locations.main_address_id = location_main_address.nkey
    {% endif %}
)

select *
from joined