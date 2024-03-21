{% macro parent_details(table, entity_id_column_name, parent_id_column_name, max_levels = 20) -%}

with entities as (

    select *
    from {{ table }}
)

{% for i in range(max_levels) -%}

, level{{ i }} as (

    select
        {{ i }} as level, 
        entities.{{ entity_id_column_name }},
        entities.{{ parent_id_column_name }},
        {% if loop.first -%}
        entities.{{entity_id_column_name}} as top_{{ parent_id_column_name }},
        1 as display_level,
        entities.account_number || ' - ' || entities.display_name as display_full_name
        {% else -%}
        parent_entities.top_{{ parent_id_column_name }},
        parent_entities.display_level + 1 as display_level,
        parent_entities.display_full_name || ' : ' || entities.account_number || ' - ' || entities.display_name as display_full_name
        {%- endif %}
    from entities
    {% if loop.first -%}
    where {{ parent_id_column_name }} is null
    {% else -%}
    inner join level{{ i-1 }} as parent_entities on entities.{{ parent_id_column_name }} = parent_entities.{{ entity_id_column_name }}
    {% endif %}
)

{%- endfor %}

{% for i in range(max_levels) -%}
select *
from level{{ i }}
{% if not loop.last %}
union all
{% endif %}
{% endfor %}

{%- endmacro %}