# Decision Log

In creating this package, which is meant for a wide range of use cases, we had to take opinionated stances on a few different questions we came across during development. We've consolidated significant choices we made here, and will continue to update as the package evolves. 

## Testing Expected Account Type Values 

In the `int_netsuite2_tran_with_converted_amounts`/`int_netsuite2_tran_with_converted_amounts`, account types are bucketed into broader account _categories_. We bucket account types through a `case when` statement that hard-codes the mapping of each account type into its appropriate category. Thus, because this is hard-coded, we have added an `accepted_values` test on the transaction detail end models. It will raise a **warning** if unexpected account types are encountered. 