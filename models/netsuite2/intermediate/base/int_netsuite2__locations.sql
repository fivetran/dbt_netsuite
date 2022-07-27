{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')) }}

with locations as (

    select *
    from {{ var('netsuite2_locations') }}
),

location_main_address as (

    select *
    from {{ var('netsuite2_location_main_address') }}
),

joined as (

    select 
        locations.*,
        location_main_address.city,
        location_main_address.state,
        location_main_address.zipcode,
        location_main_address.country

    from locations
    left join location_main_address
        on locations.main_address_id = location_main_address.nkey
)

select *
from joined