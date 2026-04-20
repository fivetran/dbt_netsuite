{% macro null_cast_pass_through_columns(pass_through_variable, relation) %}

{{ adapter.dispatch('null_cast_pass_through_columns', 'netsuite') (pass_through_variable, relation) }}

{%- endmacro %}


{% macro default__null_cast_pass_through_columns(pass_through_variable, relation) %}
{% if pass_through_variable %}
    {% set column_type_map = {} %}
    {% if execute and flags.WHICH in ('run', 'build') %}
        {% for col in adapter.get_columns_in_relation(relation) %}
            {% do column_type_map.update({col.name | lower: col.data_type}) %}
        {% endfor %}
    {% endif %}
    {% for field in pass_through_variable %}
        {% set col_name = (field.alias if field.alias else field.name) | lower %}
        {% set col_type = column_type_map.get(col_name, dbt.type_string()) %}
    , cast(null as {{ col_type }}) as {{ field.alias if field.alias else field.name }}
    {% endfor %}
{% endif %}
{% endmacro %}
