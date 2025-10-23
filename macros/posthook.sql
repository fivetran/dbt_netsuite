{# macros/remove_deleted_rows_post_hook.sql #}
{% macro remove_deleted_rows_post_hook(source_model, source_key, target_key) -%}
  {{ return(adapter.dispatch('remove_deleted_rows_post_hook')(source_model, source_key, target_key)) }}
{%- endmacro %}

{% macro default__remove_deleted_rows_post_hook(source_model, source_key, target_key) -%}
  delete from {{ this }} as model
  where exists (
    select 1
    from {{ ref(source_model)  }} as source_model
    where source_model.{{ source_key }} = model.{{ target_key }}
      and coalesce(source_model._fivetran_deleted, false) = true
  )
{%- endmacro %}