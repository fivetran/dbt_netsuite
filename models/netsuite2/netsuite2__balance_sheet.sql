{%- set multibook_accounting_enabled = var('netsuite2__multibook_accounting_enabled', false) -%}
{%- set using_to_subsidiary_and_exchange_rate = (var('netsuite2__using_to_subsidiary', false) and var('netsuite2__using_exchange_rate', true)) -%}
{%- set balance_sheet_transaction_detail_columns = var('balance_sheet_transaction_detail_columns', []) -%}
{%- set accounts_pass_through_columns = var('accounts_pass_through_columns', []) -%}
{%- set lookback_window = var('lookback_window', 3) -%}
{%- set transaction_level = var('netsuite2__balance_sheet_transaction_level', True) -%}
{%- set using_incremental = var('netsuite2__balance_sheet_use_incremental', false) -%}
{% set pass_through_column_count = accounts_pass_through_columns|length + (balance_sheet_transaction_detail_columns|length if transaction_level else 0) %}
{% set variable_column_count = (2 if multibook_accounting_enabled else 0) + (3 if using_to_subsidiary_and_exchange_rate else 0) %}

{{
    config(
        enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2'),
        materialized='incremental' if using_incremental else 'table',
        partition_by = {'field': '_fivetran_synced_date', 'data_type': 'date', 'granularity': 'month'}
            if target.type not in ['spark', 'databricks'] else ['_fivetran_synced_date'],       
        cluster_by = ['transaction_id'] if transaction_level else ['account_id', 'accounting_period_id'],
        unique_key='balance_sheet_id',
        incremental_strategy = 'merge' if target.type in ('bigquery', 'databricks', 'spark') else 'delete+insert',
        file_format='delta'
    )
}}

with transactions_with_converted_amounts_init as (
    select * 
    from {{ ref('int_netsuite2__tran_with_converted_amounts') }}

    where (is_account_balancesheet or is_income_statement) and reporting_accounting_period_id is not null

    {% if is_incremental() %}
    and _fivetran_synced_date >= {{ netsuite.netsuite_lookback(from_date='max(_fivetran_synced_date)', datepart='day', interval=lookback_window) }}
    {% endif %}
), 

{% if transaction_level %}
transactions_with_converted_amounts as (
    select * 
    from transactions_with_converted_amounts_init
),

{% else %}
-- We're rolling up past the transaction level
transactions_with_converted_amounts as (
    select 
        source_relation,
        subsidiary_id,
        _fivetran_synced_date,
        account_category,
        account_name,
        account_display_name,
        account_type_name,
        account_type_id,
        account_id,
        account_number,
        is_account_balancesheet,
        is_account_leftside,
        is_account_eliminate,
        special_account_type_id,
        reporting_accounting_period_id,
        transaction_accounting_period_id,
        account_general_rate_type,
        retained_earnings_account_number,
        cumulative_translation_account_number
        {{ netsuite.persist_pass_through_columns(accounts_pass_through_columns) }},

        {% if multibook_accounting_enabled %}
        accounting_book_id, 
        accounting_book_name,
        {% endif %}
        
        {% if using_to_subsidiary_and_exchange_rate %}
        to_subsidiary_id,
        to_subsidiary_name,
        to_subsidiary_currency_symbol,
        {% endif %}
        
        sum(converted_amount_using_transaction_accounting_period) as converted_amount_using_transaction_accounting_period,
        sum(converted_amount_using_reporting_month) as converted_amount_using_reporting_month,
        sum(unconverted_amount) as unconverted_amount

    from transactions_with_converted_amounts_init

    {{ dbt_utils.group_by(n=19 + pass_through_column_count + variable_column_count) }}

),

{% endif %}

--Below is only used if balance sheet transaction detail columns are specified dbt_project.yml file.
{% if balance_sheet_transaction_detail_columns != [] and transaction_level %}
transaction_details as (
    select * 
    from {{ ref('netsuite2__transaction_details') }}
), 
{% endif %}

accounting_periods as (
    select * 
    from {{ ref('int_netsuite2__accounting_periods') }}
), 

