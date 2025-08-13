{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')) }}

with base as (

    select * 
    from {{ ref('stg_netsuite2__transaction_accounting_lines_tmp') }}
),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_netsuite2__transaction_accounting_lines_tmp')),
                staging_columns=get_transactionaccountingline_columns()
            )
        }}
    from base
),

final as (
    
    select 
        _fivetran_deleted,
        _fivetran_synced,
        transaction as transaction_id,
        transactionline as transaction_line_id,
        accountingbook as accounting_book_id,
        account as account_id,
        posting = 'T' as is_posting,
        exchangerate as exchange_rate,
        amount,
        credit as credit_amount,
        debit as debit_amount,
        netamount as net_amount,
        amountpaid as paid_amount,
        amountunpaid as unpaid_amount
    from fields
)

select *
from final
