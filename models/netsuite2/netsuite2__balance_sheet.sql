{{
    config(
        enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2'),
        materialized='table' if target.type in ('bigquery', 'databricks', 'spark') else 'incremental',
        partition_by = {'field': '_fivetran_synced_date', 'data_type': 'date', 'granularity': 'month'}
            if target.type not in ['spark', 'databricks'] else ['_fivetran_synced_date'],       
        cluster_by = ['transaction_id'],
        unique_key='balance_sheet_id',
        incremental_strategy = 'merge' if target.type in ('bigquery', 'databricks', 'spark') else 'delete+insert',
        file_format='delta'
    )
}}

with transactions_with_converted_amounts as (
    select * 
    from {{ref('int_netsuite2__tran_with_converted_amounts')}}

    {% if is_incremental() %}
    where _fivetran_synced_date >= {{ netsuite.netsuite_lookback(from_date='max(_fivetran_synced_date)', datepart='day', interval=var('lookback_window', 3)) }}
    {% endif %}
), 

--Below is only used if balance sheet transaction detail columns are specified dbt_project.yml file.
{% if var('balance_sheet_transaction_detail_columns') != []%}
transaction_details as (
    select * 
    from {{ ref('netsuite2__transaction_details') }}
), 
{% endif %}

accounts as (
    select * 
    from {{ ref('int_netsuite2__accounts') }}
), 

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

