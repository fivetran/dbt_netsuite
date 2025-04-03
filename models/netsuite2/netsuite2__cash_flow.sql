{{ config(
    enabled = var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override', 'netsuite2')
) }}

{%- set multibook_enabled = var('netsuite2__multibook_accounting_enabled', false) -%}
{%- set multibook_cols = ['accounting_book_id', 'accounting_book_name'] -%}

{%- set to_subsidiary_enabled = (var('netsuite2__using_to_subsidiary', false) and var('netsuite2__using_exchange_rate', true)) -%}
{%- set to_subsidiary_cols = ['to_subsidiary_id', 'to_subsidiary_name', 'to_subsidiary_currency_symbol'] -%}

{%- set base_cols_list = ['accounting_period_ending', 'subsidiary_id', 'subsidiary_name'] -%}
{%- do base_cols_list.extend(multibook_cols) if multibook_enabled -%}
{%- do base_cols_list.extend(to_subsidiary_cols) if to_subsidiary_enabled -%}
{%- set base_cols_sql = base_cols_list | join(',\n') -%}

with cash_flow_classifications as (
    select *
    from {{ ref('int_netsuite2__cash_flow_classifications') }}
),

aggregated_transactions as (
    select
        {{ base_cols_sql }},
        cash_flow_category,
        cash_flow_subcategory,
        sum(transaction_amount) as cash_ending_period
    from cash_flow_classifications
    {{ dbt_utils.group_by(base_cols_list|length + 2) }}
), 

with_lag as (
    select
        *,
        lag(cash_ending_period) over (
            partition by
                {{ base_cols_sql }},
                cash_flow_category,
                cash_flow_subcategory
            order by accounting_period_ending
        ) as cash_beginning_period
    from aggregated_transactions
),

final as (
    select
        {{ base_cols_sql }},
        accounting_period_ending,
        cash_flow_category,
        cash_flow_subcategory,
        cash_beginning_period,
        cash_ending_period,
        cash_ending_period - coalesce(cash_beginning_period, 0) as cash_net_period
    from with_lag
)

select *
from final