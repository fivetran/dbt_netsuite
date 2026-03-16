{%- macro partition_by_source_relation(has_other_partitions='yes', alias=None) -%}

{{ adapter.dispatch('partition_by_source_relation', 'netsuite') (has_other_partitions, alias) }}

{%- endmacro %}

{% macro default__partition_by_source_relation(has_other_partitions='yes', alias=None) -%}
    {% set prefix = '' if alias is none else alias ~ '.' %}

    {%- if has_other_partitions == 'no' -%}
        {{ 'partition by ' ~ prefix ~ 'source_relation' if var('netsuite2_sources', [])|length > 1 }}
    {%- else -%}
        {{ ', ' ~ prefix ~ 'source_relation' if var('netsuite2_sources', [])|length > 1 }}
    {%- endif -%}
{%- endmacro -%}