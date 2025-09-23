select
    vendor_subsidiary_relationship.*,
    vendors.alt_name as vendor_alt_name,
    currencies.symbol as primary_currency_sumbol,
    subsidiaries.name as subsidiary_name

    from {{ ref('stg_netsuite2__vendor_subsidiary_relationship') }} vendor_subsidiary_relationship

    left join {{ ref('stg_netsuite2__vendors') }} vendors
        on vendor_subsidiary_relationship.vendor_id = vendors.vendor_id

    left join {{ ref('stg_netsuite2__currencies') }} currencies
        on vendor_subsidiary_relationship.primary_currency_id = currencies.currency_id

    left join {{ ref('stg_netsuite2__subsidiaries') }} subsidiaries
        on vendor_subsidiary_relationship.subsidiary_id = subsidiaries.subsidiary_id

