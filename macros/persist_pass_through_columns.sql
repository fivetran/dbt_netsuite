{% macro persist_pass_through_columns(pass_through_variable, identifier=none, transform='') %}

{{ adapter.dispatch('persist_pass_through_columns', 'netsuite') (pass_through_variable, identifier=identifier, transform='') }}

{%- endmacro %}


{% macro default__persist_pass_through_columns(pass_through_variable, identifier=none, transform='') %}
{% if pass_through_variable %}
    {% for field in pass_through_variable %}
    , {{ transform ~ '(' ~ (identifier ~ '.' if identifier else '') ~ (field.alias if field.alias else field.name) ~ ')' }} as {{ field.alias if field.alias else field.name }}
    {% endfor %}
{% endif %}
{% endmacro %}
