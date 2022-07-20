{{ config(enabled=var('netsuite_data_model', 'netsuite') == 'netsuite') }}

with transactions_with_converted_amounts as (
    select * 
    from {{ ref('int_netsuite__transactions_with_converted_amounts') }}
), 

--Below is only used if income statement transaction detail columns are specified dbt_project.yml file.
{% if var('income_statement_transaction_detail_columns') != []%}
transaction_details as (
    select * 
    from {{ ref('netsuite__transaction_details') }}
), 
{% endif %}

accounts as (
    select * 
    from {{ var('netsuite_accounts') }}
), 

accounting_periods as (
    select * 
    from {{ var('netsuite_accounting_periods') }}
),

subsidiaries as (
    select * 
    from {{ var('netsuite_subsidiaries') }}
),

transaction_lines as (
    select * 
    from {{ var('netsuite_transaction_lines') }}
),

classes as (
    select * 
    from {{ var('netsuite_classes') }}
),

locations as (
    select * 
    from {{ var('netsuite_locations') }}
),

departments as (
    select * 
    from {{ var('netsuite_departments') }}
),

income_statement as (
    select
        reporting_accounting_periods.accounting_period_id as accounting_period_id,
        reporting_accounting_periods.ending_at as accounting_period_ending,
        reporting_accounting_periods.full_name as accounting_period_full_name,
        reporting_accounting_periods.name as accounting_period_name,
        lower(reporting_accounting_periods.is_adjustment) = 'yes' as is_accounting_period_adjustment,
        lower(reporting_accounting_periods.is_closed) = 'yes' as is_accounting_period_closed,
        accounts.name as account_name,
        accounts.type_name as account_type_name,
        accounts.account_id as account_id,
        accounts.account_number,
        subsidiaries.subsidiary_id,
        subsidiaries.full_name as subsidiary_full_name,
        subsidiaries.name as subsidiary_name,

        --The below script allows for accounts table pass through columns.
        {% if var('accounts_pass_through_columns') %}

        accounts.{{ var('accounts_pass_through_columns') | join (", accounts.")}} ,

        {% endif %}

        {{ dbt_utils.concat(['accounts.account_number',"'-'", 'accounts.name']) }} as account_number_and_name,
        classes.full_name as class_full_name,

        --The below script allows for classes table pass through columns.
        {% if var('classes_pass_through_columns') %}
        
        classes.{{ var('classes_pass_through_columns') | join (", classes.")}} ,

        {% endif %}

        locations.full_name as location_full_name,
        departments.full_name as department_full_name,

        --The below script allows for departments table pass through columns.
        {% if var('departments_pass_through_columns') %}
        
        departments.{{ var('departments_pass_through_columns') | join (", departments.")}} ,

        {% endif %}

        -converted_amount_using_transaction_accounting_period as converted_amount,
        transactions_with_converted_amounts.account_category as account_category,
        case when lower(accounts.type_name) = 'income' then 1
            when lower(accounts.type_name) = 'cost of goods sold' then 2
            when lower(accounts.type_name) = 'expense' then 3
            when lower(accounts.type_name) = 'other income' then 4
            when lower(accounts.type_name) = 'other expense' then 5
            else null
            end as income_statement_sort_helper

        --Below is only used if income statement transaction detail columns are specified dbt_project.yml file.
        {% if var('income_statement_transaction_detail_columns') %}

        , transaction_details.{{ var('income_statement_transaction_detail_columns') | join (", transaction_details.")}}

        {% endif %}
    
        
    from transactions_with_converted_amounts

    join transaction_lines as transaction_lines
        on transaction_lines.transaction_line_id = transactions_with_converted_amounts.transaction_line_id
            and transaction_lines.transaction_id = transactions_with_converted_amounts.transaction_id

    left join classes 
        on classes.class_id = transaction_lines.class_id

    left join locations
        on locations.location_id = transaction_lines.location_id

    left join departments 
        on departments.department_id = transaction_lines.department_id
    join accounts on accounts.account_id = transactions_with_converted_amounts.account_id

    join accounting_periods as reporting_accounting_periods 
        on reporting_accounting_periods.accounting_period_id = transactions_with_converted_amounts.reporting_accounting_period_id
    
    join subsidiaries
        on transactions_with_converted_amounts.subsidiary_id = subsidiaries.subsidiary_id

    --Below is only used if income statement transaction detail columns are specified dbt_project.yml file.
    {% if var('income_statement_transaction_detail_columns') != []%}
    join transaction_details
        on transaction_details.transaction_id = transactions_with_converted_amounts.transaction_id
        and transaction_details.transaction_line_id = transactions_with_converted_amounts.transaction_line_id
    {% endif %}

    where reporting_accounting_periods.fiscal_calendar_id  = (select fiscal_calendar_id from subsidiaries where parent_id is null)
        and transactions_with_converted_amounts.transaction_accounting_period_id = transactions_with_converted_amounts.reporting_accounting_period_id
        and transactions_with_converted_amounts.is_income_statement
)

select *
from income_statement
