# Netsuite Transformation dbt Package ([Docs](https://fivetran.github.io/dbt_netsuite/))

<p align="left">
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

## What does this dbt package do?
- Produces modeled tables that leverage Netsuite data from [Fivetran's connector](https://fivetran.com/docs/applications/netsuite) in the format described by [this ERD](https://fivetran.com/docs/applications/netsuite#schemainformation).
- Enables users to gain insights into their netsuite data that can be used for financial statement reporting and deeper transactional analysis. This is achieved by the following:
    - Recreating both the balance sheet and income statement
    - Recreating commonly used data by using the transaction lines as the base table and joining other data
- Generates a comprehensive data dictionary of your source and modeled Netsuite data through the [dbt docs site](https://fivetran.github.io/dbt_netsuite/).

<!--section="netsuite_transformation_model"-->
The following tables provide comprehensive financial reporting capabilities from your NetSuite data.
> TIP: See more details about these tables in the package's [dbt docs site](https://fivetran.github.io/dbt_netsuite/#!/overview?g_v=1&g_e=seeds).

| **Table** | **Details** |
|-----------|-------------|
| [`netsuite2__balance_sheet`](https://fivetran.github.io/dbt_netsuite/#!/model/model.netsuite.netsuite2__balance_sheet) | Creates all transaction lines necessary to generate a balance sheet with proper currency conversion for the parent subsidiary. Non-balance sheet transactions are categorized as Retained Earnings or Net Income, with manual calculation of Cumulative Translation Adjustment.<br><br>**Example Analytics Questions:**<li>What is our current cash position and working capital across subsidiaries?<li>How has our debt-to-equity ratio changed over the past year?<li>How have retained earnings and total equity evolved across accounting periods? |
| [`netsuite2__income_statement`](https://fivetran.github.io/dbt_netsuite/#!/model/model.netsuite.netsuite2__income_statement) | Provides all transaction lines needed for income statement generation with currency conversion and department, class, and location details for enhanced reporting capabilities.<br><br>**Example Analytics Questions:**<li>What is our gross margin by product line, department, or location?<li>How has operating income changed quarter over quarter?<li>Which expense categories are growing the fastest this period? |
| [`netsuite2__transaction_details`](https://fivetran.github.io/dbt_netsuite/#!/model/model.netsuite.netsuite2__transaction_details) | Comprehensive transaction-level view combining transaction lines with detailed context including accounting period, account, subsidiary, customer, vendor, location, item, and department information.<br><br>**Example Analytics Questions:**<li>Which customers or vendors generate the highest transaction volumes?<li>What are the most common transaction types by subsidiary or department?<li>Which accounts show the largest transaction fluctuations month over month? |
| [`netsuite2__entity_subsidiary_relationships`](https://fivetran.github.io/dbt_netsuite/#!/model/model.netsuite.netsuite2__entity_subsidiary_relationships) | Unified view of customer and vendor relationships across subsidiaries, showing which entities operate in which subsidiaries with primary subsidiary designations and currency details.<br><br>**Example Analytics Questions:**<li>Which customers operate across multiple subsidiaries?<li>What currencies are most commonly used by our entities?<li>Which subsidiaries have the most vendor relationships? |

Many of the above reports are now configurable for [visualization via Streamlit](https://github.com/fivetran/streamlit_netsuite)! Check out some [sample reports here](https://fivetran-netsuite.streamlit.app/).

### Example Visualizations
Curious what these tables can do? Check out example visualizations from the [netsuite2__balance_sheet](https://fivetran.github.io/dbt_netsuite/#!/model/model.netsuite.netsuite2__balance_sheet) and [netsuite2__income_statement](https://fivetran.github.io/dbt_netsuite/#!/model/model.netsuite.netsuite2__income_statement) tables in the [Fivetran Billing Model Streamlit App](https://fivetran-billing-model.streamlit.app/), and see how you can use these tables in your own reporting. Below is a screenshot of an example report—explore the app for more.

<p align="center">
<a href="https://fivetran-billing-model.streamlit.app/">
    <img src="https://raw.githubusercontent.com/fivetran/dbt_netsuite/main/images/streamlit_example.png" alt="Streamlit Billing Model App" width="60%">
</a>
</p>

### Materialized Models
Each Quickstart transformation job run materializes 92 models if all components of this data model are enabled. This count includes all staging, intermediate, and final models materialized as `view`, `table`, or `incremental`.
<!--section-end-->

## How do I use the dbt package?
### Step 1: Prerequisites
To use this dbt package, you must have At least either one Fivetran **Netsuite** (netsuite.com) or **Netsuite2** (netsuite2) connection syncing the respective tables to your destination:
#### Netsuite.com
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

#### Netsuite2
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
- fiscalcalendar (required for non–January 1 fiscal year start)
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

#### Database Compatibility
This package is compatible with either a **BigQuery**, **Snowflake**, **Redshift**, **PostgreSQL**, or **Databricks** destination.

#### Databricks dispatch configuration
If you are using a Databricks destination with this package, you must add the following (or a variation of the following) dispatch configuration within your `dbt_project.yml`. This is required in order for the package to accurately search for macros within the `dbt-labs/spark_utils` then the `dbt-labs/dbt_utils` packages respectively.
```yml
dispatch:
  - macro_namespace: dbt_utils
    search_order: ['spark_utils', 'dbt_utils']
```
> All required sources and staging models are now bundled into this transformation package. Do not include `fivetran/netsuite_source` in your `packages.yml` since this package has been deprecated.

### Step 2: Install the package
Include the following netsuite package version in your `packages.yml` file:
> TIP: Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.
```yaml
packages:
  - package: fivetran/netsuite
    version: [">=1.1.0", "<1.2.0"]
```
### Step 3: Define Netsuite.com or Netsuite2 Source
As of April 2022 Fivetran released a new Netsuite connector version which leverages the Netsuite2 endpoint opposed to the original Netsuite.com endpoint. This package is designed to run for either or, not both. By default the `netsuite_data_model` variable for this package is set to the original `netsuite` value which runs the netsuite.com version of the package. If you would like to run the package on Netsuite2 data, you may adjust the `netsuite_data_model` variable to run the `netsuite2` version of the package.
```yml
vars:
    netsuite_data_model: netsuite2 #netsuite by default
```

> The `netsuite_data_model` variable is automatically configured for Fivetran Quickstart users.

### Step 4: Define database and schema variables
By default, this package runs using your destination and the `netsuite` schema. If this is not where your Netsuite data is (for example, if your netsuite schema is named `netsuite_fivetran`), add the following configuration to your root `dbt_project.yml` file:

```yml
vars:
    netsuite_database: your_destination_name
    netsuite_schema: your_schema_name 
```

> **Note**: If you are running the package on one source connector, each model will have a `source_relation` column that is just an empty string.

### Option 2: Union multiple connectors (Netsuite2 only) 👯
If you have multiple Netsuite connectors in Fivetran and would like to use this package on all of them simultaneously, we have provided functionality to do so. The package will union all of the data together and pass the unioned table into the transformations. You will be able to see which source it came from in the `source_relation` column of each model. To use this functionality, you will need to set either the `netsuite_union_schemas` OR `netsuite_union_databases` variables (cannot do both, though a more flexible approach is in the works...) in your root `dbt_project.yml` file:

```yml
# dbt_project.yml

vars:
    netsuite2_union_schemas: ['netsuite2_usa','netsuite2_canada'] # use this if the data is in different schemas/datasets of the same database/project
    netsuite2_union_databases: ['netsuite2_usa','netsuite2_canada'] # use this if the data is in different databases/projects but uses the same schema name
```

#### Recommended: Incorporate unioned sources into DAG
By default, this package defines one single-connector source, called `netsuite2`, which will be disabled if you are unioning multiple connectors. This means that your DAG will not include your Netsuite sources, though the package will run successfully.

To properly incorporate all of your Netsuite2 connectors into your project's DAG:
1. Define each of your sources in a `.yml` file in your project. Utilize the following template for the `source`-level configurations, and, **most importantly**, copy and paste the table and column-level definitions from the package's `src_netsuite2.yml` [file](https://github.com/fivetran/dbt_netsuite_source/blob/main/models/netsuite2/src_netsuite2.yml#L15-L607).

```yml
# a .yml file in your root project
sources:
  - name: <name> # ex: netsuite2_usa
    schema: <schema_name> # one of var('netsuite2_union_schemas') if unioning schemas, otherwise just 'netsuite2'
    database: <database_name> # one of var('netsuite2_union_databases') if unioning databases, otherwise whatever DB your netsuite2 schemas all live in
    loader: fivetran
    loaded_at_field: _fivetran_synced

    freshness: # feel free to adjust to your liking
      warn_after: {count: 72, period: hour}
      error_after: {count: 168, period: hour}

    tables: # copy and paste from netsuite_source/models/netsuite2/src_netsuite2.yml 
```

> **Note**: If there are source tables you do not have (see [Step 4](https://github.com/fivetran/dbt_netsuite?tab=readme-ov-file#step-5-disable-models-for-non-existent-sources-netsuite2-only)), you may still include them, as long as you have set the right [variables](https://github.com/fivetran/dbt_netsuite?tab=readme-ov-file#step-5-disable-models-for-non-existent-sources-netsuite2-only) to `False`. Otherwise, you may remove them from your source definitions.

2. Set the `has_defined_sources` variable (scoped to the `netsuite_source` package) to `True`, like such:
```yml
# dbt_project.yml
vars:
  netsuite_source:
    has_defined_sources: true
```

## Step 5: Disable models for non-existent sources (Netsuite2 only)
> _This step is unnecessary (but still available for use) if you are unioning multiple connectors together in the previous step. That is, the `union_data` macro we use will create completely empty staging models for sources that are not found in any of your Netsuite2 schemas/databases. However, you can still leverage the below variables if you would like to avoid this behavior._

It's possible that your Netsuite connector does not sync every table that this package expects. If your syncs exclude certain tables, it is because you either don't use that feature in Netsuite or actively excluded some tables from your syncs. To disable the corresponding functionality in the package, you must add the relevant variables. By default, all variables are assumed to be true. Add variables for only the tables you would like to disable:
### Step 5: Disable models for non-existent sources (Netsuite2 only)
Your Netsuite connection may not sync every table that this package expects. If your syncs exclude certain tables, it is because you either don't use that feature in Netsuite or actively excluded some tables from your syncs. To disable the corresponding functionality in the package, you must add the relevant variables. By default, most variables are assumed to be true with the exception of `netsuite2__fiscal_calendar_enabled`. Add variables for only the tables you would like to disable/enable:
```yml
vars:
    netsuite2__multibook_accounting_enabled: true # False by default. Disable `accountingbooksubsidiary` and `accountingbook` if you are not using the Multi-Book Accounting feature
    netsuite2__using_exchange_rate: false #True by default. Disable `exchange_rate` if you don't utilize exchange rates.
    netsuite2__using_vendor_categories: false # True by default. Disable `vendorcategory` if you don't categorize your vendors
    netsuite2__using_jobs: false # True by default. Disable `job` if you don't use jobs
    netsuite2__using_employees: false # True by default. Disable `employee` if you don't use employees.
    netsuite2__fiscal_calendar_enabled: true # False by default. Enable `fiscalcalendar` if you have a fiscal year starting on a month different than January.
```
> **Note**: The Netsuite dbt package currently only supports disabling transforms of [Multi-Book Accounting](https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/book_3831565332.html) related tables (`accountingbooksubsidiary` and `accountingbook`) and the `vendorcategory` and `job` source tables. Please create an issue to request additional tables and/or [features](https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/bridgehead_N233872.html) to exclude.
>
> To determine if a table or field is activated by a feature, access the [Records Catalog](https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/article_159367781370.html).

## (Optional) Step 6: Additional configurations
<details open><summary>Expand/collapse configurations</summary>

#### Enable additional features

#### Multi-Book (Netsuite2 only)
To include `accounting_book_id` and `accounting_book_name` columns in the end models, set the below variable to `true` in your `dbt_project.yml`. This feature is disabled by default.

>Notes:
> - If you choose to enable this feature, this adds rows for transactions for any non-primary `accounting_book_id`, and your downstream use cases may need to be adjusted.
> - The surrogate keys for the end models are dynamically generated depending on the enabled/disabled features, so adding these rows will not cause test failures.
> - If you are leveraging a `*_pass_through_columns` variable to include the added columns, you may need to remove them to avoid a duplicate column error.
```yml
vars:
    netsuite2__multibook_accounting_enabled: true # False by default.
```

**IMPORTANT**: If you are using multi-book accounting, this variable must be set to true, or you see test failures in your data. 

#### To Subsidiary (Netsuite2 only)
To include `to_subsidiary_id` and `to_subsidiary_name` columns in the end models, set the below variable to `true` in your `dbt_project.yml`. This feature is disabled by default. You also need to be using exchange rates, which is enabled by default.

>Notes:
> - If you choose to enable this feature, this adds rows for transactions where `to_subsidiary` is not a top-level subsidiary. Your downstream use cases may need to be adjusted.
> - The surrogate keys for the end models are dynamically generated depending on the enabled/disabled features, so adding these rows will not cause test failures.
> - If you are leveraging a `*_pass_through_columns` variable to include the added columns, you may need to remove them to avoid a duplicate column error.

```yml
vars:
    netsuite2__using_to_subsidiary: true # False by default.
```

#### Passing Through Additional Fields
This package includes all source columns defined in the macros folder. To add additional columns to this package, do so by adding our pass-through column variables to your `dbt_project.yml` file:

```yml
vars:
    accounts_pass_through_columns: # Included in all end models
        - name: "new_custom_field"
          alias: "custom_field"
    classes_pass_through_columns: # Included in income_statement models
        - name: "this_field"
    departments_pass_through_columns: # Included in income_statement and transaction_details models
        - name: "unique_string_field"
          alias: "field_id"
          transform_sql: "cast(field_id as string)"
    transactions_pass_through_columns: # Included in transaction_details models
        - name: "that_field"
    transaction_lines_pass_through_columns: # Included in transaction_details models
        - name: "other_id"
          alias: "another_id"
          transform_sql: "cast(another_id as int64)"
    locations_pass_through_columns: # Included in transaction_details models
        - name: "location_custom_field"
    subsidiaries_pass_through_columns: # Included in transaction_details models
        - name: "sub_field"
          alias: "subsidiary_field"
    customers_pass_through_columns: # Not included in end models; only in stg customer models
        - name: "customer_custom_field"
          alias: "customer_field"
    consolidated_exchange_rates_pass_through_columns: # Not included in end models; only in stg consolidated_exchange_rates models
        - name: "consolidate_this_field"
    entities_pass_through_columns: # Not included in end models; only in stg entities model
        - name: "entity_custom_field"
          alias: "entity_field"
    accounting_periods_pass_through_columns: # Not included in end models; only in stg accounting_periods models
        - name: "custom_field"
          transform_sql: "cast(custom_field as string)"
    vendors_pass_through_columns: # Not included in end models; only in stg vendors models
        - name: "vendors_custom_field"
          alias: "vendors_field"
    items_pass_through_columns: # Not included in end models; only in stg items models
        - name: "items_custom_field"
          alias: "items_field"
```

> If you would like any of the above passthrough columns to be persisted to additional downstream models (i.e. `netsuite2__income_statement`, `netsuite2__balance_sheet`, `netsuite2__transaction_details`), or passthrough column support for other source tables, please create a Feature Request [issue](https://github.com/fivetran/dbt_netsuite/issues).

#### Passing Through Transaction Detail Fields
Additionally, this package allows users to pass columns from the `netsuite__transaction_details` table into
the `netsuite__balance_sheet` and `netsuite__income_statement` tables. See below for an example
of how to passthrough transaction detail columns into the respective balance sheet and income statement final tables
within your `dbt_project.yml` file.

```yml
vars:
    balance_sheet_transaction_detail_columns: ['company_name','vendor_name']
    income_statement_transaction_detail_columns: ['is_account_intercompany','location_name']
```

#### Change the build schema
By default, this package builds the Netsuite staging models within a schema titled (`<target_schema>` + `_netsuite_source`) and your Netsuite modeling models within a schema titled (`<target_schema>` + `_netsuite`) in your destination. If this is not where you would like your Netsuite data to be written to, add the following configuration to your root `dbt_project.yml` file:

```yml
models:
    netsuite:
      +schema: my_new_schema_name # Leave +schema: blank to use the default target_schema.
      netsuite2: # if you're using netsuite2.com
        staging:
            +schema: my_new_schema_name # Leave +schema: blank to use the default target_schema.
      netsuite: # if you're using netsuite.com
        staging:
            +schema: my_new_schema_name # Leave +schema: blank to use the default target_schema.
```

#### Change the source table references
If an individual source table has a different name than the package expects, add the table name as it appears in your destination to the respective variable:

> IMPORTANT: See this project's [`dbt_project.yml`](https://github.com/fivetran/dbt_netsuite/blob/main/dbt_project.yml) variable declarations to see the expected names.

```yml
vars:
    use_table_name_identifer_override: true # Netsuite2 users must set this to TRUE. default = false
    
    # For all Netsuite source tables
    netsuite_<default_source_table_name>_identifier: your_table_name 

    # For all Netsuite2 source tables
    netsuite2_<default_source_table_name>_identifier: your_table_name 
```

#### Override the data models variable
This package is designed to run **either** the Netsuite.com or Netsuite2 data models. However, for documentation purposes, an additional variable `netsuite_data_model_override` was created to allow for both data model types to be run at the same time by setting the variable value to `netsuite`. This is only to ensure the [dbt docs](https://fivetran.github.io/dbt_netsuite/) (which is hosted on this repository) is generated for both model types. While this variable is provided, we recommend you do not adjust the variable and instead change the `netsuite_data_model` variable to fit your configuration needs.

#### Lookback Window
Records from the source can sometimes arrive late. Since several of the models in this package are incremental, by default we look back 3 days from the `_fivetran_synced_date` of transaction records to ensure late arrivals are captured and avoiding the need for frequent full refreshes. While the frequency can be reduced, we still recommend running `dbt --full-refresh` periodically to maintain data quality of the models.

To change the default lookback window, add the following variable to your `dbt_project.yml` file:

```yml
vars:
  netsuite:
    lookback_window: number_of_days # default is 3
```

#### Adding incremental materialization for Bigquery and Databricks
Since pricing and runtime priorities vary by customer, by default we chose to materialize the below models as tables instead of an incremental materialization for Bigquery and Databricks. For more information on this decision, see the [Incremental Strategy section](https://github.com/fivetran/dbt_netsuite/blob/main/DECISIONLOG.md#incremental-strategy) of the DECISIONLOG.

If you wish to enable incremental materializations leveraging the `merge` strategy, you can add the below materialization settings to your `dbt_project.yml` file. You only need to add lines for the specific model materializations you wish to change.
```yml
models:
  netsuite:
    netsuite2:
      netsuite2__income_statement:
        +materialized: incremental # default is table for Bigquery and Databricks
      netsuite2__transaction_details:
        +materialized: incremental # default is table for Bigquery and Databricks
      netsuite2__balance_sheet:
        +materialized: incremental # default is table for Bigquery and Databricks
```

### (Optional) Step 7: Produce Analytics-Ready Reports with Streamlit App (Bigquery and Snowflake users only)
For those who want to take their reports a step further, our team has created the [Fivetran Netsuite Streamlit App](https://fivetran-netsuite.streamlit.app/) to generate end model visualizations based off of the reports we created in this package.  This way you can replicate much of the reporting you see internally in Netsuite and automate a lot of the work needed to report on your core metrics.

[We recommend following the instructions here](https://github.com/fivetran/streamlit_netsuite) to fork the app for your own data and create end reports leveraging our Netsuite models. You can see a sample version of [these reports here](https://fivetran-netsuite.streamlit.app/).

### (Optional) Step 8: Orchestrate your models with Fivetran Transformations for dbt Core™
<details><summary>Expand for details</summary>
<br>

Fivetran offers the ability for you to orchestrate your dbt project through [Fivetran Transformations for dbt Core™](https://fivetran.com/docs/transformations/dbt). Learn how to set up your project for orchestration through Fivetran in our [Transformations for dbt Core setup guides](https://fivetran.com/docs/transformations/dbt#setupguide).

</details>

## Does this package have dependencies?
This dbt package is dependent on the following dbt packages. These dependencies are installed by default within this package. For more information on the following packages, refer to the [dbt hub](https://hub.getdbt.com/) site.
> IMPORTANT: If you have any of these dependent packages in your own `packages.yml` file, we highly recommend that you remove them from your root `packages.yml` to avoid package version conflicts.

```yml
packages:
    - package: fivetran/fivetran_utils
      version: [">=0.4.0", "<0.5.0"]

    - package: dbt-labs/dbt_utils
      version: [">=1.0.0", "<2.0.0"]

    - package: dbt-labs/spark_utils
      version: [">=0.3.0", "<0.4.0"]
```
## How is this package maintained and can I contribute?
### Package Maintenance
The Fivetran team maintaining this package _only_ maintains the latest version of the package. We highly recommend you stay consistent with the [latest version](https://hub.getdbt.com/fivetran/netsuite/latest/) of the package and refer to the [CHANGELOG](https://github.com/fivetran/dbt_netsuite/blob/main/CHANGELOG.md) and release notes for more information on changes across versions.

### Contributions
A small team of analytics engineers at Fivetran develops these dbt packages. However, the packages are made better by community contributions.

We highly encourage and welcome contributions to this package. Check out [this dbt Discourse article](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657) on the best workflow for contributing to a package.

## Are there any resources available?
- If you have questions or want to reach out for help, see the [GitHub Issue](https://github.com/fivetran/dbt_netsuite/issues/new/choose) section to find the right avenue of support for you.
- If you would like to provide feedback to the dbt package team at Fivetran or would like to request a new dbt package, fill out our [Feedback Form](https://www.surveymonkey.com/r/DQ7K7WW).
