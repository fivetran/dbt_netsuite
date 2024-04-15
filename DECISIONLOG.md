# Decision Log

In creating this package, which is meant for a wide range of use cases, we had to take opinionated stances on a few different questions we came across during development. We've consolidated significant choices we made here, and will continue to update as the package evolves. 

## Testing Expected Account Type Values 

In the `int_netsuite__transactions_with_converted_amounts` model, account types are bucketed into broader account _categories_. We bucket account types through a `case when` statement that hard-codes the mapping of each account type into its appropriate category. Thus, because this is hard-coded, we have added an `accepted_values` test on the transaction detail end models. It will raise a **warning** if unexpected account types are encountered. 

## Creation of 'Other' Account Category for Non Posting and Statistical Account Types

As mentioned above, in the `int_netsuite__transactions_with_converted_amounts`/`int_netsuite2_tran_with_converted_amounts` models, account types are bucketed into broader account _categories_. There is no standard category for `Non Posting` and `Statistical` account types and transactions from these kinds of accounts are excluded from all financial reports. However, they are used for other workflows in Netsuite, so we have bucketed `Non Posting` and `Statistical` account types into a new `Other` account category.

## Incremental Strategy Selection

For incremental models, we have chosen the `delete+insert` strategy PostgreSQL, Redshift, and Snowflake destinations.

For Bigquery and Databricks, we have turned off incremental strategy by default since we did not want to cause unexpected warehouse costs for users. If you choose to enable the incremental materialization for these destinations, we have set it up to use `merge`. 

These strategies were selected since transaction records can be updated retroactively, and `merge` and `delete+insert` work well since they rely on a unique id to identify records to update or replace. 