balance_sheet as ( 
    select
        transactions_with_converted_amounts.transaction_id,
        transactions_with_converted_amounts.transaction_line_id,
        transactions_with_converted_amounts.subsidiary_id,
        transactions_with_converted_amounts._fivetran_synced_date,
        subsidiaries.full_name as subsidiary_full_name,
        subsidiaries.name as subsidiary_name,
        subsidiaries_currencies.symbol as subsidiary_currency_symbol,

        {% if var('netsuite2__multibook_accounting_enabled', false) %}
        transactions_with_converted_amounts.accounting_book_id,
        transactions_with_converted_amounts.accounting_book_name,
        {% endif %}
        
        {% if var('netsuite2__using_to_subsidiary', false) and var('netsuite2__using_exchange_rate', true) %}
        transactions_with_converted_amounts.to_subsidiary_id,
        transactions_with_converted_amounts.to_subsidiary_name,
        transactions_with_converted_amounts.to_subsidiary_currency_symbol,
        {% endif %}

        reporting_accounting_periods.accounting_period_id as accounting_period_id,
        reporting_accounting_periods.ending_at as accounting_period_ending,
        reporting_accounting_periods.name as accounting_period_name,
        reporting_accounting_periods.is_adjustment as is_accounting_period_adjustment,
        reporting_accounting_periods.is_closed as is_accounting_period_closed,
        transactions_with_converted_amounts.account_category as account_category,
        case
        when (not accounts.is_balancesheet 
                and reporting_accounting_periods.fiscal_year_trunc = transaction_accounting_periods.fiscal_year_trunc 
                and reporting_accounting_periods.fiscal_calendar_id = transaction_accounting_periods.fiscal_calendar_id) then 'Net Income'
        when not accounts.is_balancesheet then 'Retained Earnings'
        else accounts.name
            end as account_name,
        case
        when (not accounts.is_balancesheet 
                and reporting_accounting_periods.fiscal_year_trunc = transaction_accounting_periods.fiscal_year_trunc 
                and reporting_accounting_periods.fiscal_calendar_id = transaction_accounting_periods.fiscal_calendar_id) then 'Net Income'
        when not accounts.is_balancesheet then 'Retained Earnings'
        else accounts.display_name
            end as account_display_name,
        case
        when (not accounts.is_balancesheet 
                and reporting_accounting_periods.fiscal_year_trunc = transaction_accounting_periods.fiscal_year_trunc 
                and reporting_accounting_periods.fiscal_calendar_id = transaction_accounting_periods.fiscal_calendar_id) then 'Net Income'
        when not accounts.is_balancesheet then 'Retained Earnings'
        when lower(accounts.special_account_type_id) = 'retearnings' then 'Retained Earnings'
        when lower(accounts.special_account_type_id) in ('cta-e', 'cumultransadj') then 'Cumulative Translation Adjustment'
        else accounts.type_name
            end as account_type_name,
        case
        when (not accounts.is_balancesheet 
                and reporting_accounting_periods.fiscal_year_trunc = transaction_accounting_periods.fiscal_year_trunc 
                and reporting_accounting_periods.fiscal_calendar_id = transaction_accounting_periods.fiscal_calendar_id) then 'net_income'
        when not accounts.is_balancesheet then 'retained_earnings'
        when lower(accounts.special_account_type_id) = 'retearnings' then 'retained_earnings'
        when lower(accounts.special_account_type_id) in ('cta-e', 'cumultransadj') then 'cumulative_translation_adjustment'
        else accounts.account_type_id
            end as account_type_id,
        case
        when not accounts.is_balancesheet then null
        else accounts.account_id
            end as account_id,
        case
        when not accounts.is_balancesheet then (select accounts.account_number from accounts where lower(accounts.special_account_type_id) = 'retearnings' limit 1)
        else accounts.account_number
            end as account_number,
        case
        when not accounts.is_balancesheet then false
        else accounts.is_eliminate
            end as is_account_intercompany,
        case
        when not accounts.is_balancesheet then false
        else accounts.is_leftside
            end as is_account_leftside 
        --The below script allows for accounts table pass through columns.
        {{ netsuite.persist_pass_through_columns(var('accounts_pass_through_columns', []), identifier='accounts') }},

        case
        when not accounts.is_balancesheet and lower(accounts.general_rate_type) in ('historical', 'average') then -converted_amount_using_transaction_accounting_period
        when not accounts.is_balancesheet then -converted_amount_using_reporting_month
        when accounts.is_balancesheet and not accounts.is_leftside and lower(accounts.general_rate_type) in ('historical', 'average') then -converted_amount_using_transaction_accounting_period
        when accounts.is_balancesheet and accounts.is_leftside and lower(accounts.general_rate_type) in ('historical', 'average') then converted_amount_using_transaction_accounting_period
        when accounts.is_balancesheet and not accounts.is_leftside then -converted_amount_using_reporting_month
        when accounts.is_balancesheet and accounts.is_leftside then converted_amount_using_reporting_month
        else 0
            end as converted_amount,

        case
        when not accounts.is_balancesheet then -unconverted_amount
        when accounts.is_balancesheet and not accounts.is_leftside then -unconverted_amount
        when accounts.is_balancesheet and accounts.is_leftside then unconverted_amount
        else 0
            end as transaction_amount,

        case
        when lower(accounts.account_type_id) = 'bank' then 1
        when lower(accounts.account_type_id) = 'acctrec' then 2
        when lower(accounts.account_type_id) = 'unbilledrec' then 3
        when lower(accounts.account_type_id) = 'othcurrasset' then 4
        when lower(accounts.account_type_id) = 'fixedasset' then 5
        when lower(accounts.account_type_id) = 'othasset' then 6
        when lower(accounts.account_type_id) = 'deferexpense' then 7
        when lower(accounts.account_type_id) = 'acctpay' then 8
        when lower(accounts.account_type_id) = 'credcard' then 9
        when lower(accounts.account_type_id) = 'othcurrliab' then 10
        when lower(accounts.account_type_id) = 'longtermliab' then 11
        when lower(accounts.account_type_id) = 'deferrevenue' then 12
        when lower(accounts.special_account_type_id) = 'retearnings' then 14
        when lower(accounts.special_account_type_id) in ('cta-e', 'cumultransadj') then 16
        when lower(accounts.account_type_id) = 'equity' then 13
        when (not accounts.is_balancesheet 
                and reporting_accounting_periods.fiscal_year_trunc = transaction_accounting_periods.fiscal_year_trunc
                and reporting_accounting_periods.fiscal_calendar_id = transaction_accounting_periods.fiscal_calendar_id) then 15
        when not accounts.is_balancesheet then 14
        else null
            end as balance_sheet_sort_helper

    --Below is only used if balance sheet transaction detail columns are specified dbt_project.yml file.
    {% if var('balance_sheet_transaction_detail_columns') %}
    
    , transaction_details.{{ var('balance_sheet_transaction_detail_columns') | join (", transaction_details.")}}

    {% endif %}

    from transactions_with_converted_amounts
    
    --Below is only used if balance sheet transaction detail columns are specified dbt_project.yml file.
    {% if var('balance_sheet_transaction_detail_columns') != []%}
    left join transaction_details
        on transaction_details.transaction_id = transactions_with_converted_amounts.transaction_id
        and transaction_details.transaction_line_id = transactions_with_converted_amounts.transaction_line_id

        {% if var('netsuite2__multibook_accounting_enabled', false) %}
        and transaction_details.accounting_book_id = transactions_with_converted_amounts.accounting_book_id
        {% endif %}

        {% if var('netsuite2__using_to_subsidiary', false) and var('netsuite2__using_exchange_rate', true) %}
        and transaction_details.to_subsidiary_id = transactions_with_converted_amounts.to_subsidiary_id
        {% endif %}
    {% endif %}


    left join accounts 
        on accounts.account_id = transactions_with_converted_amounts.account_id

    left join accounting_periods as reporting_accounting_periods 
        on reporting_accounting_periods.accounting_period_id = transactions_with_converted_amounts.reporting_accounting_period_id

    left join accounting_periods as transaction_accounting_periods 
        on transaction_accounting_periods.accounting_period_id = transactions_with_converted_amounts.transaction_accounting_period_id

    left join subsidiaries
        on subsidiaries.subsidiary_id = transactions_with_converted_amounts.subsidiary_id

    left join currencies subsidiaries_currencies
        on subsidiaries_currencies.currency_id = subsidiaries.currency_id

    where reporting_accounting_periods.fiscal_calendar_id = (select fiscal_calendar_id from subsidiaries where parent_id is null)
        and transaction_accounting_periods.fiscal_calendar_id = (select fiscal_calendar_id from subsidiaries where parent_id is null)
        and (accounts.is_balancesheet
        or transactions_with_converted_amounts.is_income_statement)

    union all

    select
        transactions_with_converted_amounts.transaction_id,
        transactions_with_converted_amounts.transaction_line_id,
        transactions_with_converted_amounts.subsidiary_id,
        transactions_with_converted_amounts._fivetran_synced_date,
        subsidiaries.full_name as subsidiary_full_name,
        subsidiaries.name as subsidiary_name,
        subsidiaries_currencies.symbol as subsidiary_currency_symbol,

        {% if var('netsuite2__multibook_accounting_enabled', false) %}
        transactions_with_converted_amounts.accounting_book_id,
        transactions_with_converted_amounts.accounting_book_name,
        {% endif %}

        {% if var('netsuite2__using_to_subsidiary', false) and var('netsuite2__using_exchange_rate', true) %}
        transactions_with_converted_amounts.to_subsidiary_id,
        transactions_with_converted_amounts.to_subsidiary_name,
        transactions_with_converted_amounts.to_subsidiary_currency_symbol,
        {% endif %}
        
        reporting_accounting_periods.accounting_period_id as accounting_period_id,
        reporting_accounting_periods.ending_at as accounting_period_ending,
        reporting_accounting_periods.name as accounting_period_name,
        reporting_accounting_periods.is_adjustment as is_accounting_period_adjustment,
        reporting_accounting_periods.is_closed as is_accounting_period_closed,
        'Equity' as account_category,
        'Cumulative Translation Adjustment' as account_name,
        'Cumulative Translation Adjustment' as account_display_name,
        'Cumulative Translation Adjustment' as account_type_name,
        'cumulative_translation_adjustment' as account_type_id,
        null as account_id,
        (select accounts.account_number from accounts where lower(accounts.special_account_type_id) = 'cumultransadj' limit 1) as account_number,
        false as is_account_intercompany,
        false as is_account_leftside,

        {% if var('accounts_pass_through_columns') %}
        {% for field in var('accounts_pass_through_columns') %}
            null as {{ field.alias if field.alias else field.name }},
        {% endfor %}
        {% endif %}

        case
        when lower(accounts.general_rate_type) in ('historical', 'average') then converted_amount_using_transaction_accounting_period
        else converted_amount_using_reporting_month
            end as converted_amount,

        unconverted_amount as transaction_amount,

        16 as balance_sheet_sort_helper

        --Below is only used if balance sheet transaction detail columns are specified dbt_project.yml file.
        {% if var('balance_sheet_transaction_detail_columns') %}

        , transaction_details.{{ var('balance_sheet_transaction_detail_columns') | join (", transaction_details.")}}

        {% endif %}

    from transactions_with_converted_amounts

    --Below is only used if balance sheet transaction detail columns are specified dbt_project.yml file.
    {% if var('balance_sheet_transaction_detail_columns') != []%}
    left join transaction_details
        on transaction_details.transaction_id = transactions_with_converted_amounts.transaction_id
        and transaction_details.transaction_line_id = transactions_with_converted_amounts.transaction_line_id
        
        {% if var('netsuite2__multibook_accounting_enabled', false) %}
        and transaction_details.accounting_book_id = transactions_with_converted_amounts.accounting_book_id
        {% endif %}

        {% if var('netsuite2__using_to_subsidiary', false) and var('netsuite2__using_exchange_rate', true) %}
        and transaction_details.to_subsidiary_id = transactions_with_converted_amounts.to_subsidiary_id
        {% endif %}
    {% endif %}

    left join accounts
        on accounts.account_id = transactions_with_converted_amounts.account_id

    left join accounting_periods as reporting_accounting_periods 
        on reporting_accounting_periods.accounting_period_id = transactions_with_converted_amounts.reporting_accounting_period_id

    left join subsidiaries
        on subsidiaries.subsidiary_id = transactions_with_converted_amounts.subsidiary_id

    left join currencies subsidiaries_currencies
        on subsidiaries_currencies.currency_id = subsidiaries.currency_id

    where reporting_accounting_periods.fiscal_calendar_id = (select fiscal_calendar_id from subsidiaries where parent_id is null)
        and (accounts.is_balancesheet
        or transactions_with_converted_amounts.is_income_statement)
    ),

    surrogate_key as ( 
    {% set surrogate_key_fields = ['transaction_line_id', 'transaction_id', 'accounting_period_id', 'account_name', 'account_id'] %}
    {% do surrogate_key_fields.append('to_subsidiary_id') if var('netsuite2__using_to_subsidiary', false) and var('netsuite2__using_exchange_rate', true) %}
    {% do surrogate_key_fields.append('accounting_book_id') if var('netsuite2__multibook_accounting_enabled', false) %}

    select 
        *,
        {{ dbt_utils.generate_surrogate_key(surrogate_key_fields) }} as balance_sheet_id

    from balance_sheet
)

select *
from surrogate_key
