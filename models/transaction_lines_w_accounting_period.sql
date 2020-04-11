with transactions as (
    select * from {{ source('netsuite', 'transactions') }}
), 
transaction_lines as (
    select * from {{ source('netsuite', 'transaction_lines') }}
),

transaction_lines_w_accounting_period as ( -- transaction line totals, by accounts, accounting period and subsidiary
  select
    transaction_lines.transaction_id,
    transaction_lines.transaction_line_id,
    transaction_lines.subsidiary_id,
    transaction_lines.account_id,
    transactions.accounting_period_id as transaction_accounting_period_id,
    coalesce(transaction_lines.amount, 0) as unconverted_amount
  from transaction_lines
  join transactions on transactions.transaction_id = transaction_lines.transaction_id
  where not transactions._fivetran_deleted
    and lower(transactions.transaction_type) != 'revenue arrangement'
    and lower(non_posting_line) != 'yes'
)

select * from transaction_lines_w_accounting_period    