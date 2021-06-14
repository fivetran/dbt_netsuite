# Netsuite ([docs](https://dbt-netsuite.netlify.app/))

This package models Netsuite data from [Fivetran's connector](https://fivetran.com/docs/applications/netsuite). It uses data in the format described by [this ERD](https://fivetran.com/docs/applications/netsuite-suiteanalytics#schemainformation).

The main focus of this package is to enable users to insights into their netsuite data that can be used for financial statement reporting and deeper transactional analysis. This is acheived by the following:
- Recreating both the balance sheet and income statement
- Recreating commonly used data by using the transaction lines as the base table and joining other data

## Models
This package contains transformation models, designed to work simultaneously with our [netsuite source package](https://github.com/fivetran/dbt_netsuite_source). A dependency on the source package is declared in this package's `packages.yml` file, so it will automatically download when you run `dbt deps`. The primary outputs of this package are described below. Intermediate models are used to create these output models.
| **model**                | **description**                                                                                                                                |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| [netsuite__balance_sheet](https://github.com/fivetran/dbt_netsuite/blob/master/models/netsuite__balance_sheet.sql)             | All lines necessary to generate a balance sheet (converted for the appropriate exchange rate of the parent subsidiary). Non balance sheet transactions are categorized as either Retained Earnings or Net Income. |
| [netsuite__income_statement](https://github.com/fivetran/dbt_netsuite/blob/master/models/netsuite__income_statement.sql)       | All lines necessary to generate an income statement (converted for the appropriate exchange rate of the parent subsidiary). Department, class, and location information are included for additional reporting functionality. |
| [netsuite__transaction_details](https://github.com/fivetran/dbt_netsuite/blob/master/models/netsuite__transaction_details.sql) | All transactions with the associated accounting period, account and subsidiary information. Where applicable, you can also see data about the customer, location, item, vendor, and department. |

## Installation Instructions
Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions, or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.

## Configuration
By default, this package looks for your netsuite data in the `netsuite` schema of your [target database](https://docs.getdbt.com/docs/running-a-dbt-project/using-the-command-line-interface/configure-your-profile). 
If this is not where your netsuite data is, add the below configuration to your `dbt_project.yml` file.

```yml
# dbt_project.yml

...
config-version: 2

vars:
    connector_database: your_database_name
    connector_schema: your_schema_name
```
This package allows users to add additional columns to the final model tables. 
Columns passed through must be present in the downstream source tables. See 
below for an example of how the passthrough columns should be configured within your `dbt_project.yml` file.

```yml
# dbt_project.yml

...
vars:
  accounts_pass_through_columns: ['new_custom_field', 'we_can_account_for_that']
  classes_pass_through_columns: ['class_is_in_session', 'pass_through_additional_fields_here']
  departments_pass_through_columns: ['department_custom_fields']
  transactions_pass_through_columns: ['transactions_can_be_custom','pass_this_transaction_field_on']
  transaction_lines_pass_through_columns: ['transaction_lines_field']
```

Additionally, this package allows users to pass columns from the `netsuite__transaction_details` table into
the `netsuite__balance_sheet` and `netsuite__income_statement` tables. See below for an example
of how to passthrough transaction detail columns into the respective balance sheet and income statement final tables
within your `dbt_project.yml` file.

```yml
# dbt_project.yml

...
vars:
  netsuite:
    balance_sheet_transaction_detail_columns: ['company_name','vendor_name']
    income_statement_transaction_detail_columns: ['is_account_intercompany','location_name']

```

### Changing the Build Schema
By default this package will build the Netsuite staging models within a schema titled (<target_schema> + `_stg_netsuite`) and the Netsuite final models with a schema titled (<target_schema> + `_netsuite`) in your target database. If this is not where you would like your modeled Netsuite data to be written to, add the following configuration to your `dbt_project.yml` file:

```yml
# dbt_project.yml 

...
models:
  netsuite:
    +schema: my_new_schema_name # leave blank for just the target_schema
  netsuite_source:
    +schema: my_new_schema_name # leave blank for just the target_schema
```


## Contributions
Don't see a model or specific metric you would have liked to be included? Notice any bugs when installing 
and running the package? If so, we highly encourage and welcome contributions to this package! 
Please create issues or open PRs against `master`. Check out [this post](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657) on the best workflow for contributing to a package.

## Database Support
This package has been tested on BigQuery, Snowflake and Redshift.

## Resources:
- Provide [feedback](https://www.surveymonkey.com/r/DQ7K7WW) on our existing dbt packages or what you'd like to see next
- Have questions or feedback, or need help? Book a time during our office hours [here](https://calendly.com/fivetran-solutions-team/fivetran-solutions-team-office-hours) or shoot us an email at solutions@fivetran.com
- Find all of Fivetran's pre-built dbt packages in our [dbt hub](https://hub.getdbt.com/fivetran/)
- Learn how to orchestrate dbt transformations with Fivetran [here](https://fivetran.com/docs/transformations/dbt)
- Learn more about Fivetran overall [in our docs](https://fivetran.com/docs)
- Check out [Fivetran's blog](https://fivetran.com/blog)
- Learn more about dbt [in the dbt docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](http://slack.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the dbt blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices
