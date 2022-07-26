{{ config(enabled=var('netsuite_data_model', 'netsuite') == var('netsuite_data_model_override','netsuite2')) }}

with consolidated_exchange_rates as (

    select *
    from {{ var('netsuite2_consolidated_exchange_rates') }}
),

accounting_book_subsidiaries as (

    select *
    from {{ var('netsuite2_accounting_book_subsidiaries') }}
),

joined as (

    select 
        consolidated_exchange_rates.*,
        accounting_book_subsidiaries.accounting_book_id

    from consolidated_exchange_rates
    left join accounting_book_subsidiaries
        on consolidated_exchange_rates.to_subsidiary_id = accounting_book_subsidiaries.subsidiary_id
)

select *
from joined