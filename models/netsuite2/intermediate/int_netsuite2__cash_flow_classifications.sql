{{ config(
  enabled = var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override', 'netsuite2')
) }}

-- load the dictionary with the classification filters
{% set classifications = var('cash_flow_classifications', var('cash_flow_defaults', {})) %}

with transaction_details as (
  select *
  from {{ ref('netsuite2__transaction_details') }}
), 

transaction_classifications as (
    select
        *,
        -- iterate through the categories and filters in classifications
        case
          {% for category, filters in classifications.items() %}
            {% for filter in filters %}
              when {{ filter.condition }}
              {% if filter.exclude is defined and filter.exclude %}
                then null
              {% else %}
                then '{{ category }}_transactions'
              {% endif %}
            {% endfor %}
          {% endfor %}
          else null
          end as cash_flow_category,

        case
          {% for category, filters in classifications.items() %}
            {% for filter in filters %}
              when {{ filter.condition }}
              {% if filter.subcategory is defined  %}
                then '{{ filter.subcategory }}'
              {% else %}
                then null
              {% endif %}
            {% endfor %}
          {% endfor %}
          else null
          end as cash_flow_subcategory
    from transaction_details
)

select *
from transaction_classifications
where cash_flow_category is not null