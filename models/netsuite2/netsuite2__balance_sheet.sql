{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')) }}

with transactions_with_converted_amounts as (
    select * 
    from {{ref('int_netsuite2__tran_with_converted_amounts')}}
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
    from {{ var('netsuite2_subsidiaries') }}
),

balance_sheet as ( 
  select
    transactions_with_converted_amounts.transaction_id,
    transactions_with_converted_amounts.transaction_line_id,
    transactions_with_converted_amounts.accounting_book_id,
    reporting_accounting_periods.accounting_period_id as accounting_period_id,
    reporting_accounting_periods.ending_at as accounting_period_ending,
    reporting_accounting_periods.name as accounting_period_name,
    reporting_accounting_periods.is_adjustment as is_accounting_period_adjustment,
    reporting_accounting_periods.is_closed as is_accounting_period_closed,
    transactions_with_converted_amounts.account_category as account_category,
    case
      when (not accounts.is_balancesheet 
            and {{ dbt.date_trunc('year', 'reporting_accounting_periods.starting_at') }} = {{ dbt.date_trunc('year', 'transaction_accounting_periods.starting_at') }} 
            and reporting_accounting_periods.fiscal_calendar_id = transaction_accounting_periods.fiscal_calendar_id) then 'Net Income'
      when not accounts.is_balancesheet then 'Retained Earnings'
      else accounts.name
        end as account_name,
    case
      when (not accounts.is_balancesheet 
            and {{ dbt.date_trunc('year', 'reporting_accounting_periods.starting_at') }} = {{ dbt.date_trunc('year', 'transaction_accounting_periods.starting_at') }} 
            and reporting_accounting_periods.fiscal_calendar_id = transaction_accounting_periods.fiscal_calendar_id) then 'Net Income'
      when not accounts.is_balancesheet then 'Retained Earnings'
      when lower(accounts.special_account_type_id) = 'retearnings' then 'Retained Earnings'
      when lower(accounts.special_account_type_id) IN ('cta-e', 'cumultransadj') then 'Cumulative Translation Adjustment'
      else accounts.type_name
        end as account_type_name,
    case
      when (not accounts.is_balancesheet 
            and {{ dbt.date_trunc('year', 'reporting_accounting_periods.starting_at') }} = {{ dbt.date_trunc('year', 'transaction_accounting_periods.starting_at') }} 
            and reporting_accounting_periods.fiscal_calendar_id = transaction_accounting_periods.fiscal_calendar_id) then 'net_income'
      when not accounts.is_balancesheet then 'retained_earnings'
      when lower(accounts.special_account_type_id) = 'retearnings' then 'retained_earnings'
      when lower(accounts.special_account_type_id) IN ('cta-e', 'cumultransadj') then 'cumulative_translation_adjustment'
      else accounts.account_type_id
        end as account_type_id,
    case
      when not accounts.is_balancesheet then null
      else accounts.account_id
        end as account_id,
    case
      when not accounts.is_balancesheet then null
      else accounts.account_number
        end as account_number
    
    --The below script allows for accounts table pass through columns.
    {{ fivetran_utils.persist_pass_through_columns('accounts_pass_through_columns', identifier='accounts') }},

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
      when lower(accounts.special_account_type_id) IN ('cta-e', 'cumultransadj') then 16
      when lower(accounts.account_type_id) = 'equity' then 13
      when (not accounts.is_balancesheet 
            and {{ dbt.date_trunc('year', 'reporting_accounting_periods.starting_at') }} = {{ dbt.date_trunc('year', 'transaction_accounting_periods.starting_at') }} 
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
      and transaction_details.accounting_book_id = transactions_with_converted_amounts.accounting_book_id
  {% endif %}


  left join accounts 
    on accounts.account_id = transactions_with_converted_amounts.account_id

  left join accounting_periods as reporting_accounting_periods 
    on reporting_accounting_periods.accounting_period_id = transactions_with_converted_amounts.reporting_accounting_period_id

  left join accounting_periods as transaction_accounting_periods 
    on transaction_accounting_periods.accounting_period_id = transactions_with_converted_amounts.transaction_accounting_period_id

  where reporting_accounting_periods.fiscal_calendar_id = (select fiscal_calendar_id from subsidiaries where parent_id is null)
    and transaction_accounting_periods.fiscal_calendar_id = (select fiscal_calendar_id from subsidiaries where parent_id is null)
    and (accounts.is_balancesheet
      or transactions_with_converted_amounts.is_income_statement)

  union all

  select
    transactions_with_converted_amounts.transaction_id,
    transactions_with_converted_amounts.transaction_line_id,
    transactions_with_converted_amounts.accounting_book_id,
    reporting_accounting_periods.accounting_period_id as accounting_period_id,
    reporting_accounting_periods.ending_at as accounting_period_ending,
    reporting_accounting_periods.name as accounting_period_name,
    reporting_accounting_periods.is_adjustment as is_accounting_period_adjustment,
    reporting_accounting_periods.is_closed as is_accounting_period_closed,
    'Equity' as account_category,
    'Cumulative Translation Adjustment' as account_name,
    'Cumulative Translation Adjustment' as account_type_name,
    'cumulative_translation_adjustment' as account_type_id,
    null as account_id,
    null as account_number,

    {% if var('accounts_pass_through_columns') %}
      {% for field in var('accounts_pass_through_columns') %}
        null as {{ field.alias if field.alias else field.name }},
      {% endfor %}
    {% endif %}

    case
      when lower(account_category) = 'equity' or is_income_statement then converted_amount_using_transaction_accounting_period
      else converted_amount_using_reporting_month
        end as converted_amount,
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
      and transaction_details.accounting_book_id = transactions_with_converted_amounts.accounting_book_id
  {% endif %}

  left join accounts
    on accounts.account_id = transactions_with_converted_amounts.account_id

  left join accounting_periods as reporting_accounting_periods 
    on reporting_accounting_periods.accounting_period_id = transactions_with_converted_amounts.reporting_accounting_period_id
    
  where reporting_accounting_periods.fiscal_calendar_id = (select fiscal_calendar_id from subsidiaries where parent_id is null)
    and (accounts.is_balancesheet
      or transactions_with_converted_amounts.is_income_statement)
)

select *
from balance_sheet