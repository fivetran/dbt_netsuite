### Fivetran's Net Suite Analytics
This [dbt package](https://docs.getdbt.com/docs/package-management):
* Recreates both the balance sheet and income statement
* Using transaction lines as the base table, other data is joined to recreate commonly used data

### Requirements
- [x] A Fivetran NetSuite Analytics connector, with the following tables synced:
    - accounts
    - accounting_periods
    - accounting_books
    - consolidated_exchange_rates
    - currencies
    - customers
    - classes
    - departments
    - expense_accounts
    - income_accounts
    - items
    - locations, partners
    - transaction_lines
    - transactions
    - subsidiaries
    - vendors


### Installation instructions
1. Include this package in your `packages.yml` -- check [here](https://hub.getdbt.com/fivetran/netsuite/latest/)
for installation instructions.

2. Check the location of your NetSuite data — if it is in a schema named `netsuite` and in the same database as your target database, no further modification is required. If it is in a different database or schema:
    a. Copy the `src_netsuite.yml` [file](models/src_netsuite.yml) into your own project
    b. Uncomment the `schema` the `database` configurations, updating the values for your own data source.¹

3. Execute `dbt run` – the NetSuite models will get built as part of your run!
4. Execute `dbt test` — these models include tests to check the output of the models.

### Database support
These package can be used on Snowflake, BigQuery and Redshift.


### Contributing ###

Contributions are welcome. To contribute:

* fork this repo,
* make and test changes, and
* submit a PR.
All contributions must be widely relevant to NetSuite customers and not contain logic specific to a given business.

----
¹In dbt v0.17.0 (currently unreleased) it will be possible to add the following to your own `dbt_project.yml` file:
```yml
sources:
  vars:
    netsuite_database: raw
    netsuite_schema: raw
```

When this functionality is released, it will become easier to install and configure packages that include sources.
