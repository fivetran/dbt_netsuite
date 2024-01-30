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

Many of the above reports are now configurable for [visualization via Streamlit](https://github.com/fivetran/streamlit_netsuite)! Check out some [sample reports here](https://fivetran-netsuite.streamlit.app/).
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
    version: [">=0.13.0", "<0.14.0"]
```
## Step 3: Define Netsuite.com or Netsuite2 Source
As of April 2022 Fivetran made available a new Netsuite connector which leverages the Netsuite2 endpoint opposed to the original Netsuite.com endpoint. This package is designed to run for either or, not both. By default the `netsuite_data_model` variable for this package is set to the original `netsuite` value which runs the netsuite.com version of the package. If you would like to run the package on Netsuite2 data, you may adjust the `netsuite_data_model` variable to run the `netsuite2` version of the package.
```yml
vars:
    netsuite_data_model: netsuite2 #netsuite by default
```

## Step 4: Define database and schema variables
### Option 1: Single connector
By default, this package runs using your destination and the `netsuite` schema. If this is not where your Netsuite data is (for example, if your netsuite schema is named `netsuite_fivetran`), add the following configuration to your root `dbt_project.yml` file:

```yml
vars:
    netsuite_database: your_destination_name
    netsuite_schema: your_schema_name 
```

> **Note**: If you are running the package on one source connector, each model will have a `source_relation` column that is just an empty string.

### Option 2: Union multiple connectors
If you have multiple Netsuite connectors in Fivetran and would like to use this package on all of them simultaneously, we have provided functionality to do so. The package will union all of the data together and pass the unioned table into the transformations. You will be able to see which source it came from in the `source_relation` column of each model. To use this functionality, you will need to set either the `netsuite_union_schemas` OR `netsuite_union_databases` variables (cannot do both, though a more flexible approach is in the works...) in your root `dbt_project.yml` file:

```yml
# dbt_project.yml

vars:
    netsuite_union_schemas: ['netsuite_usa','netsuite_canada'] # use this if the data is in different schemas/datasets of the same database/project
    netsuite_union_databases: ['netsuite_usa','netsuite_canada'] # use this if the data is in different databases/projects but uses the same schema name
```

#### Recommended: Incorporate unioned sources into DAG
By default, this package defines one single-connector source, called `netsuite`, which will be disabled if you are unioning multiple connectors. This means that your DAG will not include your Netsuite sources, though the package will run successfully.

To properly incorporate all of your Netsuite connectors into your project's DAG:
1. Define each of your sources in a `.yml` file in your project. Utilize the following template to leverage our table and column documentation. 

  <details><summary><i>Expand for source configuration template</i></summary><p>

> **Note**: If there are source tables you do not have (see [Step 4](https://github.com/fivetran/dbt_netsuite?tab=readme-ov-file#step-5-disable-models-for-non-existent-sources-netsuite2-only)), you may still include them, as long as you have set the right variables to `False`. Otherwise, you may remove them from your source definitions.

```yml
sources:
  - name: <name>
    schema: <schema_name>
    database: <database_name>
    loader: fivetran
    loaded_at_field: _fivetran_synced

    freshness:
      warn_after: {count: 72, period: hour}
      error_after: {count: 168, period: hour}

    tables: &netsuite2_table_defs # <- see https://support.atlassian.com/bitbucket-cloud/docs/yaml-anchors/
      - name: account_type
        identifier: accounttype
        description: A table containing the various account types within Netsuite.
        columns:
          - name: _fivetran_deleted
            description: Unique ID used by Fivetran to sync and dedupe data.
          - name: _fivetran_synced
            description: Timestamp of when a record was last synced.
          - name: id
            description: Unique identifier of thea account type.
          - name: balancesheet
            description: Boolean indicating if the account type is a balance sheet account. Represented as "T" or "F" for true and false respectively.
          - name: left
            description: Boolean indicating if the account type is leftside. Represented as "T" or "F" for true and false respectively.
          - name: longname
            description: The name of the account type.

      - name: accounting_book_subsidiaries
        identifier: accountingbooksubsidiaries
        description: A table containing the various account books and the respective subsidiaries.
        config:
          enabled: "{{ var('netsuite2__multibook_accounting_enabled', true) }}"
        columns:
          - name: _fivetran_id
            description: Unique ID used by Fivetran to sync and dedupe data.
          - name: _fivetran_synced
            description: Timestamp of when a record was last synced.
          - name: accountingbook
            description: Unique identifier of the accounting book.
          - name: status
            description: The status of the accounting book subsidiary.
          - name: subsidiary
            description: The unique identifier of the subsidiary used for the record.
      
      - name: accounting_book
        identifier: accountingbook
        description: Table detailing all accounting books set up in Netsuite.
        config:
          enabled: "{{ var('netsuite2__multibook_accounting_enabled', true) }}"
        columns:
          - name: _fivetran_synced
            description: Timestamp of when a record was last synced.
          - name: id
            description: Unique identifier of the accounting book.
          - name: name
            description: Name of the accounting book.
          - name: basebook
            description: Reference to the base book.
          - name: effectiveperiod
            description: Reference to the effective period of the accounting book.
          - name: isadjustmentonly
            description: Boolean indicating if the accounting book is an adjustment only. Represented as "T" or "F" for true and false respectively.
          - name: isconsolidated
            description: Boolean indicating if the accounting book is a consolidated entry. Represented as "T" or "F" for true and false respectively.
          - name: contingentrevenuehandling
            description: Boolean indicating if the accounting book is contingent revenue handling. Represented as "T" or "F" for true and false respectively.
          - name: isprimary
            description: Boolean indicating if the accounting book is a primary entry. Represented as "T" or "F" for true and false respectively.
          - name: twosteprevenueallocation
            description: Boolean indicating if the accounting book is a two step revenue allocation entry. Represented as "T" or "F" for true and false respectively.
          - name: unbilledreceivablegrouping
            description: Boolean indicating if the accounting book is an unbilled receivable grouping. Represented as "T" or "F" for true and false respectively.
      
      - name: accounting_period_fiscal_calendars
        identifier: accountingperiodfiscalcalendars
        description: A table containing the accounting fiscal calendar periods.
        columns:
          - name: _fivetran_id
            description: Unique ID used by Fivetran to sync and dedupe data.
          - name: _fivetran_synced
            description: Timestamp of when a record was last synced.
          - name: accountingperiod
            description: The accounting period id of the accounting period which the transaction took place in.
          - name: fiscalcalendar
            description: Reference to the fiscal calendar used for the record.
          - name: parent
            description: Reference to the parent fiscal calendar accounting period.

      - name: accounting_period
        identifier: accountingperiod
        description: Table detailing all accounting periods, including monthly, quarterly and yearly.
        columns:
          - name: _fivetran_synced
            description: Timestamp of when a record was last synced.
          - name: id
            description: The accounting period id of the accounting period which the transaction took place in.
          - name: parent
            description: Reference to the parent accounting period.
          - name: periodname
            description: Name of the accounting period.
          - name: startdate
            description: Timestamp of when the accounting period starts.
          - name: enddate
            description: Timestamp if when the accounting period ends.
          - name: closedondate
            description: Timestamp of when the accounting period is closed.
          - name: isquarter
            description: Boolean indicating if the accounting period is the initial quarter. Represented as "T" or "F" for true and false respectively.
          - name: isyear
            description: Boolean indicating if the accounting period is the initial period. Represented as "T" or "F" for true and false respectively.
          - name: isadjust
            description: Boolean indicating if the accounting period is an adjustment. Represented as "T" or "F" for true and false respectively.
          - name: isposting
            description: Boolean indicating if the accounting period is posting. Represented as "T" or "F" for true and false respectively.
          - name: closed
            description: Boolean indicating if the accounting period is closed. Represented as "T" or "F" for true and false respectively.
          - name: alllocked
            description: Boolean indicating if all the accounting periods are locked. Represented as "T" or "F" for true and false respectively.
          - name: arlocked
            description: Boolean indicating if the ar accounting period is locked. Represented as "T" or "F" for true and false respectively.
          - name: aplocked
            description: Boolean indicating if the ap accounting period is locked. Represented as "T" or "F" for true and false respectively.
          
      - name: account
        identifier: account
        description: Table detailing all accounts set up in Netsuite.
        columns:
          - name: _fivetran_synced
            description: Timestamp of when a record was last synced.
          - name: id
            description: The unique identifier associated with the account.
          - name: externalid
            description: Reference to the external account,
          - name: parent
            description: Reference to the parent account.
          - name: acctnumber
            description: Netsuite generated account number.
          - name: accttype
            description: Reference to the account type.
          - name: sspecacct
            description: Special account type.
          - name: fullname
            description: Name of the account.
          - name: description
            description: Description of the account.
          - name: deferralacct
            description: Reference to the deferral account.
          - name: cashflowrate
            description: The cash flow rate type of the account.
          - name: generalrate
            description: The general rate type of the account (Current, Historical, Average).
          - name: currency
            description: The currency id of the currency used within the record.
          - name: class
            description: The unique identifier of the class used for the record.
          - name: department
            description: The unique identifier of the department used for the record.
          - name: location
            description: The unique identifier of the location used for the record.
          - name: includechildren
            description: Boolean indicating if the account includes sub accounts. Represented as "T" or "F" for true and false respectively.
          - name: isinactive
            description: Boolean indicating if the account is inactive. Represented as "T" or "F" for true and false respectively.
          - name: issummary
            description: Boolean indicating if the account is a summary account. Represented as "T" or "F" for true and false respectively.
          - name: eliminate
            description: Indicates this is an intercompany account used only to record transactions between subsidiaries. Amounts posted to intercompany accounts are eliminated when you run the intercompany elimination process at the end of an accounting period. Represented as "T" or "F" for true and false respectively.
          - name: _fivetran_deleted
            description: Timestamp of when a record was deleted.

      - name: classification
        identifier: classification
        description: Table detailing all classes set up in Netsuite.
        columns:
          - name: _fivetran_synced
            description: Timestamp of when a record was last synced.
          - name: id
            description: The unique identifier of the class used for the record.
          - name: externalid
            description: Reference to the external class.
          - name: name
            description: Name of the class.
          - name: fullname
            description: Full name of the class.
          - name: isinactive
            description: Boolean indicating if the class is active. Represented as "T" or "F" for true and false respectively.
          - name: _fivetran_deleted
            description: Timestamp of when a record was deleted.

      - name: consolidated_exchange_rate
        identifier: consolidatedexchangerate
        description: Table detailing average, historical and current exchange rates for all accounting periods.
        columns:
          - name: id
            description: Unique identifier for the consolidated exchange rate.
          - name: postingperiod
            description: The accounting period id of the accounting period which the transaction took place in.
          - name: fromcurrency
            description: The currency id which the consolidated exchange rate is from.
          - name: fromsubsidiary
            description: The subsidiary id which the consolidated exchange rate is from.
          - name: tocurrency
            description: The subsidiary id which the consolidated exchange rate is for.
          - name: tosubsidiary
            description: The subsidiary id which the consolidated exchange rate is for.
          - name: currentrate
            description: The current rate associated with the exchange rate.
          - name: averagerate
            description: The consolidated exchange rates average rate.
          - name: accountingbook
            description: Unique identifier of the accounting book.
          - name: historicalrate
            description: The historical rate of the exchange rate.

      - name: currency
        identifier: currency
        description: Table detailing all currency information.
        columns:
          - name: _fivetran_synced
            description: Timestamp of when a record was last synced.
          - name: id
            description: The currency id of the currency used within the record.
          - name: name
            description: Name of the currency.
          - name: symbol
            description: Currency symbol.

      - name: customer
        identifier: customer
        description: Table detailing all customer information.
        columns:
          - name: id
            description: Unique identifier of the customer.
          - name: entityid
            description: The entity id of the entity used for the record.
          - name: externalid
            description: Reference to the associated external customer.
          - name: parent
            description: Reference to the parent customer.
          - name: isperson
            description: Boolean indicating if the customer is an individual person. Represented as "T" or "F" for true and false respectively.
          - name: companyname
            description: Name of the company.
          - name: firstname
            description: First name of the customer.
          - name: lastname
            description: Last name of the customer.
          - name: email
            description: Customers email address.
          - name: phone
            description: Phone number of the customer.
          - name: defaultbillingaddress
            description: Reference to the associated billing address.
          - name: defaultshippingaddress
            description: Reference to the associated default shipping address.
          - name: receivablesaccount
            description: Reference to the associated receivables account.
          - name: currency
            description: The currency id of the currency used within the record.
          - name: firstorderdate
            description: Timestamp of when the first order was created.

      - name: department
        identifier: department
        description: Table detailing all departments set up in Netsuite.
        columns:
          - name: _fivetran_synced
            description: Timestamp of when a record was last synced.
          - name: id
            description: The unique identifier of the department used for the record.
          - name: parent
            description: Reference to the parent department.
          - name: name
            description: Name of the department.
          - name: fullname
            description: Full name of the department.
          - name: subsidiary
            description: The unique identifier of the subsidiary used for the record.
          - name: isinactive
            description: Boolean indicating if the department is active. Represented as "T" or "F" for true and false respectively.
          - name: _fivetran_deleted
            description: Timestamp of when a record was deleted.

      - name: entity
        identifier: entity
        description: Table detailing all entities in Netsuite.
        columns:
          - name: id
            description: The entity id of the entity used for the record.
          - name: contact
            description: The unique identifier of the contact associated with the entity.
          - name: customer
            description: The unique identifier of the customer associated with the entity.
          - name: employee
            description: The unique identifier of the employee associated with the entity.
          - name: entitytitle
            description: The entity name.
          - name: isperson
            description: Value indicating whether the entity is a person (either yes or no).
          - name: parent
            description: The unique identifier of the parent entity.
          - name: project
            description: The unique identifier of the project (job) associated with the entity.
          - name: type
            description: The entity type (Contact, CustJob, Job, etc).
          - name: vendor
            description: The unique identifier of the vendor associated with the entity.

      - name: entity_address
        identifier: entityaddress
        description: A table containing addresses and the various entities which they map.
        columns:
          - name: _fivetran_synced
            description: Timestamp of when a record was last synced.
          - name: addr1
            description: The associated address 1.
          - name: addr2
            description: The associated address 2.
          - name: addr3
            description: The associated address 3.
          - name: addressee
            description: The individual associated with the address.
          - name: addrtext
            description: The full address associated.
          - name: city
            description: The associated city.
          - name: country
            description: The associated country.
          - name: state
            description: The associated state.
          - name: nkey
            description: The associated Netsuite key.
          - name: zip
            description: The associated zipcode.

      - name: item
        identifier: item
        description: Table detailing information about the items created in Netsuite.
        columns:
          - name: _fivetran_synced
            description: Timestamp of when a record was last synced.
          - name: id
            description: The unique identifier of the item used within the record.
          - name: fullname
            description: Name of the item.
          - name: itemtype
            description: Item type name.
          - name: description
            description: Sales description associated with the item.
          - name: department
            description: The unique identifier of the department used for the record.
          - name: class
            description: The unique identifier of the class used for the record.
          - name: location
            description: The unique identifier of the location used for the record.
          - name: subsidiary
            description: The unique identifier of the subsidiary used for the record.
          - name: assetaccount
            description: Reference to the asset account.
          - name: expenseaccount
            description: Reference to the expense account.
          - name: gainlossaccount
            description: Reference to the gain or loss account.
          - name: incomeaccount
            description: Reference to the income account.
          - name: intercoexpenseaccount
            description: Reference to the intercompany expense account.
          - name: intercoincomeaccount
            description: Reference to the intercompany income account.
          - name: deferralaccount
            description: Reference to the deferred expense account.
          - name: deferredrevenueaccount
            description: Reference to the deferred revenue account.
          - name: parent
            description: Reference to the parent item.

      - name: job
        identifier: job
        description: Table detailing all jobs.
        config:
          enabled: "{{ var('netsuite2__using_jobs', true) }}"
        columns:
          - name: id
            description: The unique identifier of the job.
          - name: externalid
            description: The unique identifier of the external job reference.
          - name: customer
            description: The unique identifier of the customer associated with the job.
          - name: entityid
            description: Reference the the entity.
          - name: defaultbillingaddress
            description: Default billing address.
          - name: defaultshippingaddress
            description: Default shipping address.
          - name: parent
            description: Reference to the parent job.

      - name: location_main_address
        identifier: locationmainaddress
        description: A table containing the location main addresses.
        columns:
          - name: _fivetran_synced
            description: Timestamp of when a record was last synced.
          - name: addr1
            description: The associated address 1.
          - name: addr2
            description: The associated address 2.
          - name: addr3
            description: The associated address 3.
          - name: addressee
            description: The individual associated with the address.
          - name: addrtext
            description: The full address associated.
          - name: city
            description: The associated city.
          - name: country
            description: The associated country.
          - name: state
            description: The associated state.
          - name: nkey
            description: The associated Netsuite key.
          - name: zip
            description: The associated zipcode.

      - name: location
        identifier: location
        description: Table detailing all locations, including store, warehouse and office locations.
        columns:
          - name: _fivetran_synced
            description: Timestamp of when a record was last synced.
          - name: id
            description: The unique identifier of the location used for the record.
          - name: name
            description: Name of the location.
          - name: fullname
            description: Full name of the location.
          - name: mainaddress
            description: Reference to the main address used for the record.
          - name: parent
            description: Reference to the parent location.
          - name: subsidiary
            description: The unique identifier of the subsidiary used for the record.

      - name: subsidiary
        identifier: subsidiary
        description: Table detailing all subsidiaries.
        columns:
          - name: _fivetran_synced
            description: Timestamp of when a record was last synced.
          - name: id
            description: The unique identifier of the subsidiary used for the record.
          - name: name
            description: Name of the subsidiary.
          - name: fullname
            description: Full name of the subsidiary.
          - name: email
            description: Email address associated with the subsidiary.
          - name: mainaddress
            description: Reference to the main address used for the record.
          - name: country
            description: The country which the subsidiary is located.
          - name: state
            description: The state which the subsidiary is located.
          - name: fiscalcalendar
            description: Reference to the fiscal calendar used for the record.
          - name: parent
            description: Reference to the parent subsidiary.
          - name: currency
            description:  The currency id of the currency used within the record.

      - name: transaction_accounting_line
        identifier: transactionaccountingline
        description: A table detailing all transaction lines for all transactions.
        columns:
          - name: transaction
            description: The transaction id which the transaction line is associated with.
          - name: transactionline
            description: The unique identifier of the transaction line.
          - name: amount
            description: The amount of the transaction line.
          - name: netamount
            description: The net amount of the transaction line.
          - name: accountingbook
            description: Unique identifier of the accounting book.
          - name: account
            description: Reference to the account associated with the entry.
          - name: posting
            description: Boolean indicating if the entry is posting. Represented as "T" or "F" for true and false respectively.
          - name: credit
            description: Amount associated as a credit.
          - name: debit
            description: Amount associated as a debit.
          - name: amountpaid
            description: Total amount paid.
          - name: amountunpaid
            description: Total amount unpaid.

      - name: transaction_line
        identifier: transactionline
        description: A table detailing all transaction lines for all transactions.
        columns:
          - name: _fivetran_synced
            description: Timestamp of when a record was last synced.
          - name: id
            description: Unique identifier of the transaction line.
          - name: transaction
            description: The transaction id of referenced for the record.
          - name: linesequencenumber
            description: Netsuite generated number associated with the transaction line.
          - name: memo
            description: The memo attached to the transaction line.
          - name: entity
            description: The entity id of the entity used for the record.
          - name: item
            description: The unique identifier of the item used within the record.
          - name: class
            description: The unique identifier of the class used for the record.
          - name: location
            description: The unique identifier of the location used for the record.
          - name: subsidiary
            description: The unique identifier of the subsidiary used for the record.
          - name: department
            description: The unique identifier of the department used for the record.
          - name: isclosed
            description: Boolean indicating if the transaction line is closed. Represented as "T" or "F" for true and false respectively.
          - name: isbillable
            description: Boolean indicating if the transaction line is billable. Represented as "T" or "F" for true and false respectively.
          - name: iscogs
            description: Boolean indicating if the transaction line is a cost of goods sold entry. Represented as "T" or "F" for true and false respectively.
          - name: cleared
            description: Boolean indicating if the transaction line is cleared. Represented as "T" or "F" for true and false respectively.
          - name: commitmentfirm
            description: Boolean indicating if the transaction line is a commitment firm. Represented as "T" or "F" for true and false respectively.
          - name: mainline
            description: Boolean indicating if the transaction line is a main line entry. Represented as "T" or "F" for true and false respectively.
          - name: taxline
            description: Boolean indicating if the transaction line is a tax line. Represented as "T" or "F" for true and false respectively.

      - name: transaction
        identifier: transaction
        description: A table detailing all transactions.
        columns:
          - name: _fivetran_synced
            description: Timestamp of when a record was last synced.
          - name: id
            description: The transaction id of referenced for the record.
          - name: transactionnumber
            description: The Netsuite generated number of the transaction.
          - name: type
            description: The type of the transaction.
          - name: memo
            description: Memo attached to the transaction.
          - name: trandate
            description: The timestamp of the transaction date.
          - name: status
            description: Status of the transaction.
          - name: createddate
            description: Timestamp of when the record was created.
          - name: duedate
            description: Timestamp of the transactions due date.
          - name: closedate
            description: Timestamp of when the transaction was closed.
          - name: currency
            description: The currency id of the currency used within the record.
          - name: entity
            description: The entity id of the entity used for the record.
          - name: postingperiod
            description: The accounting period id of the accounting period which the transaction took place in.
          - name: posting
            description: Boolean indicating if the transaction is a posting event. Represented as "T" or "F" for true and false respectively.
          - name: intercoadj
            description: Boolean indicating if the transaction is an intercompany adjustment. Represented as "T" or "F" for true and false respectively.
          - name: isreversal
            description: Boolean indicating if the transaction is a reversal entry. Represented as "T" or "F" for true and false respectively.

      - name: vendor_category
        identifier: vendorcategory
        description: A table containing categories and how they map to vendors.
        config:
          enabled: "{{ var('netsuite2__using_vendor_categories', true) }}"
        columns:
          - name: id
            description: Unique identifier of the vendor category.
          - name: name
            description: Name of the vendor category.
          - name: _fivetran_synced
            description: Timestamp of when a record was last synced.

      - name: vendor
        identifier: vendor
        description: A table detailing all vendor information.
        columns:
          - name: _fivetran_synced
            description: Timestamp of when a record was last synced.
          - name: id
            description: The unique identifier of the vendor.
          - name: companyname
            description: Name of the company.
          - name: datecreated
            description: Timestamp of the record creation.
          - name: category
            description: Unique identifier of the vendor category
```
  </p></details>

2. Set the `has_defined_sources` variable (scoped to the `netsuite_source` package) to true, like such:
```yml
# dbt_project.yml
vars:
  netsuite_source:
    has_defined_sources: true
```

## Step 5: Disable models for non-existent sources (Netsuite2 only)
It's possible that your Netsuite connector does not sync every table that this package expects. If your syncs exclude certain tables, it is because you either don't use that feature in Netsuite or actively excluded some tables from your syncs. To disable the corresponding functionality in the package, you must add the relevant variables. By default, all variables are assumed to be true. Add variables for only the tables you would like to disable:
```yml
vars:
    netsuite2__multibook_accounting_enabled: true # False by default. Disable `accountingbooksubsidiary` and `accountingbook` if you are not using the Multi-Book Accounting feature
    netsuite2__using_exchange_rate: false #True by default. Disable `exchange_rate` if you don't utilize exchange rates. If you set this variable to false, ensure it is scoped globally so that the `netsuite_source` package can access it as well.
    netsuite2__using_vendor_categories: false # True by default. Disable `vendorcategory` if you don't categorize your vendors
    netsuite2__using_jobs: false # True by default. Disable `job` if you don't use jobs
```
> **Note**: The Netsuite dbt package currently only supports disabling transforms of [Multi-Book Accounting](https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/book_3831565332.html) related tables (`accountingbooksubsidiary` and `accountingbook`) and the `vendorcategory` and `job` source tables. Please create an issue to request additional tables and/or [features](https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/bridgehead_N233872.html) to exclude. 
> 
> To determine if a table or field is activated by a feature, access the [Records Catalog](https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/article_159367781370.html).

## (Optional) Step 6: Additional configurations

### Enable additional features 

### Multi-Book (Netsuite2 only)
To include `accounting_book_id` and `accounting_book_name` columns in the end models, set the below variable to `true` in your `dbt_project.yml`. This feature is disabled by default.
>❗Notes:  
> - If you choose to enable this feature, this will add rows for transactions for any non-primary `accounting_book_id`, and your downstream use cases may need to be adjusted. 
> - The surrogate keys for the end models are dynamically generated depending on the enabled/disabled features, so adding these rows will not cause test failures.
> - If you are leveraging a `*_pass_through_columns` variable to include the added columns, you may need to remove them to avoid a duplicate column error.
```yml
vars:
    netsuite2__multibook_accounting_enabled: true # False by default.
```

### To Subsidiary (Netsuite2 only)
To include `to_subsidiary_id` and `to_subsidiary_name` columns in the end models, set the below variable to `true` in your `dbt_project.yml`. This feature is disabled by default. You will also need to be using exchange rates, which is enabled by default.

>❗Notes:  
> - If you choose to enable this feature, this will add rows for transactions where `to_subsidiary` is not a top-level subsidiary. Your downstream use cases may need to be adjusted. 
> - The surrogate keys for the end models are dynamically generated depending on the enabled/disabled features, so adding these rows will not cause test failures.
> - If you are leveraging a `*_pass_through_columns` variable to include the added columns, you may need to remove them to avoid a duplicate column error.

```yml
vars:
    netsuite2__using_to_subsidiary: true # False by default.
```

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

## (Optional) Step 7: Produce Analytics-Ready Reports with Streamlit App (Bigquery and Snowflake users only)
For those who want to take their reports a step further, our team has created the [Fivetran Netsuite Streamlit App](https://fivetran-netsuite.streamlit.app/) to generate end model visualizations based off of the reports we created in this package.  This way you can replicate much of the reporting you see internally in Netsuite and automate a lot of the work needed to report on your core metrics.

[We recommend following the instructions here](https://github.com/fivetran/streamlit_netsuite) to fork the app for your own data and create end reports leveraging our Netsuite models. You can see a sample version of [these reports here]((https://fivetran-netsuite.streamlit.app/)).

## (Optional) Step 8: Orchestrate your models with Fivetran Transformations for dbt Core™    
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
      version: [">=0.10.0", "<0.11.0"]

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
