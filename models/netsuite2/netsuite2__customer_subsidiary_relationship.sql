select
    customer_subsidiary_relationship.*,
    customers.entity_id as customer_entity_id,
    customers.alt_name as customer_alt_name,
    currencies.symbol as primary_currency_sumbol,
    subsidiaries.name as subsidiary_name

    from {{ ref('stg_netsuite2__customer_subsidiary_relationship') }} customer_subsidiary_relationship

    left join {{ ref('stg_netsuite2__customers') }} customers
        on customer_subsidiary_relationship.customer_id = customers.customer_id

    left join {{ ref('stg_netsuite2__currencies') }} currencies
        on customer_subsidiary_relationship.primary_currency_id = currencies.currency_id

    left join {{ ref('stg_netsuite2__subsidiaries') }} subsidiaries
        on customer_subsidiary_relationship.subsidiary_id = subsidiaries.subsidiary_id

