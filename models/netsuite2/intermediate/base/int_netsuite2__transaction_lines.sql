{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')) }}

with transaction_lines as (

    select *
    from {{ var('netsuite2_transaction_lines') }}
),

transaction_accounting_lines as (

    select *
    from {{ var('netsuite2_transaction_accounting_lines') }}
),

joined as (

    select 
        transaction_lines.*,
        transaction_accounting_lines.account_id,
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
)

select *
from joined