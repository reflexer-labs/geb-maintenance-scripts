DECLARE DeployDate DEFAULT TIMESTAMP("2020-02-05 00:00:00+00");

DECLARE AddAuthorization DEFAULT "0x599a298163e1678bb1c676052a8930bf0b8a1261ed6e01b8a2391e55f7000102";
DECLARE RemoveAuthorization DEFAULT "0x8834a87e641e9716be4f34527af5d23e11624f1ddeefede6ad75a9acfc31b903";

CREATE TEMP FUNCTION
  PARSE_AUTH_EVENT(data STRING, topics ARRAY<STRING>)
  RETURNS STRUCT<`account` STRING>
  LANGUAGE js AS """
    var parsedEvent = {"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"account","type":"address"}],"name":"AddAuthorization","type":"event"};
    return abi.decodeEvent(parsedEvent, data, topics, false);
"""
OPTIONS
  ( library="https://storage.googleapis.com/ethlab-183014.appspot.com/ethjs-abi.js" );
  
  
WITH auth_events AS (
  SELECT address, data, topics, block_number, block_timestamp, log_index,transaction_hash FROM `bigquery-public-data.crypto_ethereum.logs`
    WHERE block_timestamp >= DeployDate
     AND ARRAY_LENGTH(topics) >= 1
     AND (topics[offset(0)] = AddAuthorization OR topics[offset(0)] = RemoveAuthorization)
),

auth_events_parsed AS (
  SELECT 
    block_number, 
    block_timestamp,
    log_index,
    transaction_hash, 
    address AS contract, 
    PARSE_AUTH_EVENT(data, topics).account AS account, 
    CASE 
      WHEN topics[offset(0)] = AddAuthorization THEN 1 
      WHEN topics[offset(0)] = RemoveAuthorization THEN 0 
     END AS isAuth
  FROM auth_events
),

auth_ranked AS (
    SELECT *, 
      ROW_NUMBER() OVER (PARTITION BY contract, account ORDER BY block_number DESC, log_index DESC) AS rank 
    FROM auth_events_parsed AS a
)

SELECT contract, account, isAuth FROM auth_ranked 
WHERE rank = 1 
ORDER BY contract, isAuth DESC