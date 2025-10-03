{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')) }}

with base as (

    select *
        from {{ ref('stg_netsuite2__nexuses_tmp') }}

),

fields as (

select
    {{
    fivetran_utils.fill_staging_columns(
    source_columns=adapter.get_columns_in_relation(ref('stg_netsuite2__nexuses_tmp')),
    staging_columns=get_netsuite2_nexuses_columns()
    )
    }}
    from base
        ),

        final as (

select
    _fivetran_synced,
    id as nexus_id,
    country,
    description,
    state,
    taxagency as tax_agency_id

    --The below macro adds the fields defined within your nexuses_pass_through_columns variable into the staging model
    {{ fivetran_utils.fill_pass_through_columns('nexuses_pass_through_columns') }}

    from fields
    where not coalesce(_fivetran_deleted, false)
        )

select *
    from final

