{{ config(enabled=(var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2') and var('netsuite2__using_employees', true))) }} 

with base as (

    select * 
    from {{ ref('stg_netsuite2__employees_tmp') }}
),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_netsuite2__employees_tmp')),
                staging_columns=get_employee_columns()
            )
        }}
    from base
),

final as (
    
    select
        _fivetran_synced,
        id as employee_id,
        entityid as entity_id,
        firstname as first_name,
        lastname as last_name,
        department as department_id,
        subsidiary as subsidiary_id,
        email,
        supervisor as supervisor_id,
        approvallimit as approval_limit,
        expenselimit as expense_limit,
        purchaseorderapprovallimit as purchase_order_approval_limit,
        purchaseorderlimit as purchase_order_limit,
        currency as currency_id,
        isinactive = 'T' as is_inactive
    from fields
)

select * 
from final
