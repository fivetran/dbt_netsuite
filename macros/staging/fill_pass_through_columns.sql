{% macro fill_pass_through_columns(pass_through_variable) %}

{{ adapter.dispatch('fill_pass_through_columns', 'netsuite') (pass_through_variable) }}

{%- endmacro %}

{% macro default__fill_pass_through_columns(pass_through_variable) %}

{% if pass_through_variable %}
    {% for field in pass_through_variable %}
        {% if field is mapping %}
            {% if field.transform_sql %}
                , {{ field.transform_sql }} as {{ field.alias if field.alias else field.name }}
            {% else %}
                , {{ field.alias if field.alias else field.name }}
            {% endif %}
        {% else %}
        , {{ field }}
        {% endif %}
    {% endfor %}
{% endif %}

{% endmacro %}