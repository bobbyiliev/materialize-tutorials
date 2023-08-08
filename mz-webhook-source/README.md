## Introduction to Webhooks and Materialize Webhooks Source

### What Are Webhooks?

Webhooks are a method for augmenting or altering the behavior of a web page, or web application, with custom callbacks. These callbacks may be maintained, modified, and managed by third-party users and developers who may not necessarily be affiliated with the originating website or application.

A webhook delivers data to other applications as it happens, meaning you get data immediately. It's a way for different applications to communicate with each other automatically without any user intervention.

### Introduction to Materialize Webhooks Source

The new [Materialize webhook source](https://materialize.com/docs/sql/create-source/webhook) introduces a new way of ingesting data via webhooks. Webhook sources in Materialize expose a public URL that allows other applications to push data into Materialize. This enables real-time data streaming from various sources, like IoT devices or third-party services.

## Creating a Webhooks Source in Materialize

You can create a webhook source in Materialize using the [`CREATE SOURCE`](https://materialize.com/docs/sql/create-source/) SQL statement that specifies details like the source name, cluster, body format, and an optional check for validation.

### Validation

It is common practice to validate webhooks requests to ensure they're legitimate. The `CHECK` clause in Materialize allows you to define a boolean expression that's used to validate each request received by the source.

Here's an example SQL command to create a webhook source with validation:

```sql
-- Create a shared secret
CREATE SECRET my_webhook_shared_secret AS 'some-secret-value';

-- Create a cluster
CREATE CLUSTER my_webhook_cluster SIZE = 'xsmall', REPLICATION FACTOR = 1;

-- Create a webhook source with validation
CREATE SOURCE my_webhook_source IN CLUSTER my_webhook_cluster FROM WEBHOOK
  BODY FORMAT JSON
  CHECK (
    WITH (
      HEADERS, BODY AS request_body,
      SECRET my_webhook_shared_secret
    )
    decode(headers->'x-signature', 'base64') = hmac(request_body, my_webhook_shared_secret, 'sha256')
  );

```

> **Note**: Without a `CHECK` statement, all requests will be accepted. To prevent bad actors from inserting data, it is strongly encouraged to define a `CHECK` statement with your webhook sources.

The above example creates a webhook source named `my_webhook_source` in the `my_webhook_cluster` cluster. It uses the `JSON` body format and validates each request using the `CHECK` statement.

The public URL for this webhook source is `https://<HOST>/api/webhook/<database>/<schema>/<src_name>`:
- `<HOST>` is the hostname of the Materialize cluster.
- `<database>` is the name of the database where the source is created. Defaults to `materialize`.
- `<schema>` is the name of the schema where the source is created. Defaults to `public`.
- `<src_name>` is the name of the source. In this case, it's `my_webhook_source`.


## Understanding HMAC

HMAC (Hash-based Message Authentication Code) is a specific type of message authentication code involving a cryptographic hash function and a secret cryptographic key. It's used to verify both the data integrity and the authenticity of a message.

By using HMAC, you can ensure that the data being sent to your webhook source is coming from a trusted source. This is done by generating a signature using a shared secret and comparing it with the signature sent in the request.

### Example in Bash

Here's a Bash example to generate an HMAC signature:

```bash
#!/bin/bash

payload='{"username": "johndoe"}'
secret='some-secret-value'
signature=$(echo -n ${payload} | openssl dgst -sha256 -hmac "${secret}" -binary | base64)
```

A rundown of the above script:

- `payload` is the JSON payload that will be sent to the webhook source.
- `secret` is the shared secret used to generate the signature.
- `signature` is the HMAC signature generated using the `payload` and `secret` values.

### Example in Node.js

In Node.js, you can use the `crypto` module to achieve the same:

```js
const crypto = require('crypto');

const payload = '{"username": "johndoe"}';
const secret = 'some-secret-value';

const hmac = crypto.createHmac('sha256', secret);
hmac.update(payload);
const signature = hmac.digest('base64');
```

## Simulating IoT Data with a Bash Script

In the context of IoT, webhooks are extremely useful.

![](https://imgur.com/EnW33xM.png)

You can simulate data coming from IoT devices, such as Raspberry Pi, using a bash script.

```bash
#!/bin/bash

# Variables
SECRET="some-secret-value" # The shared secret used to generate the HMAC signature
NAME="raspberry" # The name of the device
URL="https://<HOST>/api/webhook/materialize/public/my_webhook_source" # The URL of the webhook source


# Generate a random temperature number
function temperature(){
    temp=$(seq 40.1 83.1 | sort -R | head -n 1)
    echo $temp
}

# Get the current time
function timestamp(){
    time=$(TZ="UTC" date +"%Y-%m-%dT%H:%M:%S%z")
    echo $time
}

# Start generating data
while [[ true ]] ; do
    # Mock 50 Raspberry Pi devices
    for i in {1..50} ; do
        payload="{\"device\": \"${NAME}-${i}\",\"timestamp\": \"$(timestamp)\",\"temperature\": $(temperature)}"

        # Compute the HMAC signature for this payload
        signature=$(echo -n ${payload} | openssl dgst -sha256 -hmac "${SECRET}" -binary | base64)

        echo ${payload}

        # Send the data to the Materialize webhook source
        curl -X POST ${URL} \
             -H "Content-Type: application/json" \
             -H "x-signature: ${signature}" \
             -d "${payload}"

        sleep 0.1 # Sleep for 100ms
    done
    sleep 1
done
```

This script leverages HMAC for authentication and constructs the JSON payloads as expected by the Materialize webhook source.

## Compute real-time analytics on IoT data

Let's create a view to cast the JSON payloads into columns with the correct data types:

```sql
CREATE VIEW sensors_data AS SELECT
    (body->>'device')::text AS "device",
    (body->>'timestamp')::timestamp AS "timestamp",
    (body->>'temperature')::float AS "temperature"
  FROM my_webhook_source;
```

After that we can create a materialized view to compute real-time analytics on the IoT data in the last 5 minutes:

```sql
CREATE MATERIALIZED VIEW sensors_data_5m AS SELECT
    device,
    timestamp,
    temperature,
    COUNT(*) AS "count",
    AVG(temperature) AS "avg_temperature"
  FROM sensors_data
  WHERE mz_now() < timestamp + INTERVAL '5 minutes'
  GROUP BY device, timestamp, temperature;
```

We can query the materialized view to get the latest data:

```sql
SELECT * FROM sensors_data_5m ORDER BY timestamp DESC LIMIT 10;
```

To subscribe to the `sensors_data_5m` materialized view, we can use the `SUBSCRIBE` command:

```sql
COPY (
    SUBSCRIBE TO sensors_data_5m
    WITH (SNAPSHOT = FALSE)
) TO STDOUT;
```

## Conclusion

Webhooks are a powerful tool to stream data between applications, and Materialize's webhooks source provides a seamless way to ingest this data in real time. By understanding the underlying concepts like HMAC and creating secure and validated webhooks, you can build robust data pipelines that leverage the full potential of real-time data processing. Whether you're simulating IoT device data or integrating third-party services, Materialize's webhooks source offers a flexible and efficient solution.
