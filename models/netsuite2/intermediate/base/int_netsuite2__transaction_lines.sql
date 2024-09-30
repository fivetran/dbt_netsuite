{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')) }}

with transaction_lines as (

    select *
    from {{ var('netsuite2_transaction_lines') }}
),

transaction_accounting_lines as (

    select *
    from {{ var('netsuite2_transaction_accounting_lines') }}
),

{% if var('netsuite2__multibook_accounting_enabled', false) %}
accounting_books as (

    select *
    from {{ var('netsuite2_accounting_books') }}
), 
{% endif %}

joined as (

    select 
        transaction_lines.*,
        transaction_accounting_lines.account_id,

        {% if var('netsuite2__multibook_accounting_enabled', false) %}
        transaction_accounting_lines.accounting_book_id,
        accounting_books.accounting_book_name,
        {% endif %}
        
        transaction_accounting_lines.exchange_rate,
        transaction_accounting_lines.amount,
        transaction_accounting_lines.credit_amount,
        transaction_accounting_lines.debit_amount,
        transaction_accounting_lines.paid_amount,
        transaction_accounting_lines.unpaid_amount,
        transaction_accounting_lines.is_posting

    from transaction_lines
    left join transaction_accounting_lines
        on transaction_lines.transaction_line_id = transaction_accounting_lines.transaction_line_id
        and transaction_lines.transaction_id = transaction_accounting_lines.transaction_id
        
    {% if var('netsuite2__multibook_accounting_enabled', false) %}
    left join accounting_books
        on accounting_books.accounting_book_id = transaction_accounting_lines.accounting_book_id

    union all

    select
        transaction_lines.*,
        transaction_accounting_lines.account_id,
        accounting_books.accounting_book_id,
        accounting_books.accounting_book_name,
        transaction_accounting_lines.exchange_rate,
        transaction_accounting_lines.amount,
        transaction_accounting_lines.credit_amount,
        transaction_accounting_lines.debit_amount,
        transaction_accounting_lines.paid_amount,
        transaction_accounting_lines.unpaid_amount,
        transaction_accounting_lines.is_posting

    from transaction_lines
    left join transaction_accounting_lines
        on transaction_lines.transaction_line_id = transaction_accounting_lines.transaction_line_id
        and transaction_lines.transaction_id = transaction_accounting_lines.transaction_id
    left join accounting_books
        on accounting_books.base_book_id = transaction_accounting_lines.accounting_book_id
    where accounting_books.base_book_id is not null
    {% endif %}

)

select *
from joined