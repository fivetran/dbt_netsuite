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

- Removed the unnecessary reference to `entities` in the `netsuit2__transaction_details` model.

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
