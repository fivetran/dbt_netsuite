{{ config(
    enabled = var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override', 'netsuite2')
) }}

{%- set multibook_enabled = var('netsuite2__multibook_accounting_enabled', false) -%}
{%- set multibook_cols = ['accounting_book_id', 'accounting_book_name'] -%}

{%- set to_subsidiary_enabled = (var('netsuite2__using_to_subsidiary', false) and var('netsuite2__using_exchange_rate', true)) -%}
{%- set to_subsidiary_cols = ['to_subsidiary_id', 'to_subsidiary_name', 'to_subsidiary_currency_symbol'] -%}

{%- set base_cols_list = ['subsidiary_id', 'subsidiary_name'] -%}
{%- do base_cols_list.extend(multibook_cols) if multibook_enabled -%}
{%- do base_cols_list.extend(to_subsidiary_cols) if to_subsidiary_enabled -%}
{%- set base_cols_sql = base_cols_list | join(', ') -%}

{%- set categories = var('cash_flow_classifications', var('cash_flow_defaults', {})).keys() -%}

with cash_flow_classifications as (
    select *
    from {{ ref('int_netsuite2__cash_flow_classifications') }}
),

aggregated_by_category as (
    select
        {{ base_cols_sql }},
        accounting_period_ending,
        cash_flow_category,
        sum(transaction_amount) as cash_net_period
    from cash_flow_classifications
    {{ dbt_utils.group_by(base_cols_list | length + 2) }}
),

pivoted_cash_flow as (
    select
        {{ base_cols_sql }},
        accounting_period_ending,


        {%- for category in categories %}
            sum(
                case when cash_flow_category = '{{ category }}_transactions'
                then cash_net_period
                else 0 end) 
            as {{ category }}_cash_flow {{ ',' if not loop.last }}
        {%- endfor %}

    from aggregated_by_category
    {{ dbt_utils.group_by(base_cols_list | length + 1) }}
),

total_cash as (
    select
        *,
        {%- for category in categories %}
            {{ category }}_cash_flow {{ '+' if not loop.last }}
        {%- endfor %}
        as net_cash_flow
    from pivoted_cash_flow
),

with_beginning_cash as (
    select
        *,
        lag(net_cash_flow) over (
            partition by {{ base_cols_sql }}
            order by accounting_period_ending
        ) as beginning_cash
    from total_cash
),

income_statement as (
    select *
    from {{ ref('netsuite2__income_statement') }}
),

income_statement_classifications as (
    select
        {{ base_cols_sql }},
        accounting_period_ending,
        sum(case when lower(account_category) in ('income', 'expense') then transaction_amount else 0 end) as net_income,
        sum(case when lower(account_name) like '%depreciation%' or lower(account_name) like '%amortization%' then transaction_amount else 0 end) as non_cash_expenses
    from income_statement
    {{ dbt_utils.group_by(base_cols_list | length + 1) }}
),

final as (
    select
        with_beginning_cash.accounting_period_ending,
        {% for col in base_cols_list %}
            with_beginning_cash.{{ col }},
        {% endfor %}

        {%- for category in categories %}
            with_beginning_cash.{{ category }}_cash_flow ,
        {%- endfor %}

        with_beginning_cash.net_cash_flow,
        with_beginning_cash.beginning_cash,
        coalesce(with_beginning_cash.beginning_cash, 0) + with_beginning_cash.net_cash_flow as ending_cash,
        income_statement_classifications.net_income,
        income_statement_classifications.non_cash_expenses
    from with_beginning_cash
    left join income_statement_classifications
        on with_beginning_cash.accounting_period_ending = income_statement_classifications.accounting_period_ending
        and {% for col in base_cols_list %}
            with_beginning_cash.{{ col }} = income_statement_classifications.{{ col }}
            {% if not loop.last %} and {% endif %}
        {% endfor %}
)

select *
from final
order by accounting_period_ending