subsidiaries as (
    select * 
    from {{ ref('stg_netsuite2__subsidiaries') }}
),

currencies as (
    select *
    from {{ ref('stg_netsuite2__currencies') }}
),

balance_sheet_join as (

    select 
        transactions_with_converted_amounts.*, -- contains account pass through columns
        subsidiaries.full_name as subsidiary_full_name,
        subsidiaries.name as subsidiary_name,

        subsidiaries_currencies.symbol as subsidiary_currency_symbol,

        reporting_accounting_periods.accounting_period_id as accounting_period_id,
        reporting_accounting_periods.ending_at as accounting_period_ending,
        reporting_accounting_periods.accounting_period_full_name,
        reporting_accounting_periods.name as accounting_period_name,
        reporting_accounting_periods.is_adjustment as is_accounting_period_adjustment,
        reporting_accounting_periods.is_closed as is_accounting_period_closed,

        reporting_accounting_periods.fiscal_year_trunc as reporting_fiscal_year_trunc,
        reporting_accounting_periods.fiscal_calendar_id as reporting_fiscal_calendar_id,
        transaction_accounting_periods.fiscal_year_trunc as transaction_fiscal_year_trunc,
        transaction_accounting_periods.fiscal_calendar_id as transaction_fiscal_calendar_id

    from transactions_with_converted_amounts

    --Below is only used if balance sheet transaction detail columns are specified dbt_project.yml file.
    {% if balance_sheet_transaction_detail_columns != [] and transaction_level %}
    left join transaction_details
        on transaction_details.transaction_id = transactions_with_converted_amounts.transaction_id
        and transaction_details.transaction_line_id = transactions_with_converted_amounts.transaction_line_id
        and transaction_details.source_relation = transactions_with_converted_amounts.source_relation
        
        {% if multibook_accounting_enabled %}
        and transaction_details.accounting_book_id = transactions_with_converted_amounts.accounting_book_id
        {% endif %}

        {% if using_to_subsidiary_and_exchange_rate %}
        and transaction_details.to_subsidiary_id = transactions_with_converted_amounts.to_subsidiary_id
        {% endif %}
    {% endif %}

    left join subsidiaries
        on subsidiaries.subsidiary_id = transactions_with_converted_amounts.subsidiary_id
        and subsidiaries.source_relation = transactions_with_converted_amounts.source_relation

    {% if using_to_subsidiary_and_exchange_rate %}
    left join subsidiaries as to_subsidiaries
        on to_subsidiaries.subsidiary_id = coalesce(transactions_with_converted_amounts.to_subsidiary_id, subsidiaries.subsidiary_id)
        and to_subsidiaries.source_relation = transactions_with_converted_amounts.source_relation
    {% endif %}

    left join accounting_periods as reporting_accounting_periods 
        on reporting_accounting_periods.accounting_period_id = transactions_with_converted_amounts.reporting_accounting_period_id
        and reporting_accounting_periods.source_relation = transactions_with_converted_amounts.source_relation
        and reporting_accounting_periods.fiscal_calendar_id = {{ 'to_subsidiaries' if using_to_subsidiary_and_exchange_rate else 'subsidiaries' }}.fiscal_calendar_id

    left join accounting_periods as transaction_accounting_periods
        on transaction_accounting_periods.accounting_period_id = transactions_with_converted_amounts.transaction_accounting_period_id
        and transaction_accounting_periods.source_relation = transactions_with_converted_amounts.source_relation
        and transaction_accounting_periods.fiscal_calendar_id = {{ 'to_subsidiaries' if using_to_subsidiary_and_exchange_rate else 'subsidiaries' }}.fiscal_calendar_id

    left join currencies subsidiaries_currencies
        on subsidiaries_currencies.currency_id = subsidiaries.currency_id
        and subsidiaries_currencies.source_relation = subsidiaries.source_relation
),

