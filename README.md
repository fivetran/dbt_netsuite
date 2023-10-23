<p align="center">
    <a alt="License"
        href="https://github.com/fivetran/dbt_netsuite/blob/main/LICENSE">
        <img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" /></a>
    <a alt="dbt-core">
        <img src="https://img.shields.io/badge/dbt_Core™_version->=1.3.0_,<2.0.0-orange.svg" /></a>
    <a alt="Maintained?">
        <img src="https://img.shields.io/badge/Maintained%3F-yes-green.svg" /></a>
    <a alt="PRs">
        <img src="https://img.shields.io/badge/Contributions-welcome-blueviolet" /></a>
    <a alt="Fivetran Quickstart Compatible"
        href="https://fivetran.com/docs/transformations/dbt/quickstart">
        <img src="https://img.shields.io/badge/Fivetran_Quickstart_Compatible%3F-yes-green.svg" /></a>
</p>

# Netsuite Transformation dbt Package ([Docs](https://fivetran.github.io/dbt_netsuite/))
# 📣 What does this dbt package do?
- Produces modeled tables that leverage Netsuite data from [Fivetran's connector](https://fivetran.com/docs/applications/netsuite) in the format described by [this ERD](https://fivetran.com/docs/applications/netsuite#schemainformation) and builds off the output of our [Netsuite source package](https://github.com/fivetran/dbt_netsuite_source).
- Enables users to insights into their netsuite data that can be used for financial statement reporting and deeper transactional analysis. This is achieved by the following:
    - Recreating both the balance sheet and income statement
    - Recreating commonly used data by using the transaction lines as the base table and joining other data
- Generates a comprehensive data dictionary of your source and modeled Netsuite data through the [dbt docs site](https://fivetran.github.io/dbt_netsuite/).

<!--section="netsuite_transformation_model"-->
The following table provides a detailed list of all models materialized within this package by default. 
> TIP: See more details about these models in the package's [dbt docs site](https://fivetran.github.io/dbt_netsuite/#!/overview?g_v=1&g_e=seeds).

| **Model**                | **Description**                                                                                                                                |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| [netsuite__transaction_details](https://fivetran.github.io/dbt_netsuite/#!/model/model.netsuite.netsuite__transaction_details) or [netsuite2__transaction_details](https://fivetran.github.io/dbt_netsuite/#!/model/model.netsuite.netsuite2__transaction_details)             | All transactions with the associated accounting period, account and subsidiary information. Where applicable, you can also see data about the customer, location, item, vendor, and department. |
| [netsuite__income_statement](https://fivetran.github.io/dbt_netsuite/#!/model/model.netsuite.netsuite__income_statement) or [netsuite2__income_statement](https://fivetran.github.io/dbt_netsuite/#!/model/model.netsuite.netsuite2__income_statement)             | All transaction lines necessary to generate an income statement (converted for the appropriate exchange rate of the parent subsidiary). Department, class, and location information are included for additional reporting functionality. |
| [netsuite__balance_sheet](https://fivetran.github.io/dbt_netsuite/#!/model/model.netsuite.netsuite__balance_sheet) or [netsuite2__balance_sheet](https://fivetran.github.io/dbt_netsuite/#!/model/model.netsuite.netsuite2__balance_sheet)            | All transaction lines necessary to generate a balance sheet (converted for the appropriate exchange rate of the parent subsidiary). Non balance sheet transactions are categorized as either Retained Earnings or Net Income. |
<!--section-end-->


# 🎯 How do I use the dbt package?
## Step 1: Prerequisites
To use this dbt package, you must have At least either one Fivetran **Netsuite** (netsuite.com) or **Netsuite2** (netsuite2) connector syncing the respective tables to your destination:
### Netsuite.com
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

### Netsuite2
- account
- accounttype
- accountingbooksubsidiary
- accountingperiodfiscalcalendar
- accountingperiod
- accountingbook
- consolidatedexchangerate
- currency
- customer
- classification
- department
- entity
- entityaddress
- item
- item
- job
- location
- locationmainaddress
- transactionaccountingline
- transactionline
- transaction
- subsidiary
- vendor
- vendorcategory

### Database Compatibility
This package is compatible with either a **BigQuery**, **Snowflake**, **Redshift**, **PostgreSQL**, or **Databricks** destination.

### Databricks dispatch configuration
If you are using a Databricks destination with this package, you must add the following (or a variation of the following) dispatch configuration within your `dbt_project.yml`. This is required in order for the package to accurately search for macros within the `dbt-labs/spark_utils` then the `dbt-labs/dbt_utils` packages respectively.
```yml
dispatch:
  - macro_namespace: dbt_utils
    search_order: ['spark_utils', 'dbt_utils']
```
Do **NOT** include the `netsuite_source` package in this file. The transformation package itself has a dependency on it and will install the source package as well. 

## Step 2: Install the package
Include the following netsuite package version in your `packages.yml` file:
> TIP: Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.
```yaml
packages:
  - package: fivetran/netsuite
    version: [">=0.11.0", "<0.12.0"]
```
## Step 3: Define Netsuite.com or Netsuite2 Source
As of April 2022 Fivetran made available a new Netsuite connector which leverages the Netsuite2 endpoint opposed to the original Netsuite.com endpoint. This package is designed to run for either or, not both. By default the `netsuite_data_model` variable for this package is set to the original `netsuite` value which runs the netsuite.com version of the package. If you would like to run the package on Netsuite2 data, you may adjust the `netsuite_data_model` variable to run the `netsuite2` version of the package.
```yml
vars:
    netsuite_data_model: netsuite2 #netsuite by default
```

## Step 4: Define database and schema variables
By default, this package runs using your destination and the `netsuite` schema. If this is not where your Netsuite data is (for example, if your netsuite schema is named `netsuite_fivetran`), add the following configuration to your root `dbt_project.yml` file:

```yml
vars:
    netsuite_database: your_destination_name
    netsuite_schema: your_schema_name 
```

## Step 5: Disable models for non-existent sources (Netsuite2 only)
It's possible that your Netsuite connector does not sync every table that this package expects. If your syncs exclude certain tables, it is because you either don't use that feature in Netsuite or actively excluded some tables from your syncs. To disable the corresponding functionality in the package, you must add the relevant variables. By default, all variables are assumed to be true. Add variables for only the tables you would like to disable:
```yml
vars:
    netsuite2__multibook_accounting_enabled: false # True by default. Disable `accountingbooksubsidiary` and `accountingbook` if you are not using the Multi-Book Accounting feature
    netsuite2__using_exchange_rate: false #True by default. Disable `exchange_rate` if you don't utilize exchange rates. If you set this variable to false, ensure it is scoped globally so that the `netsuite_source` package can access it as well.
    netsuite2__using_vendor_categories: false # True by default. Disable `vendorcategory` if you don't categorize your vendors
    netsuite2__using_jobs: false # True by default. Disable `job` if you don't use jobs
```
> **Note**: The Netsuite dbt package currently only supports disabling transforms of [Multi-Book Accounting](https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/book_3831565332.html) related tables (`accountingbooksubsidiary` and `accountingbook`) and the `vendorcategory` and `job` source tables. Please create an issue to request additional tables and/or [features](https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/bridgehead_N233872.html) to exclude. 
> 
> To determine if a table or field is activated by a feature, access the [Records Catalog](https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/article_159367781370.html).

## (Optional) Step 6: Additional configurations
<details><summary>Expand for configurations</summary>

### Passing Through Additional Fields
This package includes all source columns defined in the macros folder. To add additional columns to this package, do so by adding our pass-through column variables to your `dbt_project.yml` file:

```yml
vars:
    accounts_pass_through_columns: 
        - name: "new_custom_field"
          alias: "custom_field"
    classes_pass_through_columns: 
        - name: "this_field"
    departments_pass_through_columns: 
        - name: "unique_string_field"
          alias: "field_id"
          transform_sql: "cast(field_id as string)"
    transactions_pass_through_columns: 
        - name: "that_field"
    transaction_lines_pass_through_columns: 
        - name: "other_id"
          alias: "another_id"
          transform_sql: "cast(another_id as int64)"
    customers_pass_through_columns: 
        - name: "customer_custom_field"
          alias: "customer_field"
    locations_pass_through_columns: 
        - name: "location_custom_field"
    subsidiaries_pass_through_columns: 
        - name: "sub_field"
          alias: "subsidiary_field"
    consolidated_exchange_rates_pass_through_columns: 
        - name: "consolidate_this_field"
```

### Passing Through Transaction Detail Fields
Additionally, this package allows users to pass columns from the `netsuite__transaction_details` table into
the `netsuite__balance_sheet` and `netsuite__income_statement` tables. See below for an example
of how to passthrough transaction detail columns into the respective balance sheet and income statement final tables
within your `dbt_project.yml` file.

```yml
vars:
    balance_sheet_transaction_detail_columns: ['company_name','vendor_name']
    income_statement_transaction_detail_columns: ['is_account_intercompany','location_name']
```

### Change the build schema
By default, this package builds the Netsuite staging models within a schema titled (`<target_schema>` + `_netsuite_source`) and your Netsuite modeling models within a schema titled (`<target_schema>` + `_netsuite`) in your destination. If this is not where you would like your Netsuite data to be written to, add the following configuration to your root `dbt_project.yml` file:

```yml
models:
    netsuite_source:
      +schema: my_new_schema_name # leave blank for just the target_schema
    netsuite:
      +schema: my_new_schema_name # leave blank for just the target_schema
```
    
### Change the source table references
If an individual source table has a different name than the package expects, add the table name as it appears in your destination to the respective variable:

> IMPORTANT: See this project's [`dbt_project.yml`](https://github.com/fivetran/dbt_netsuite_source/blob/main/dbt_project.yml) variable declarations to see the expected names.

```yml
vars:
    # For all Netsuite source tables
    netsuite_<default_source_table_name>_identifier: your_table_name 

    # For all Netsuite2 source tables
    netsuite2_<default_source_table_name>_identifier: your_table_name 
```

### Override the data models variable
This package is designed to run **either** the Netsuite.com or Netsuite2 data models. However, for documentation purposes, an additional variable `netsuite_data_model_override` was created to allow for both data model types to be run at the same time by setting the variable value to `netsuite`. This is only to ensure the [dbt docs](https://fivetran.github.io/dbt_netsuite/) (which is hosted on this repository) is generated for both model types. While this variable is provided, we recommend you do not adjust the variable and instead change the `netsuite_data_model` variable to fit your configuration needs.

</details>

## (Optional) Step 7: Orchestrate your models with Fivetran Transformations for dbt Core™    
<details><summary>Expand for details</summary>
<br>

Fivetran offers the ability for you to orchestrate your dbt project through [Fivetran Transformations for dbt Core™](https://fivetran.com/docs/transformations/dbt). Learn how to set up your project for orchestration through Fivetran in our [Transformations for dbt Core setup guides](https://fivetran.com/docs/transformations/dbt#setupguide).

</details>

# 🔍 Does this package have dependencies?
This dbt package is dependent on the following dbt packages. Please be aware that these dependencies are installed by default within this package. For more information on the following packages, refer to the [dbt hub](https://hub.getdbt.com/) site.
> IMPORTANT: If you have any of these dependent packages in your own `packages.yml` file, we highly recommend that you remove them from your root `packages.yml` to avoid package version conflicts.
    
```yml
packages:
    - package: fivetran/netsuite_source
      version: [">=0.7.0", "<0.8.0"]

    - package: fivetran/fivetran_utils
      version: [">=0.4.0", "<0.5.0"]

    - package: dbt-labs/dbt_utils
      version: [">=1.0.0", "<2.0.0"]

    - package: dbt-labs/spark_utils
      version: [">=0.3.0", "<0.4.0"]
```
# 🙌 How is this package maintained and can I contribute?
## Package Maintenance
The Fivetran team maintaining this package _only_ maintains the latest version of the package. We highly recommend you stay consistent with the [latest version](https://hub.getdbt.com/fivetran/netsuite/latest/) of the package and refer to the [CHANGELOG](https://github.com/fivetran/dbt_netsuite/blob/main/CHANGELOG.md) and release notes for more information on changes across versions.

## Contributions
A small team of analytics engineers at Fivetran develops these dbt packages. However, the packages are made better by community contributions! 

We highly encourage and welcome contributions to this package. Check out [this dbt Discourse article](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657) on the best workflow for contributing to a package!

# 🏪 Are there any resources available?
- If you have questions or want to reach out for help, please refer to the [GitHub Issue](https://github.com/fivetran/dbt_netsuite/issues/new/choose) section to find the right avenue of support for you.
- If you would like to provide feedback to the dbt package team at Fivetran or would like to request a new dbt package, fill out our [Feedback Form](https://www.surveymonkey.com/r/DQ7K7WW).
- Have questions or want to be part of the community discourse? Create a post in the [Fivetran community](https://community.fivetran.com/t5/user-group-for-dbt/gh-p/dbt-user-group) and our team along with the community can join in on the discussion!
