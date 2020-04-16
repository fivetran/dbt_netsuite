### Fivetran's Netsuite SuiteAnalytics
This [dbt package](https://docs.getdbt.com/docs/package-management):
* Recreates both the balance sheet and income statement
* Using transaction lines as the base table, other data is joined to recreate commonly used data

### Requirements
* A Fivetran Netsuite SuiteAnalytics connector
* To have synced the following Netsuite tables: To have synced at least the following tables: accounts, accounting_periods,accounting_books,consolidated_exchange_rates, currencies, customers, classes, departments, expense_accounts, income_accounts, items, locations, partners, transaction_lines, transactions, subsidiaries, vendors


### Installation instructions
1. Include this package in your `packages.yml` -- check [here](https://hub.getdbt.com/fivetran/netsuite/latest/)
for installation instructions.

2. Add this to your `dbt_project.yml` and fill in for your company:

```

schema_name - this is currently set to a default value of "netsuite".  Please update if this does not reflect your schema name.

```

3. Execute `dbt run` – the Netsuite models will get built as part of your run!

### Installation instructions v2.
Is your schema named `netsuite`?
  - Yes: OK great
  - No: You'll need to override the default source schema (can you rename your schema?). To do this there are two options:
      Opt 1. Use the CLI method to override a schema name only: dbt run --vars '{"netsuite_schema": "my_schema"}'
      Opt 2. Add the `src_netsuite` file to your own project and edit as required (note that this may cause some strangeness in your documentation)

Is your schema in the same database as your `target.database`?
  - (as above)

Are the freshness parameters acceptable?
  - If not: add the `src_netsuite.yml` file to your project and update them


### Database support
These package can be used on Snowflake, BigQuery and Redshift.


### Contributing ###

Contributions are welcome. To contribute:

* fork this repo,
* make and test changes, and
* submit a PR.
All contributions must be widely relevant to Netsuite customers and not contain logic specific to a given business.