balance_sheet as ( 
    select
        source_relation,

        {% if transaction_level %}
        transaction_id,
        transaction_line_id,
        {% endif %}

        subsidiary_id,
        _fivetran_synced_date,
        subsidiary_full_name,
        subsidiary_name,
        subsidiary_currency_symbol,

        {% if multibook_accounting_enabled %}
        accounting_book_id,
        accounting_book_name,
        {% endif %}
        
        {% if using_to_subsidiary_and_exchange_rate %}
        to_subsidiary_id,
        to_subsidiary_name,
        to_subsidiary_currency_symbol,
        {% endif %}

        accounting_period_id,
        accounting_period_ending,
        accounting_period_full_name,
        accounting_period_name,
        is_accounting_period_adjustment,
        is_accounting_period_closed,
        account_category,
        case
        when (not is_account_balancesheet
                and reporting_fiscal_year_trunc = transaction_fiscal_year_trunc 
                and reporting_fiscal_calendar_id = transaction_fiscal_calendar_id) then 'Net Income'
        when not is_account_balancesheet then 'Retained Earnings'
        else account_name
            end as account_name,
        case
        when (not is_account_balancesheet
                and reporting_fiscal_year_trunc = transaction_fiscal_year_trunc 
                and reporting_fiscal_calendar_id = transaction_fiscal_calendar_id) then 'Net Income'
        when not is_account_balancesheet then 'Retained Earnings'
        else account_display_name
            end as account_display_name,
        case
        when (not is_account_balancesheet
                and reporting_fiscal_year_trunc = transaction_fiscal_year_trunc 
                and reporting_fiscal_calendar_id = transaction_fiscal_calendar_id) then 'Net Income'
        when not is_account_balancesheet then 'Retained Earnings'
        when lower(special_account_type_id) = 'retearnings' then 'Retained Earnings'
        when lower(special_account_type_id) in ('cta-e', 'cumultransadj') then 'Cumulative Translation Adjustment'
        else account_type_name
            end as account_type_name,
        case
        when (not is_account_balancesheet
                and reporting_fiscal_year_trunc = transaction_fiscal_year_trunc 
                and reporting_fiscal_calendar_id = transaction_fiscal_calendar_id) then 'net_income'
        when not is_account_balancesheet then 'retained_earnings'
        when lower(special_account_type_id) = 'retearnings' then 'retained_earnings'
        when lower(special_account_type_id) in ('cta-e', 'cumultransadj') then 'cumulative_translation_adjustment'
        else account_type_id
            end as account_type_id,
        case
        when not is_account_balancesheet then null
        else account_id
            end as account_id,
        case
        when not is_account_balancesheet then retained_earnings_account_number 
        else account_number
            end as account_number,
        case
        when not is_account_balancesheet then false
        else is_account_eliminate
            end as is_account_intercompany,
        case
        when not is_account_balancesheet then false
        else is_account_leftside
            end as is_account_leftside

        --The below script allows for accounts table pass through columns.
        {{ netsuite.persist_pass_through_columns(accounts_pass_through_columns) }},

        case
        when lower(account_type_id) = 'bank' then 1
        when lower(account_type_id) = 'acctrec' then 2
        when lower(account_type_id) = 'unbilledrec' then 3
        when lower(account_type_id) = 'othcurrasset' then 4
        when lower(account_type_id) = 'fixedasset' then 5
        when lower(account_type_id) = 'othasset' then 6
        when lower(account_type_id) = 'deferexpense' then 7
        when lower(account_type_id) = 'acctpay' then 8
        when lower(account_type_id) = 'credcard' then 9
        when lower(account_type_id) = 'othcurrliab' then 10
        when lower(account_type_id) = 'longtermliab' then 11
        when lower(account_type_id) = 'deferrevenue' then 12
        when lower(special_account_type_id) = 'retearnings' then 14
        when lower(special_account_type_id) in ('cta-e', 'cumultransadj') then 16
        when lower(account_type_id) = 'equity' then 13
        when (not is_account_balancesheet
                and reporting_fiscal_year_trunc = transaction_fiscal_year_trunc
                and reporting_fiscal_calendar_id = transaction_fiscal_calendar_id) then 15
        when not is_account_balancesheet then 14
        else null
            end as balance_sheet_sort_helper,

        --Below is only used if balance sheet transaction detail columns are specified dbt_project.yml file.
        {% if balance_sheet_transaction_detail_columns and transaction_level %}

        {{ balance_sheet_transaction_detail_columns | join (",") }},

        {% endif %}

        sum(case
        when not is_account_balancesheet and lower(account_general_rate_type) in ('historical', 'average') then -converted_amount_using_transaction_accounting_period
        when not is_account_balancesheet then -converted_amount_using_reporting_month
        when is_account_balancesheet and not is_account_leftside and lower(account_general_rate_type) in ('historical', 'average') then -converted_amount_using_transaction_accounting_period
        when is_account_balancesheet and is_account_leftside and lower(account_general_rate_type) in ('historical', 'average') then converted_amount_using_transaction_accounting_period
        when is_account_balancesheet and not is_account_leftside then -converted_amount_using_reporting_month
        when is_account_balancesheet and is_account_leftside then converted_amount_using_reporting_month
        else 0
            end) as converted_amount,

        sum(case
        when not is_account_balancesheet then -unconverted_amount
        when is_account_balancesheet and not is_account_leftside then -unconverted_amount
        when is_account_balancesheet and is_account_leftside then unconverted_amount
        else 0
            end) as transaction_amount

    from balance_sheet_join
    
    {{ dbt_utils.group_by(n=22 + pass_through_column_count + variable_column_count + (2 if transaction_level else 0)) }}

    union all

    select
        source_relation,

        {% if transaction_level %}
        transaction_id,
        transaction_line_id,
        {% endif %}

        subsidiary_id,
        _fivetran_synced_date,
        subsidiary_full_name,
        subsidiary_name,
        subsidiary_currency_symbol,

        {% if multibook_accounting_enabled %}
        accounting_book_id,
        accounting_book_name,
        {% endif %}

        {% if using_to_subsidiary_and_exchange_rate %}
        to_subsidiary_id,
        to_subsidiary_name,
        to_subsidiary_currency_symbol,
        {% endif %}
        
        accounting_period_id,
        accounting_period_ending,
        accounting_period_full_name,
        accounting_period_name,
        is_accounting_period_adjustment,
        is_accounting_period_closed,
        'Equity' as account_category,
        'Cumulative Translation Adjustment' as account_name,
        'Cumulative Translation Adjustment' as account_display_name,
        'Cumulative Translation Adjustment' as account_type_name,
        'cumulative_translation_adjustment' as account_type_id,
        cast(null as {{ dbt.type_int() }}) as account_id,
        cumulative_translation_account_number as account_number,
        false as is_account_intercompany,
        false as is_account_leftside,

        {% if accounts_pass_through_columns != [] %}
        {% for field in accounts_pass_through_columns %}
            null as {{ field.alias if field.alias else field.name }},
        {% endfor %}
        {% endif %}

        16 as balance_sheet_sort_helper,

        --Below is only used if balance sheet transaction detail columns are specified dbt_project.yml file.
        {% if balance_sheet_transaction_detail_columns and transaction_level %}

        {{ balance_sheet_transaction_detail_columns | join (",") }},

        {% endif %}

        sum(case
        when lower(account_general_rate_type) in ('historical', 'average') then converted_amount_using_transaction_accounting_period
        else converted_amount_using_reporting_month
            end) as converted_amount,

        sum(unconverted_amount) as transaction_amount

    from balance_sheet_join

    {{ dbt_utils.group_by(n=22 + pass_through_column_count + variable_column_count + (2 if transaction_level else 0)) }}
),

surrogate_key as ( 
{% set surrogate_key_fields = ['source_relation', 'transaction_line_id', 'transaction_id', 'accounting_period_id', 'account_name', 'account_id'] if transaction_level else ['source_relation', 'accounting_period_id', 'account_name', 'account_id'] %}
{% do surrogate_key_fields.append('to_subsidiary_id') if using_to_subsidiary_and_exchange_rate %}
{% do surrogate_key_fields.append('accounting_book_id') if multibook_accounting_enabled %}

select 
    *,
    {{ dbt_utils.generate_surrogate_key(surrogate_key_fields) }} as balance_sheet_id

from balance_sheet
)

select *
from surrogate_key
