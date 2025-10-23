{# macros/remove_deleted_rows_post_hook.sql #}
{% macro remove_deleted_rows_post_hook(src_model, src_pk, tgt_pk) -%}
  {{ return(adapter.dispatch('remove_deleted_rows_post_hook')(src_model, src_pk, tgt_pk)) }}
{%- endmacro %}

{% macro default__remove_deleted_rows_post_hook(src_model, src_pk, tgt_pk) -%}
  {%- set src = ref(src_model) -%}
  delete from {{ this }} as model
  where exists (
    select 1
    from {{ src }} as src
    where src.{{ src_pk }} = model.{{ tgt_pk }}
      and coalesce(src._fivetran_deleted, false) = true
  )
{%- endmacro %}

{# Snowflake #}
{# {% macro snowflake__remove_deleted_rows_post_hook(src_model, src_pk, tgt_pk) -%}
  {%- set src = ref(src_model) -%}
  delete from {{ this }}
  using {{ src }} as src
  where {{ this }}.{{ tgt_pk }} = src.{{ src_pk }}
    and coalesce(src._fivetran_deleted, false) = true
{%- endmacro %} #}
