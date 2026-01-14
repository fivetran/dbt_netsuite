# dbt_netsuite v1.4.0

[PR #190](https://github.com/fivetran/dbt_netsuite/pull/190) includes the following updates:

## Documentation
- Updates README with standardized Fivetran formatting.

## Under the Hood
- In the `quickstart.yml` file:
  - Adds `table_variables` for relevant sources to prevent missing sources from blocking downstream Quickstart models.
  - Adds `supported_vars` for Quickstart UI customization.

# dbt_netsuite v1.3.0

[PR #187](https://github.com/fivetran/dbt_netsuite/pull/187) includes the following updates:

## Schema/Data Change
**2 total changes • 2 possible breaking changes**

| Data Model(s) | Change type | Old | New | Notes |
| ------------- | ----------- | --- | --- | ----- |
| [netsuite2__balance_sheet](https://fivetran.github.io/dbt_netsuite/#!/model/model.netsuite.netsuite2__balance_sheet)<br>[netsuite2__income_statement](https://fivetran.github.io/dbt_netsuite/#!/model/model.netsuite.netsuite2__income_statement)<br>[netsuite2__transaction_details](https://fivetran.github.io/dbt_netsuite/#!/model/model.netsuite.netstuite2__transaction_details)<br>[stg_netsuite2__accounting_period_fiscal_cal](https://fivetran.github.io/dbt_netsuite/#!/model/model.netsuite.stg_netsuite2__accounting_period_fiscal_cal)  | New column | | `accounting_period_full_name` | Adds the full name field from the accounting period fiscal calendar source table, providing descriptive period names like "FY2023 : Q1 2023". |

## Feature Update
- When `netsuite2__using_to_subsidiary` is enabled, `netsuite2__balance_sheet` applies each transaction’s `to_subsidiary` fiscal calendar. If `to_subsidiary` is `null`, the model falls back to the fiscal calendar of the transaction’s `subsidiary_id`.
- Increases the required dbt version upper limit to v3.0.0

## Under the Hood
- Adds `full_name` column to the `get_accountingperiodfiscalcalendars_columns` macro to support the new staging model field.
- Updates integration test seed data to include sample `full_name` values for testing the new functionality.
- In `netsuite2__balance_sheet`, combines variables `netsuite2__using_to_subsidiary` and `netsuite2__using_exchange_rate` into `using_to_subsidiary_and_exchange_rate` to simplify configuration.

## Contributors
- [@jmongerlyra](https://github.com/jmongerlyra) ([PR #183](https://github.com/fivetran/dbt_netsuite/pull/183))

# dbt_netsuite v1.2.1
[PR #186](https://github.com/fivetran/dbt_netsuite/pull/186) includes the following updates:

## Quickstart Update
- Adds `netsuite2__entity_subsidiary_relationships` to the `public_models` section of the `quickstart.yml`, so it is available to run in Quickstart for Fivetran customers.

# dbt_netsuite v1.2.0

[PR #185](https://github.com/fivetran/dbt_netsuite/pull/185) includes the following updates:

## Schema/Data Change (--full-refresh required after upgrading)
**1 total change • 1 possible breaking change**

| Data Model(s) | Change type | Old | New | Notes |
| ------------- | ----------- | --- | --- | ----- |
| [netsuite2__transaction_details](https://fivetran.github.io/dbt_netsuite/#!/model/model.netsuite.netsuite2__transaction_details) | New columns | | `converted_amount_raw`<br>`transaction_amount_raw`<br>`transaction_line_amount_raw` | Adds raw amount fields without sign adjustments, providing access to original amounts as recorded in the source system. These fields complement the existing sign-adjusted amount fields.<br><br>**Breaking change**: If you already include `amount` or `netamount` from `transaction_lines` via the [passthrough columns](https://github.com/fivetran/dbt_netsuite/blob/main/README.md#passing-through-additional-fields) variable `transaction_lines_pass_through_columns`, remove them from the list to avoid duplicate column errors.<br><br>A full refresh is required after upgrading because the incremental model schema needs to be reset to accommodate the new columns. |

## Documentation
- Enhanced documentation for amount fields in `netsuite2__transaction_details` and `netsuite__transaction_details` to clarify that the sign is flipped for income and other income accounts to follow accounting conventions. All other accounts retain their original sign.

# dbt_netsuite v1.1.0

## Schema/Data Change
**7 total changes • 2 possible breaking changes**

| Data Model(s) | Change type | Old | New | Notes |
| ------------- | ----------- | ----| --- | ----- |
| `netsuite2__entity_subsidiary_relationships` | New model | | | Unified view combining customer and vendor subsidiary relationships |
| `netsuite2__transaction_details` | New columns | | `nexus_id`<br>`nexus_country`<br>`nexus_state`<br>`tax_agency_id`<br>`tax_agency_alt_name`<br>`is_nexus_override`<br>`is_tax_details_override`<br>`tax_point_date`<br>`is_tax_point_date_override` | Adds nexus-related tax information.<br><br>**Breaking change**: If you already include any of these fields via the [passthrough columns](https://github.com/fivetran/dbt_netsuite/blob/main/README.md#passing-through-additional-fields) variable `transactions_pass_through_columns`, remove them from the list to avoid duplicate column errors. |
| `stg_netsuite2__nexuses` | New model | | | Provides access to Netsuite tax nexus data with configurable pass-through columns. See the [README](https://github.com/fivetran/dbt_netsuite/blob/main/README.md#passing-through-additional-fields) for instructions on adding the pass-through columns. |
| `stg_netsuite2__customer_subsidiary_relationships` | New model | | | Maps customers to their associated subsidiaries |
| `stg_netsuite2__vendor_subsidiary_relationships` | New model | | | Maps vendors to their associated subsidiaries |
| `stg_netsuite2__transactions` | New columns | | `nexus_id`<br>`is_nexus_override`<br>`is_tax_details_override`<br>`tax_point_date`<br>`is_tax_point_date_override` | Adds nexus-related tax information.<br><br>**Breaking change**: If you already include any of these fields via the [passthrough columns](https://github.com/fivetran/dbt_netsuite/blob/main/README.md#passing-through-additional-fields) variable `transactions_pass_through_columns`, remove them from the list to avoid duplicate column errors. |
| `stg_netsuite2__vendors` | New column | | `entity_id` | For use in `netsuite2__entity_subsidiary_relationships`.<br><br>**Breaking change**: If you already include this field via the [passthrough columns](https://github.com/fivetran/dbt_netsuite/blob/main/README.md#passing-through-additional-fields) variable `vendors_pass_through_columns`, remove it from the list to avoid duplicate column errors.  |
| All models | New column | | `source_relation` | Identifies the source connection when using multiple Netsuite connectors |

## Feature Update
- **Union Data Functionality**: This release supports running the package on multiple Netsuite source connections. See the [README](https://github.com/fivetran/dbt_netsuite/tree/main?tab=readme-ov-file#step-4-define-database-and-schema-variables) for details on how to leverage this feature.
- **Entity-Subsidiary Relationships**: New end model `netsuite2__entity_subsidiary_relationships` provides a unified view of both customer and vendor subsidiary relationships with enhanced metadata including currency information. Unions and enhances data from `stg_netsuite2__customer_subsidiary_relationships` and `stg_netsuite2__vendor_subsidiary_relationships`.
- **Nexus Support**: Adds comprehensive support for Netsuite nexus data through new staging model `stg_netsuite2__nexuses` with configurable pass-through columns. See the [README](https://github.com/fivetran/dbt_netsuite/blob/main/README.md#passing-through-additional-fields) for instructions on how to configure them. 
- Adds Streamlit example to the README. See the [README](https://github.com/fivetran/dbt_netsuite/tree/main?tab=readme-ov-file#example-visualizations) for more details.

## Under the Hood
- Updates integration tests configuration and seed data references
- Updates the `get_*_columns` macros to return only the columns referenced by the corresponding staging model.

## Contributors:
- [@jmongerlyra](https://github.com/jmongerlyra) ([PR #171](https://github.com/fivetran/dbt_netsuite/pull/171))
- [@fivetran-poonamagate](https://github.com/fivetran-poonamagate) ([PR #104](https://github.com/fivetran/dbt_netsuite/pull/104))

# dbt_netsuite v1.0.0

[PR #168](https://github.com/fivetran/dbt_netsuite/pull/168) includes the following updates:

## Breaking Changes

### Source Package Consolidation
- Removed the dependency on the `fivetran/netsuite_source` package.
  - All functionality from the source package has been merged into this transformation package for improved maintainability and clarity.
  - If you reference `fivetran/netsuite_source` in your `packages.yml`, you must remove this dependency to avoid conflicts.
  - Any source overrides referencing the `fivetran/netsuite_source` package will also need to be removed or updated to reference this package.
  - Update any netsuite_source-scoped variables to be scoped to only under this package. See the [README](https://github.com/fivetran/dbt_netsuite/blob/main/README.md) for how to configure the build schema of staging models.
- As part of the consolidation, vars are no longer used to reference staging models, and only sources are represented by vars. Staging models are now referenced directly with `ref()` in downstream models.

### dbt Fusion Compatibility Updates
- Updated package to maintain compatibility with dbt-core versions both before and after v1.10.6, which introduced a breaking change to multi-argument test syntax (e.g., `unique_combination_of_columns`).
- Temporarily removed unsupported tests to avoid errors and ensure smoother upgrades across different dbt-core versions. These tests will be reintroduced once a safe migration path is available.
  - Removed all `dbt_utils.unique_combination_of_columns` tests.
  - Removed all `accepted_values` tests.
  - Moved `loaded_at_field: _fivetran_synced` under the `config:` block in `src_netsuite.yml`.

## Features
- Added pass through columns functionality to the `stg_netsuite__accounting_periods` and `stg_netsuite2__accounting_periods` models using a new `accounting_periods_pass_through_columns` variable. This allows users to pass through additional columns from the source accounting periods tables.
  - See the [README](https://github.com/fivetran/dbt_netsuite/blob/main/README.md#passing-through-additional-fields) for more details.
> Note: Columns specified by `accounting_periods_pass_through_columns` are not currently included in Netsuite transform models. Please open an [issue](https://github.com/fivetran/dbt_netsuite/issues) if you would like to see accounting period custom columns persisted downstream.

## Documentation
- Updated the [README](https://github.com/fivetran/dbt_netsuite?tab=readme-ov-file#passing-through-additional-fields) to include all available passthrough column variables and which models they materialize in. ([PR #163](https://github.com/fivetran/dbt_netsuite/pull/163))

## Under the Hood
- Updated conditions in `.github/workflows/auto-release.yml`.
- Added `.github/workflows/generate-docs.yml`.

# dbt_netsuite v0.20.0

[PR #162](https://github.com/fivetran/dbt_netsuite/pull/162) includes the following updates:

## Breaking Change for dbt Core < 1.9.6

> *Note: This is not relevant to Fivetran Quickstart users.*

Migrated `freshness` from a top-level source property to a source `config` in alignment with [recent updates](https://github.com/dbt-labs/dbt-core/issues/11506) from dbt Core ([Netsuite Source v0.13.0](https://github.com/fivetran/dbt_netsuite_source/releases/tag/v0.13.0)). This will resolve the following deprecation warning that users running dbt >= 1.9.6 may have received:

```
[WARNING]: Deprecated functionality
Found `freshness` as a top-level property of `netsuite` in file
`models/src_netsuite.yml`. The `freshness` top-level property should be moved
into the `config` of `netsuite`.
```

**IMPORTANT:** Users running dbt Core < 1.9.6 will not be able to utilize freshness tests in this release or any subsequent releases, as older versions of dbt will not recognize freshness as a source `config` and therefore not run the tests.

If you are using dbt Core < 1.9.6 and want to continue running Netsuite freshness tests, please elect **one** of the following options:
  1. (Recommended) Upgrade to dbt Core >= 1.9.6
  2. Do not upgrade your installed version of the `netsuite` package. Pin your dependency on v0.19.0 in your `packages.yml` file.
  3. Utilize a dbt [override](https://docs.getdbt.com/reference/resource-properties/overrides) to overwrite the package's `netsuite` source and apply freshness via the previous release top-level property route. This will require you to copy and paste the entirety of the previous release `src_netsuite.yml` file and add an `overrides: netsuite_source` property.

## Under the Hood
- Updates to ensure integration tests use latest version of dbt.

# dbt_netsuite v0.19.0

For Netsuite2, [PR #160](https://github.com/fivetran/dbt_netsuite/pull/160) includes the following updates: 

## Breaking Changes (full refresh required)
- Added optional `fiscalcalendar` source table to support accurate fiscal year start dates (currently defaulted to calendar year). This table, related models (`stg_netsuite2__fiscal_calendar_tmp` and `stg_netsuite2__fiscal_calendar`), and relevant adjustments within `int_netsuite2__accounting_periods` are disabled by default. To enable this feature:
  - Quickstart users: enable the fiscalcalendar table in the connection schema tab.
  - dbt Core users: enable the fiscalcalendar table in the connection schema tab and also set the `netsuite2__fiscal_calendar_enabled` variable to true (default is false).

## Under the Hood
- Added `fiscal_year_trunc` to `int_netsuite2__accounting_periods`, which returns the truncated calendar year (default) or fiscal year (if `netsuite2__fiscal_calendar_enabled` is enabled). This replaces the previous case statements in `netsuite2__balance_sheet` for reporting_accounting_periods and transaction_accounting_periods.
- Included the `netsuite2__fiscal_calendar_enabled` variable and `fiscalcalendar` source table configuration in the `quickstart.yml`.
- Created new `date_from_parts` and `get_month_number` macros to be used when calculating the results for the `fiscal_year_trunc` field.

# dbt_netsuite v0.19.0-a1

## Breaking Changes (full refresh required)
- Added optional `fiscalcalendar` source table to support accurate fiscal year start dates (currently defaulted to calendar year). This table, related models (`stg_netsuite2__fiscal_calendar_tmp` and `stg_netsuite2__fiscal_calendar`), and relevant adjustments within `int_netsuite2__accounting_periods` are disabled by default. To enable this feature:
  - Quickstart users: enable the fiscalcalendar table in the connection schema tab.
  - dbt Core users: enable the fiscalcalendar table in the connection schema tab and also set the `netsuite2__fiscal_calendar_enabled` variable to true (default is false).

## Under the Hood
- Added `fiscal_year_trunc` to `int_netsuite2__accounting_periods`, which returns the truncated calendar year (default) or fiscal year (if `netsuite2__fiscal_calendar_enabled` is enabled). This replaces the previous case statements in `netsuite2__balance_sheet` for reporting_accounting_periods and transaction_accounting_periods.
- Included the `netsuite2__fiscal_calendar_enabled` variable and `fiscalcalendar` source table configuration in the `quickstart.yml`.

# dbt_netsuite v0.18.0

## Fivetran Quickstart Updates
- Added the Netsuite (netsuite.com) output models in the `public_models` configuration of the `quickstart.yml`. This ensures the netsuite.com models are accessible in Quickstart. ([#157](https://github.com/fivetran/dbt_netsuite/pull/157))
  - The netsuite.com models include: 
    - `netsuite__balance_sheet`
    - `netsuite__income_statement`
    - `netsuite__transaction_details`

## Documentation
- Added Quickstart model counts to README. ([#156](https://github.com/fivetran/dbt_netsuite/pull/156))
- Corrected references to connectors and connections in the README. ([#156](https://github.com/fivetran/dbt_netsuite/pull/156))

# dbt_netsuite v0.17.2-a1

## Fivetran Quickstart Updates
- Added the Netsuite (netsuite.com) output models in the `public_models` configuration of the `quickstart.yml`. This ensures the netsuite.com models are accessible in Quickstart. ([#157](https://github.com/fivetran/dbt_netsuite/pull/157))
  - The netsuite.com models include: 
    - `netsuite__balance_sheet`
    - `netsuite__income_statement`
    - `netsuite__transaction_details`

## Documentation
- Added Quickstart model counts to README. ([#156](https://github.com/fivetran/dbt_netsuite/pull/156))
- Corrected references to connectors and connections in the README. ([#156](https://github.com/fivetran/dbt_netsuite/pull/156))

# dbt_netsuite v0.17.1
[PR #155](https://github.com/fivetran/dbt_netsuite/pull/155) includes the following updates: 

## Macro Updates
- Introduced a local version of the `persist_pass_through_columns` macro that directly calls the variables within our models. This removes the existing string-to-variable conversion and leads to cleaner parsing. 
  - This new macro has no functional changes from the previous macro and will not require customers to make any changes on their end.
- This new macro is applied to all end models with passthrough column functionality, and replaces the existing `persist_pass_through_columns` macro.
- Models impacted for both `netsuite__*` and `netsuite2__*` include `balance_sheet`, `income_statement`, `transaction_details`.
- The process for adding passthrough columns remains unchanged. [Consult the README](https://github.com/fivetran/dbt_netsuite?tab=readme-ov-file#optional-step-6-additional-configurations) for more details.

# dbt_netsuite v0.17.0

This release involves **breaking changes** and will require running a **full refresh**.

## Bug Fixes
- Adjusted the materialization of the `int_netsuite2__tran_with_converted_amounts` model **from incremental to [ephemeral](https://docs.getdbt.com/docs/build/materializations#ephemeral)** to resolve potential duplicate records in certain situations ([PR #153](https://github.com/fivetran/dbt_netsuite/pull/153)).
   - This simplification minimizes duplication risk with marginal performance impact.
> This is a **Breaking Change**, as `int_netsuite2__tran_with_converted_amounts` will no longer materialize in the warehouse.

## Feature Updates
- Added two fields to the `netsuite2__balance_sheet` and `netsuite2__income_statement` models to support reporting on amounts in the functional currency alongside consolidated (`converted_amount`) results ([PR #151](https://github.com/fivetran/dbt_netsuite/pull/151)):
  - `transaction_amount`
  - `subsidiary_currency_symbol`
> This change **will require running a full refresh**, as we are adding new fields to incrementally materialized models.

## Contributors
- [@jmongerlyra](https://github.com/jmongerlyra) ([PR #151](https://github.com/fivetran/dbt_netsuite/pull/151))

# dbt_netsuite v0.16.0
For Netsuite2, [PR #149](https://github.com/fivetran/dbt_netsuite/pull/149) includes the following updates: 

## Breaking Changes (Full Refresh Required)
- Revised the incremental logic of the `netsuite2__transaction_details` model to use `transaction_lines` CTE as the primary driver instead of `transactions`. 
  - This ensures all transaction lines are captured, including those synced after the parent transaction.
  - This also aligns with `transaction_lines` serving as the base CTE in the model, onto which all other CTEs are left-joined.
  - When the `balance_sheet_transaction_detail_columns` and `income_statement_transaction_detail_columns` variables are used in the `netsuite2__balance_sheet` and `netsuite2__income_statement` models, all transactions are now included during incremental runs. This ensures no transactions are missed, aligning with the changes made in the `netsuite2__transaction_details` model.
  - We still recommend running `dbt --full-refresh` periodically to maintain data quality of the models.

## Documentation
- Updated dbt documentation definitions.

# dbt_netsuite v0.15.0
For Netsuite2, [PR #144](https://github.com/fivetran/dbt_netsuite/pull/144) includes the following updates: 

## Breaking Changes (Full refresh required after upgrading)
- Corrected `account_number` field logic for the `netsuite2__balance_sheet` model to match the native Balance Sheet report within Netsuite:
  - Income statement accounts should use the account number of the system-generated retained earnings account. 
  - Cumulative Translation Adjustment (CTA) accounts should use the account number of the system-generated CTA account.
  - We modified the logic to ensure the account number is the retained earnings number for income statement accounts in the balance sheet, and CTA rather than null. 
  - Since this will change the `account_number`, a `--full-refresh` after upgrading will be required. 

## New Fields
- Added commonly used fields to each end model. They are listed in the below table.
- Also added foreign keys to each end model to make it easier for customers to join back to source tables for better insights.

| **Models**                | **New Fields**                                                                                                                                |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| [netsuite2__transaction_details](https://fivetran.github.io/dbt_netsuite/#!/model/model.netsuite.netsuite2__transaction_details)             | New fields:  `is_reversal`, `reversal_transaction_id`, `reversal_date`, `is_reversal_defer`, `is_eliminate`, `exchange_rate`, `department_full_name`,  `subsidiary_full_name`, `subsidiary_currency_symbol`, `transaction_line_amount`, `account_display_name`  <br> <br> New keys: `customer_id`, `vendor_id`, `class_id`, `location_id`, `department_id`, `currency_id`, `parent_account_id`, `vendor_category_id` (if `netsuite2__using_vendor_categories` is enabled)  |
| [netsuite2__balance_sheet](https://fivetran.github.io/dbt_netsuite/#!/model/model.netsuite.netsuite2__balance_sheet)            | New fields: `account_display_name`, `subsidiary_full_name`, `is_account_intercompany`,  `is_account_leftside` |
| [netsuite2__income_statement](https://fivetran.github.io/dbt_netsuite/#!/model/model.netsuite.netsuite2__income_statement)             |  New fields: `account_display_name` <br> <br>   New keys: `class_id`, `location_id`, `department_id` |


> **IMPORTANT**: All of the affected models have pass-through functionality. If you have already been using passthrough column variables to include the newly added fields (without aliases), you **MUST** remove the fields from your passthrough variable configuration in order to avoid duplicate column errors.
## Feature Updates
- You can now leverage passthrough columns in `netsuite2__transaction_details` to bring in additional fields from the `locations` and `subsidiaries` source tables. 
- To add additional columns to this model, do so by adding our pass-through column variables `locations_pass_through_columns` and `subsidiaries_pass_through_columns` to your `dbt_project.yml` file:

```yml
vars:
    locations_pass_through_columns: 
        - name: "location_custom_field"
    subsidiaries_pass_through_columns: 
        - name: "sub_field"
          alias: "subsidiary_field"
```
- For more details on how to passthrough columns, [please consult our README section](https://github.com/fivetran/dbt_netsuite/blob/main/README.md#passing-through-additional-fields). 
## Under the Hood
- Additional consistency tests added for each Netsuite2 end model in order to be used during integration test validations.
- Updated yml documentation with new fields.
## Contributors
- [@jmongerlyra](https://github.com/jmongerlyra) ([PR #136](https://github.com/fivetran/dbt_netsuite/pull/136))
- [@fastbarreto](https://github.com/fastbarreto) ([PR #124](https://github.com/fivetran/dbt_netsuite/pull/124))
# dbt_netsuite v0.14.0
For Netsuite2, [PR #138](https://github.com/fivetran/dbt_netsuite/pull/138) and [PR #132](https://github.com/fivetran/dbt_netsuite/pull/132) include the following updates: 
## Breaking Changes (Full refresh required after upgrading)
- Partitioned models have had the `partition_by` logic adjusted to include a granularity of a month. This change should only impact BigQuery warehouses and was applied to avoid the common `too many partitions` error users have experienced due to over-partitioning by day. Therefore, adjusting the partition to a monthly granularity will increase the partition windows and allow for more performant querying. 
- This change was applied to the following models:
  - `int_netsuite2__tran_with_converted_amounts`
  - `netsuite2__balance_sheet`
  - `netsuite2__income_statement`
  - `netsuite2__transaction_details`

## Upstream Netsuite Source Breaking Changes (Full refresh required after upgrading)
- Casted specific timestamp fields across all staging models as dates where the Netsuite UI does not perform timezone conversion. Keeping these fields as type timestamp causes issues in reporting tools that perform automatic timezone conversion.   
- Adds additional commonly used fields within the `stg_netsuite2__*` models. 
> **IMPORTANT**: Nearly all of the affected models have pass-through functionality. If you have already been using passthrough column variables to include the newly added fields (without aliases), you **MUST** remove the fields from your passthrough variable configuration in order to avoid duplicate column errors.
- Please refer to the [v0.11.0 `dbt_netsuite_source` release](https://github.com/fivetran/dbt_netsuite_source/releases/tag/v0.11.0) for more details regarding the upstream changes to view the fields that were added and impacted.

## Bug Fixes
- Updates logic in `netsuite2__transaction_details` to select the appropriate customer and vendor values based on the whether the transaction type is a customer invoice or credit, or a vendor bill or credit.
  - Customer fields impacted: `company_name`, `customer_city`, `customer_state`, `customer_zipcode`, `customer_country`, `customer_date_first_order`, `customer_external_id`.
  - Vendor fields impacted: `vendor_category_name`, `vendor_name`, `vendor_create_date`.

## Feature Updates
- New fields `customer_alt_name` and `vendor_alt_name` were introduced into `netsuite2__transaction_details`, after being added into the `stg_netsuite2__customers` and `stg_netsuite2__vendors` models in the most [recent release of `dbt_netsuite_source`](https://github.com/fivetran/dbt_netsuite_source/releases/tag/v0.11.0).  
- We added the `employee` model in the [`v0.11.0` release of `dbt_netsuite_source`](https://github.com/fivetran/dbt_netsuite_source/releases/tag/v0.11.0), which will materialize `stg_netsuite2__employees` from the source package by default.
  - Since this model is only used by a subset of customers, we've introduced the variable `netsuite2__using_employees` to allow users who don't utilize the `employee` table in Netsuite2 the ability to disable that functionality within your `dbt_project.yml`. This value is set to true by default. [Instructions are available in the README for how to disable this variable](https://github.com/fivetran/dbt_netsuite/?tab=readme-ov-file#step-5-disable-models-for-non-existent-sources-netsuite2-only).

## Under the Hood
- Consistency tests added for each Netsuite2 end model in order to be used during integration test validations.

## Contributors
- [@jmongerlyra](https://github.com/jmongerlyra) ([PR #131](https://github.com/fivetran/dbt_netsuite/pull/131))

# dbt_netsuite v0.13.0

For Netsuite2, [PR #116](https://github.com/fivetran/dbt_netsuite/pull/116) includes the following updates: 

## 🚨 Breaking Changes 🚨
> ⚠️ Since the following changes are breaking, a `--full-refresh` after upgrading will be required.
- Performance improvements:
  - Snowflake, Postgres, and Redshift destinations:
    - Added an incremental strategy for the following models:
      - `int_netsuite2__tran_with_converted_amounts`
      - `netsuite2__balance_sheet`
      - `netsuite2__income_statement`
      - `netsuite2__transaction_details`
  - Bigquery and Databricks destinations:
    - Due to the variation in pricing and runtime priorities for customers, by default we chose to materialize these models as tables instead of incremental materialization for Bigquery and Databricks. For more information on this decision, see the [Incremental Strategy section](https://github.com/fivetran/dbt_netsuite/blob/main/DECISIONLOG.md#incremental-strategy) of the DECISIONLOG.
    - To enable incremental materialization for these destinations, see the [Incremental Materialization section](https://github.com/fivetran/dbt_netsuite/blob/main/README.md#-adding-incremental-materialization-for-bigquery-and-databricks) of the README for instructions.

- To reduce storage, updated the default materialization of the upstream staging models to views. (See the [dbt_netsuite_source CHANGELOG](https://github.com/fivetran/dbt_netsuite_source/blob/main/CHANGELOG.md#dbt_netsuite_source-v0100) for more details.)

## 🎉 Features
- Added a default 3-day look-back to incremental models to accommodate late arriving records, based on the `_fivetran_synced_date` of transaction records. The number of days can be changed by setting the var `lookback_window` in your dbt_project.yml. See the [Lookback Window section of the README](https://github.com/fivetran/dbt_netsuite/blob/main/README.md#lookback-window) for more details. 
- Added macro `netsuite_lookback` to streamline the lookback calculation.

## Under the Hood:
- Added integration testing pipeline for Databricks SQL Warehouse.
- Included auto-releaser GitHub Actions workflow to automate future releases.

For Netsuite2, [PR #114](https://github.com/fivetran/dbt_netsuite/pull/114) includes the following updates:

##  Features
- Added the following columns to model `netsuite2__transaction_details`:
  - department_id
  - entity_id
  - is_closed
  - is_main_line
  - is_tax_line
  - item_id
  - transaction_number
- ❗Note: If you have already added any of these fields as passthrough columns to the `transactions_pass_through_columns`, `transaction_lines_pass_through_columns`, `accounts_pass_through_columns`, or `departments_pass_through_columns` vars, you will need to remove or alias these fields from the var to avoid duplicate column errors.

- Removed the unnecessary reference to `entities` in the `netsuite2__transaction_details` model.

## 📝 Documentation Update 📝
- [Updated DECISIONLOG](https://github.com/fivetran/dbt_netsuite/blob/main/DECISIONLOG.md#why-converted-transaction-amounts-are-null-if-they-are-non-posting) with our reasoning for why we don't bring in future-facing transactions and leave the `converted_amount` in transaction details empty. ([#115](https://github.com/fivetran/dbt_netsuite/issues/115))

## Contributors:
- [@FrankTub](https://github.com/FrankTub) ([#114](https://github.com/fivetran/dbt_netsuite/issues/114))

# dbt_netsuite v0.12.0
## 🎁 Official release for Netsuite2! 🎁
[PR #98](https://github.com/fivetran/dbt_netsuite/pull/98) is the official supported release of [dbt_netsuite v0.12.0-b1](https://github.com/fivetran/dbt_netsuite/releases/tag/v0.12.0-b1). 

## 📈 New Visualization Support (BigQuery & Snowflake users) 📊
- Our team has created the [Netsuite Streamlit app](https://fivetran-netsuite.streamlit.app/) to help you visualize the end reports created in this package! [See instructions here](https://github.com/fivetran/streamlit_netsuite) on how to fork our Streamlit repo and configure your own reports.

[PR #95](https://github.com/fivetran/dbt_netsuite/pull/95) (built upon [#90](https://github.com/fivetran/dbt_netsuite/issues/90)) introduces the following updates.

## 🚨 Breaking Changes 🚨
- Multi-book functionality is now disabled by default. To enable it, set the variable `netsuite2__multibook_accounting_enabled` to `true` in your `dbt_project.yml`. 
  - ❗Note:  The default behavior was updated due to addition of `accounting_book` fields. Depending on your Netsuite setup, **adding this field can significantly increase the row count of the end models**.
  - See additional details in the multi-book section below.

## 🎉 Features 🎉
### Model updates
- For more accurate categorization of accounts, accounts having the following `special_account_type_id` are now categorized as:

special_account_type_id | account_type_name | account_type_id
--- | --- | ---
retearnings | Retained Earnings | retained_earnings
cta-e | Cumulative Translation Adjustment | cumulative_translation_adjustment
cumultransadj | Cumulative Translation Adjustment | cumulative_translation_adjustment

- The below fields have been added for all configurations. 
  - If you are leveraging a `*_pass_through_columns` variable to include `accounting_period_id` or `subsidiary_id`, you may need to remove them to avoid a duplicate column error.

model | new cols
----- | -----
netsuite2__transaction_details | accounting_period_id <br> subsidiary_id <br> transaction_details_id
netsuite2__income_statement | income_statement_id
netsuite2__balance_sheet | balance_sheet_id <br> subsidiary_name <br> subsidiary_id

- `balance_sheet_id`, `income_statement_id`, and `transaction_details_id` are surrogate keys created for each end model. These keys are now tested for uniqueness and replaces the previous combination-of-columns tests for these models. 

- For detailed descriptions on the added columns, refer to our [dbt docs for this package](https://fivetran.github.io/dbt_netsuite/#!/overview/netsuite). 

### Multi-book
- Expanded `accounting_book` information that is included. As mentioned above, this feature is now disabled by default. To enable it, set the below variable to `true` in your `dbt_project.yml`. 
  - ❗Notes:  
    - If you choose to enable this feature, this will add rows for transactions for your non-primary accounting_book_ids, and any of your downstream use cases may need to be adjusted. 
    - The surrogate keys mentioned above are dynamically generated depending on your enabled/disabled features, so adding these rows should not cause test failures.
    - If you are leveraging a `*_pass_through_columns` variable to include the below columns, you may need to remove them to avoid a duplicate column error.
```yml
vars:
    netsuite2__multibook_accounting_enabled: true # False by default.
```
- The resulting fields added by enabling this feature are:

model | new cols
----- | -----
netsuite2__transaction_details | accounting_book_id <br> accounting_book_name
netsuite2__income_statement | accounting_book_id <br> accounting_book_name
netsuite2__balance_sheet | accounting_book_id <br> accounting_book_name 

### To_subsidiary
- Added the option to include `to_subsidiary` information in all end models. This feature is disabled by default, so to enable it, set the below variable to `true` in your `dbt_project.yml`. You will also need to be using exchange rates, which is enabled by default.
  - ❗Notes:  
    - If you choose to enable this feature, this will add rows for transactions where `to_subsidiary` is not a top-level subsidiary. Your downstream use cases may need to be adjusted. 
    - The surrogate keys mentioned above are dynamically generated depending on your enabled/disabled features, so adding these rows should not cause test failures.
    - If you are leveraging a `*_pass_through_columns` variable to include the below columns, you may need to remove them to avoid a duplicate column error.
```yml
vars:
    netsuite2__using_to_subsidiary: true # False by default.
```
- The resulting fields added by enabling this feature are:

model | new cols
----- | -----
netsuite2__transaction_details | to_subsidiary_id <br> to_subsidiary_name <br> to_subsidiary_currency_symbol
netsuite2__income_statement | to_subsidiary_id <br> to_subsidiary_name <br> to_subsidiary_currency_symbol
netsuite2__balance_sheet | to_subsidiary_id <br> to_subsidiary_name <br> to_subsidiary_currency_symbol

## 🚘 Under the hood 🚘
- Removed previously deprecated, empty model `int_netsuite2__consolidated_exchange_rates`.

## Contributors:
- [@jmongerlyra](https://github.com/jmongerlyra) ([#90](https://github.com/fivetran/dbt_netsuite/issues/90))
- [@rwang-lyra](https://github.com/rwang-lyra ) ([#90](https://github.com/fivetran/dbt_netsuite/issues/90))

# dbt_netsuite v0.12.0-b1
## 📈 New Visualization Support (BigQuery & Snowflake users) 📊
- Our team has created the [Netsuite Streamlit app](https://fivetran-netsuite.streamlit.app/) to help you visualize the end reports created in this package! [See instructions here](https://github.com/fivetran/streamlit_netsuite) on how to fork our Streamlit repo and configure your own reports.

## Beta Release Notes for Netsuite2

[PR #95](https://github.com/fivetran/dbt_netsuite/pull/95) (built upon [#90](https://github.com/fivetran/dbt_netsuite/issues/90)) introduces the following updates. These changes are released in beta format to encourage community feedback and insights before the final release.
## 🚨 Breaking Changes 🚨
- Multi-book functionality is now disabled by default. To enable it, set the variable `netsuite2__multibook_accounting_enabled` to `true` in your `dbt_project.yml`. 
  - ❗Note:  The default behavior was updated due to addition of `accounting_book` fields. Depending on your Netsuite setup, **adding this field can significantly increase the row count of the end models**.
  - See additional details in the multi-book section below.

## 🎉 Features 🎉
### Model updates
- For more accurate categorization of accounts, accounts having the following `special_account_type_id` are now categorized as:

special_account_type_id | account_type_name | account_type_id
--- | --- | ---
retearnings | Retained Earnings | retained_earnings
cta-e | Cumulative Translation Adjustment | cumulative_translation_adjustment
cumultransadj | Cumulative Translation Adjustment | cumulative_translation_adjustment

- The below fields have been added for all configurations. 
  - If you are leveraging a `*_pass_through_columns` variable to include `accounting_period_id` or `subsidiary_id`, you may need to remove them to avoid a duplicate column error.

model | new cols
----- | -----
netsuite2__transaction_details | accounting_period_id <br> subsidiary_id <br> transaction_details_id
netsuite2__income_statement | income_statement_id
netsuite2__balance_sheet | balance_sheet_id <br> subsidiary_name <br> subsidiary_id

- `balance_sheet_id`, `income_statement_id`, and `transaction_details_id` are surrogate keys created for each end model. These keys are now tested for uniqueness and replaces the previous combination-of-columns tests for these models. 

- For detailed descriptions on the added columns, refer to our [dbt docs for this package](https://fivetran.github.io/dbt_netsuite/#!/overview/netsuite). 

### multi-book
- Expanded `accounting_book` information that is included. As mentioned above, this feature is now disabled by default. To enable it, set the below variable to `true` in your `dbt_project.yml`. 
  - ❗Notes:  
    - If you choose to enable this feature, this will add rows for transactions for your non-primary accounting_book_ids, and any of your downstream use cases may need to be adjusted. 
    - The surrogate keys mentioned above are dynamically generated depending on your enabled/disabled features, so adding these rows should not cause test failures.
    - If you are leveraging a `*_pass_through_columns` variable to include the below columns, you may need to remove them to avoid a duplicate column error.
```yml
vars:
    netsuite2__multibook_accounting_enabled: true # False by default.
```
- The resulting fields added by enabling this feature are:

model | new cols
----- | -----
netsuite2__transaction_details | accounting_book_id <br> accounting_book_name
netsuite2__income_statement | accounting_book_id <br> accounting_book_name
netsuite2__balance_sheet | accounting_book_id <br> accounting_book_name 

### to_subsidiary
- Added the option to include `to_subsidiary` information in all end models. This feature is disabled by default, so to enable it, set the below variable to `true` in your `dbt_project.yml`. You will also need to be using exchange rates, which is enabled by default.
  - ❗Notes:  
    - If you choose to enable this feature, this will add rows for transactions where `to_subsidiary` is not a top-level subsidiary. Your downstream use cases may need to be adjusted. 
    - The surrogate keys mentioned above are dynamically generated depending on your enabled/disabled features, so adding these rows should not cause test failures.
    - If you are leveraging a `*_pass_through_columns` variable to include the below columns, you may need to remove them to avoid a duplicate column error.
```yml
vars:
    netsuite2__using_to_subsidiary: true # False by default.
```
- The resulting fields added by enabling this feature are:

model | new cols
----- | -----
netsuite2__transaction_details | to_subsidiary_id <br> to_subsidiary_name <br> to_subsidiary_currency_symbol
netsuite2__income_statement | to_subsidiary_id <br> to_subsidiary_name <br> to_subsidiary_currency_symbol
netsuite2__balance_sheet | to_subsidiary_id <br> to_subsidiary_name <br> to_subsidiary_currency_symbol

## 🚘 Under the hood 🚘
- Removed previously deprecated, empty model `int_netsuite2__consolidated_exchange_rates`.

## Contributors:
- [@jmongerlyra](https://github.com/jmongerlyra) ([#90](https://github.com/fivetran/dbt_netsuite/issues/90))
- [@rwang-lyra](https://github.com/rwang-lyra ) ([#90](https://github.com/fivetran/dbt_netsuite/issues/90))

# dbt_netsuite v0.11.0

## 🚨 Breaking Changes 🚨:
- This release includes a breaking change in the upstream `dbt_netsuite_source` dependency. Please refer to the respective [dbt_netsuite_source v0.8.0](https://github.com/fivetran/dbt_netsuite_source/releases/tag/v0.8.0) release notes for more information.

## 🐛 Bug Fixes 🐛:
- Adjusted our translation rate logic to calculate `converted_amount` in `netsuite__balance_sheet` and `netsuite2__balance_sheet`. 
  - The logic is adjusted so we examine the `general_rate_type` rather than `account_category`, as is intended by Netsuite definitions.
  - Historical and average rates now convert amounts into the `converted_amount_using_transaction_accounting_period`. Otherwise, it looks at `converted_amount_using_reporting_month`.
  - The `is_leftside` logic is added to make sure debit values are properly assigned as negative converted values if false and positive if true.
- Modified the Cumulative Translation Adjustment calculation within the `netsuite2__balance_sheet` model to be built upon referencing that the general_rate_type is either `historical` or `average` as opposed to checking that the account_category is `equity`.
  - This update more accurately reflects the behavior of how the Cumulative Translation Adjustment should be calculated. The `equity` check was not as robust and had an opportunity to generate an incorrect value. 

## Contributors:
- [@jmongerlyra](https://github.com/jmongerlyra) ([#75](https://github.com/fivetran/dbt_netsuite/issues/75))
- [@rwang-lyra](https://github.com/rwang-lyra ) ([#75](https://github.com/fivetran/dbt_netsuite/issues/75))
  
# dbt_netsuite v0.10.0
[PR #84](https://github.com/fivetran/dbt_netsuite/pull/84) includes the following updates:
## 🚨 Breaking Changes 🚨
- For **Netsuite2**: updated the following models to reference `account_type_id` instead of `type_name`:
  - int_netsuite2__tran_with_converted_amounts
  - netsuite2__balance_sheet
  - netsuite2__income_statement
  - netsuite2__transaction_details
- The above change was implemented for Netsuite2 because `type_name` was previously utilized to categorize records, which was causing issues for users that customized the `type_name` values. Utilizing the unique identifier `account_type_id` instead produces more accurate results in the final models. Below is a list of the account type name and type id pairings used (list also found [here](https://blog.prolecto.com/2013/09/10/netsuite-searchfilter-internal-account-type-codes/)):

Type Name |	Type ID
---- | ----
Accounts Receivable | AcctRec
Accounts Payable | AcctPay
Bank | Bank
Cost of Goods Sold | COGS
Credit Card | CredCard
Deferred Expense | DeferExpense
Deferred Revenue | DeferRevenue
Equity | Equity
Expense | Expense
Fixed Asset | FixedAsset
Income | Income
Long Term Liability | LongTermLiab
Non Posting | NonPosting
Other Asset | OthAsset
Other Current Asset | OthCurrAsset
Other Current Liability | OthCurrLiab
Other Expense | OthExpense
Other Income | OthIncome
Statistical | Stat
Unbilled Receivable | UnbilledRec

- We also added the following `account_type_id` values for use in model `netsuite2__balance_sheet` and its downstream models:

account_type_name |	account_type_id
---- | ----
Net Income | net_income
Retained Earnings | retained_earnings

## Under the Hood
- Removed `accepted_values` test from column `account_type_names` in model `netsuite2__transaction_details` since logic is now based on `account_type_id` instead, and type names can be changed by the user.
- Updated documents with descriptions for `account_type_id`

# dbt_netsuite v0.9.0

[PR #74](https://github.com/fivetran/dbt_netsuite/pull/74) includes the following updates:
## 🚨 Breaking Changes 🚨
- Removed the `int_netsuite2__consolidated_exchange_rates` model 
  - Originally the `accounting_book_id` field was brought into the `int_netsuite2__acctxperiod_exchange_rate_map` model via `int_netsuite2__consolidated_exchange_rates`, but this was resulting in duplicate records downstream in the `netsuite2__transaction_details` model due to the way it was being joined. Now we have brought in `accounting_book_id` (accountingbook) via the `stg_netsuite2__consolidated_exchange_rates` model, so we do not have a need for `int_netsuite2__consolidated_exchange_rates` 

## Test Updates
- Added `account_id` to the unique combination test for `netsuite2__balance_sheet`

# dbt_netsuite v0.8.1
[PR #73](https://github.com/fivetran/dbt_netsuite/pull/73) applies the following changes:

## 🎉 Feature Updates 🎉
- Introduces variable `netsuite2__using_exchange_rate` to allow users who don't utilize exchange rates in Netsuite2 the ability to disable that functionality, and return only the unconverted amount as the final converted amount.
- This variable will also disable upstream models utilizing exchange rates, since they only flow into the intermediate model that converts amounts into their default subsidiary currency.
- **IMPORTANT**: The `netsuite2__using_exchange_rate` variable has also been implemented in the [`dbt_netsuite_source` package](https://github.com/fivetran/dbt_netsuite), so be sure to set it globally by inserting this code into your `dbt_project.yml`:
```yml
vars:
  netsuite2__using_exchange_rate: false
```

- Updated documentation in `netsuite2.yml` to provide context on how disabling exchange rates impacts specific models. 

## 🔧 Under the Hood 🔩
- Incorporated the new `fivetran_utils.drop_schemas_automation` macro into the end of each Buildkite integration test job.
- Updated the pull request [templates](/.github).
# dbt_netsuite v0.8.0
[PR #66](https://github.com/fivetran/dbt_netsuite/pull/66) applies the following changes:

## 🚨 Breaking Changes 🚨 (Netsuite.com Endpoint Only)
- Adds `transaction_id` and `transaction_line_id` to the Netsuite (1) income statement and balance sheet models. These fields were already present in the Netsuite2 versions of these models. These columns are included in newly added Primary Key tests on the Netsuite (1) income statement and balance sheet models.
> **Note**: Ensure that neither of these columns are included in your `balance_sheet_transaction_detail_columns` or `income_statement_transaction_detail_columns` variables.

## Under the Hood
- Aligns join types in Netsuite end models with the joins in Netsuite2 end models.
- Adds new account type <> account category mappings in the `int_netsuite__transactions_with_converted_amounts`/`int_netsuite2__tran_with_converted_amounts` model. 
  - `Prepaid Expense` account types are treated as `Deferred Expense` accounts. 
  - `Non Posting` and `Statistical` account types will be placed in a new `Other` category.
- Adds an `accepted_values` test on the transaction detail end models that will raise a **warning** if unexpected account types are encountered. 
- Adds a [DECISIONLOG](https://github.com/fivetran/dbt_netsuite/DECISIONLOG.md).
- Updates README to include the `netsuite2__using_jobs` variable.
- Adds uniqueness and not-null tests to the Netsuite (1) income statement and balance sheet models. These tests were already present in the Netsuite2 models.

# dbt_netsuite v0.7.1

## 🎉 Feature Updates 🎉
- Now introducing...Databricks compatibility 🧱 ([PR #61](https://github.com/fivetran/dbt_netsuite/pull/61))

## Bug Fixes
- Adjustment to add persist pass_through_columns macro to Netsuite1 models ([#60](https://github.com/fivetran/dbt_netsuite/issues/60))

## Contributors
- [@kchiodo](https://github.com/kchiodo) ([#60](https://github.com/fivetran/dbt_netsuite/issues/60))

# dbt_netsuite v0.7.0

## 🚨 Breaking Changes 🚨:
[PR #53](https://github.com/fivetran/dbt_netsuite/pull/53) includes the following breaking changes:
- Dispatch update for dbt-utils to dbt-core cross-db macros migration. Specifically `{{ dbt_utils.<macro> }}` have been updated to `{{ dbt.<macro> }}` for the below macros:
    - `any_value`
    - `bool_or`
    - `cast_bool_to_text`
    - `concat`
    - `date_trunc`
    - `dateadd`
    - `datediff`
    - `escape_single_quotes`
    - `except`
    - `hash`
    - `intersect`
    - `last_day`
    - `length`
    - `listagg`
    - `position`
    - `replace`
    - `right`
    - `safe_cast`
    - `split_part`
    - `string_literal`
    - `type_bigint`
    - `type_float`
    - `type_int`
    - `type_numeric`
    - `type_string`
    - `type_timestamp`
    - `array_append`
    - `array_concat`
    - `array_construct`
- For `current_timestamp` and `current_timestamp_in_utc` macros, the dispatch AND the macro names have been updated to the below, respectively:
    - `dbt.current_timestamp_backcompat`
    - `dbt.current_timestamp_in_utc_backcompat`
- `packages.yml` has been updated to reflect new default `fivetran/fivetran_utils` version, previously `[">=0.3.0", "<0.4.0"]` now `[">=0.4.0", "<0.5.0"]`.
# dbt_netsuite v0.6.3
## Bug Fixes 🐞
- Adjustment within the `int_netsuite2_tran_lines_w_accounting_period` model to correctly filter **only** posting accounts. Previously this filter filtered for only non-posting accounts. In order to replicate a true income statement, the posting accounts should only be included downstream. ([#56](https://github.com/fivetran/dbt_netsuite/pull/56))

# dbt_netsuite v0.6.2

PR [#48](https://github.com/fivetran/dbt_netsuite/pull/48) includes the following updates to the dbt_netsuite package:
## Features 🎉 (affects Netsuite2 users only)
- Introduces the `netsuite2__multibook_accounting_enabled` and `netsuite2__using_vendor_categories` variables to disable their related source tables and downstream models.
  - `netsuite2__multibook_accounting_enabled` is `True` by default. Set it to `False` if you do not use the [Multi-Book Accounting](https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/book_3831565332.html) feature in Netsuite and/or do not have the `accountingbook` and `accountingbooksubsidiaries` source tables.
  - `netsuite2__using_vendor_categories` is `True` by default. Set it to `False` if you do not categorize vendors in Netsuite and/or do not have the `vendorcategory` source table.

## Bug Fixes 🐞
- Fixes the grain at which the `netsuite__transaction_details` model is tested (Netsuite.com users only).

# dbt_netsuite v0.6.1

## Bug Fixes 🐞
- Properly applies new passthrough column logic to allow for the use of `alias` and `transform_sql` (see v0.6.0 below). ([#43](https://github.com/fivetran/dbt_netsuite/issues/43))

# dbt_netsuite v0.6.0
🎉 [Netsuite2](https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/article_163465025391.html) Compatibility 🎉
PR [#41](https://github.com/fivetran/dbt_netsuite/pull/41) includes the following update to the dbt_netsuite package:
## 🚨 Breaking Changes 🚨
- The declaration of passthrough variables within your root `dbt_project.yml` has changed. To allow for more flexibility and better tracking of passthrough columns, you will now want to define passthrough columns in the following format:
> This applies to all passthrough columns within the `dbt_netsuite` package and not just the `customers_pass_through_columns` example.
```yml
vars:
  customers_pass_through_columns:
    - name: "my_field_to_include" # Required: Name of the field within the source.
      alias: "field_alias" # Optional: If you wish to alias the field within the staging model.
      transform_sql: "cast(field_alias as string)" # Optional: If you wish to define the datatype or apply a light transformation.
```
## Features 🎉
- Addition of the `netsuite_data_model` variable. This variable may either be `netsuite` (the original Netsuite.com connector endpoint) or `netsuite2` (the new Netsuite2 connector endpoint).
  - The variable is set to `netsuite` by default. If you wish to run the data models for the Netsuite2 connector, you may simply change the variable within your root dbt_project.yml to `netsuite2`.
- Postgres compatibility!
- Added identifier variables to each Netsuite.com and Netsuite2 source to enable dynamic source-table adjustments.
- Applied schema level tests to each Netsuite2 end model to ensure data validation.
- README updates for easier navigation and package use.
# dbt_netsuite v0.5.0
🎉 dbt v1.0.0 Compatibility 🎉
## 🚨 Breaking Changes 🚨
- Adjusts the `require-dbt-version` to now be within the range [">=1.0.0", "<2.0.0"]. Additionally, the package has been updated for dbt v1.0.0 compatibility. If you are using a dbt version <1.0.0, you will need to upgrade in order to leverage the latest version of the package.
  - For help upgrading your package, I recommend reviewing this GitHub repo's Release Notes on what changes have been implemented since your last upgrade.
  - For help upgrading your dbt project to dbt v1.0.0, I recommend reviewing dbt-labs [upgrading to 1.0.0 docs](https://docs.getdbt.com/docs/guides/migration-guide/upgrading-to-1-0-0) for more details on what changes must be made.
- Upgrades the package dependency to refer to the latest `dbt_netsuite_source`. Additionally, the latest `dbt_netsuite_source` package has a dependency on the latest `dbt_fivetran_utils`. Further, the latest `dbt_fivetran_utils` package also has a dependency on `dbt_utils` [">=0.8.0", "<0.9.0"].
  - Please note, if you are installing a version of `dbt_utils` in your `packages.yml` that is not in the range above then you will encounter a package dependency error.

# dbt_netsuite v0.1.0 -> v0.4.1
Refer to the relevant release notes on the Github repository for specific details for the previous releases. Thank you!
