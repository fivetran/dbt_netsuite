# NetSuite SuiteAnalytics

This package models NetSuite SuiteAnalytics data from [Fivetran's connector](https://fivetran.com/docs/applications/netsuite-suiteanalytics). It uses data in the format described by [this ERD](https://docs.google.com/presentation/d/1sgWiu5PMdFdBZgWtQ-aWqrym3dNcZvOtBNKT0q084pI/edit).

This [dbt package](https://docs.getdbt.com/docs/package-management):
* Recreates both the balance sheet and income statement
* Recreates commonly used data by using the transaction lines as the base table and joining other data

## Requirements
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
    - locations
    - partners
    - transaction_lines
    - transactions
    - subsidiaries
    - vendors
    - vendor_types


## Installation instructions

1. Include this package in your `packages.yml` - check [our installation guide](https://hub.getdbt.com/fivetran/netsuite/latest/)
for installation instructions.

2. Check the location of your NetSuite data — if it is in a schema named `netsuite` and in the same database as your target database, no further modification is required. If it is in a different database or schema:
    1. Copy the `src_netsuite.yml` [file](models/src_netsuite.yml) into your own project.
    2. Uncomment the `schema` and the `database` configurations, updating the values for your own data source.¹

3. Execute `dbt run` – the NetSuite models will get built as part of your run!
4. Execute `dbt test` — these models include tests to check the output of the models.

## Database support
These package can be used on Snowflake, BigQuery, and Redshift.


## Contributions
Additional contributions to this package are very welcome! Please create issues
or open PRs against `master`. Check out 
[this post](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657) 
on the best workflow for contributing to a package.

All contributions must be widely relevant to NetSuite customers and not contain logic specific to a given business.

## Resources:
- Provide [feedback](https://www.surveymonkey.com/r/DQ7K7WW) on our existing dbt packages or what you'd like to see next
- Learn more about Fivetran [in the Fivetran docs](https://fivetran.com/docs)
- Check out [Fivetran's blog](https://fivetran.com/blog)
- Learn more about dbt [in the dbt docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](http://slack.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the dbt blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices
