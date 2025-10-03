{% macro apply_source_relation() -%}

{{ adapter.dispatch('apply_source_relation', 'netsuite') () }}

{%- endmacro %}

{% macro default__apply_source_relation() -%}

{% if var('netsuite_sources', []) != [] %}
, _dbt_source_relation as source_relation
{% else %}
, '{{ var("netsuite_database", target.database) }}' || '.'|| '{{ var("netsuite_schema", "netsuite") }}' as source_relation
{% endif %} 

{%- endmacro %}