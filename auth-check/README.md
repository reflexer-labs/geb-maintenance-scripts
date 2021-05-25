# Authorization checker script

BigQuery script that pulls all AddAuthorization/RemoveAuthorization event from the chain since the geb system was deployed to determine the current authorization status for all contracts.
Note: this will include non geb realted contracts that have the same event ABI. We keep them to make sure we're not missing any event.