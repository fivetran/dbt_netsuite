{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2'))}}

{%- set multibook_enabled = true if var('netsuite2__multibook_accounting_enabled', false) -%}
{%- set multibook_cols = ['accounting_book_id', 'accounting_book_name'] -%}

{%- set to_subsidiary_enabled = (var('netsuite2__using_to_subsidiary', false) and var('netsuite2__using_exchange_rate', true)) -%}
{{ print('to sub ' ~ to_subsidiary_enabled)}}
{%- set to_subsidiary_cols = ['to_subsidiary_id', 'to_subsidiary_name', 'to_subsidiary_currency_symbol'] -%}

{%- set base_cols_list = ['accounting_period_ending', 'subsidiary_id', 'subsidiary_name'] -%}
{%- do base_cols_list.extend(multibook_cols) if multibook_enabled -%}
{%- do base_cols_list.extend(to_subsidiary_cols) if to_subsidiary_enabled -%}
{%- set base_cols_sql = base_cols_list | join(',\n') -%}

with income_statement as (
    select
        {{ base_cols_sql }},
        sum(case when lower(account_category) in ('income', 'expense') then transaction_amount else 0 end) as net_income,
        sum(case when lower(account_name) like '%depreciation%' or lower(account_name) like '%amortization%' then transaction_amount else 0 end) as non_cash_expenses
    from {{ ref('netsuite2__income_statement') }}
    {{ dbt_utils.group_by(base_cols_list|length) }}
),

balance_sheet as (
    select
        {{ base_cols_sql }},
        account_type_name,
        account_type_id,
        account_name,
        account_id,
        sum(transaction_amount) as transaction_amount
    from {{ ref('netsuite2__balance_sheet') }}
    where lower(account_type_id) in ('acctpay', 'acctrec', 'bank', 'credcard', 
        'deferexpense', 'deferrevenue', 'equity', 'fixedasset', 'longtermliab', 
        'othasset', 'othcurrasset', 'othcurrliab', 'unbilledrec')
    and not is_accounting_period_adjustment
    {{ dbt_utils.group_by(base_cols_list|length + 4) }}
),

balance_sheet_prev_transaction as (
    select
        *,
        lag(transaction_amount) over (
            partition by -- need to make these dynamic
                {{ 'accounting_book_id,' if multibook_enabled }}
                {{ 'to_subsidiary_id,' if to_subsidiary_enabled }}
                subsidiary_id,
                account_id
            order by accounting_period_ending
        ) as prev_transaction_amount
    from balance_sheet
),

balance_sheet_changes as (
    select
        *,
        transaction_amount - coalesce(prev_transaction_amount, 0) as change_since_prev_period
    from balance_sheet_prev_transaction
),

category_changes as (
    select
        {{ base_cols_sql }},
        -- working capital changes 
        sum(case when lower(account_type_id) = 'acctrec' 
            then change_since_prev_period else 0 end) as change_in_ar,
        sum(case when lower(account_type_id) = 'acctpay' 
            then change_since_prev_period else 0 end) as change_in_ap,
        sum(case when lower(account_type_id) = 'othcurrasset' 
            then change_since_prev_period else 0 end) as change_in_inventory,

        -- investment changes
        sum(case when lower(account_type_id) in ('deferexpense', 'fixedasset', 'othasset', 'unbilledrec')
            then change_since_prev_period else 0 end) as change_in_investments,

        -- financing changes
        sum(case when lower(account_type_id) = 'equity' and lower(account_name) not like '%stock%' -- stocks not treated as cash
            then change_since_prev_period else 0 end) as change_in_equity,
        sum(case when lower(account_type_id) = 'deferrevenue' 
            then change_since_prev_period else 0 end) as change_in_deferred_revenue,
        sum(case when lower(account_type_id) in ('longtermliab', 'othcurrliab', 'credcard') 
            then change_since_prev_period else 0 end) as change_in_debt,

        -- bank changes
        sum(case when lower(account_type_id) = 'bank'
            then change_since_prev_period else 0 end) as change_in_cash
    from balance_sheet_changes
    {{ dbt_utils.group_by(base_cols_list|length) }}
),

cash_flow as (
    select
        {% for col in base_cols_list %}
        income_statement.{{ col }},
        {% endfor %}

        sum(coalesce(income_statement.net_income, 0)) as net_income,
        sum(coalesce(income_statement.non_cash_expenses, 0)) as non_cash_expenses,

        -- Operating Cash Flow
        sum(coalesce(category_changes.change_in_ar, 0)) as change_in_ar,
        sum(coalesce(category_changes.change_in_ap, 0)) as change_in_ap,
        sum(coalesce(category_changes.change_in_inventory, 0)) as change_in_inventory,
        sum((income_statement.net_income
            + income_statement.non_cash_expenses
            - coalesce(category_changes.change_in_ar, 0)
            - coalesce(category_changes.change_in_inventory, 0)
            + coalesce(category_changes.change_in_ap, 0))) as cash_from_operations,

        -- Investing Cash Flow
        sum(coalesce(category_changes.change_in_investments, 0)) as cash_from_investing,

        -- Financing Cash Flow
        sum(coalesce(category_changes.change_in_equity, 0) 
            + coalesce(category_changes.change_in_deferred_revenue, 0) 
            + coalesce(category_changes.change_in_debt, 0)) as cash_from_financing,

        -- Bank Change in Cash
        sum(coalesce(category_changes.change_in_cash, 0)) as reported_change_in_cash

    from income_statement
    left join category_changes
        on 
        {% for col in base_cols_list %}
            {{ 'and' if not loop.first}} income_statement.{{ col }} = category_changes.{{ col }}
        {% endfor %}
    {{ dbt_utils.group_by(base_cols_list|length) }}
),

final as (
    select
        *,
        -- Net Cash Flow
        cash_from_operations + cash_from_investing + cash_from_financing as net_cash_flow
    from cash_flow
)

select *
from final