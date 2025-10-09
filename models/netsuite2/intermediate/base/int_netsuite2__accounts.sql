{%- set using_account_types = var('netsuite2__using_account_types', true) -%}

{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')) }}

with accounts as (

    select *
    from {{ ref('stg_netsuite2__accounts') }}
),

{% if using_account_types %}
account_types as (

    select *
    from {{ ref('stg_netsuite2__account_types') }}
),
{% endif %}

joined as (

    select
        accounts.*
        {% if using_account_types %},
        account_types.type_name,
        account_types.is_balancesheet,
        account_types.is_leftside
        {% else %},
        cast(null as {{ dbt.type_string() }}) as type_name,
        cast(null as boolean) as is_balancesheet,
        cast(null as boolean) as is_leftside
        {% endif %}

    from accounts
    {% if using_account_types %}
    left join account_types
        on accounts.account_type_id = account_types.account_type_id
        and accounts.source_relation = account_types.source_relation
    {% endif %}
)

select *
from joined

