# dbt_netsuite v0.10.0
[PR #84](https://github.com/fivetran/dbt_netsuite/pull/84)includes the following updates:
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

[PR #74](https://github.com/fivetran/dbt_netsuite/pull/74)includes the following updates:
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
