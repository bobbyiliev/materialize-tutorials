# MySQL -> Airbyte -> Kafka -> Materialize -> Live dashboard

This is a self-contained demo using [Materialize](https://materialize.com).

This demo would show you how to use Materialize with Airbyte to create a live dashboard.

For this demo, we are going to monitor the orders on our demo website and generate events that could, later on, be used to send notifications when a cart has been abandoned for a long time.

This demo is an extension of the [How to join PostgreSQL and MySQL in a live Materialized view](https://devdojo.com/bobbyiliev/how-to-join-mysql-and-postgres-in-a-live-materialized-view) tutorial but rather than using Debezium CDC, we are going to use Airbyte to incrementally extract the orders from MySQL over [CDC](https://materialize.com/docs/connect/materialize-cdc/).

## Diagram:

<img width="1442" alt="image" src="https://user-images.githubusercontent.com/21223421/158989609-45cd719d-7326-4a60-bc01-e75b663851dd.png">

## Running the demo

For Mac M1 make sure to run the follwoing:

```
export DOCKER_BUILD_PLATFORM=linux/arm64
export DOCKER_BUILD_ARCH=arm64
export ALPINE_IMAGE=arm64v8/alpine:3.14
export POSTGRES_IMAGE=arm64v8/postgres:13-alpine
export JDK_VERSION=17
```

> Note: I could not get the build to work on Mac M1 despite the above.

Start all services:

```bash
docker-compose up -d
```

## Airbyte

Setup the Airbyte service by visiting `your_server_ip:8080` and follow the instructions.

## Create a `SOURCE`

```bash
docker-compose run mzcli
```

Or if you have `psql` installed:

```bash
psql -U materialize -h localhost -p 6875 materialize
```

Create a `SOURCE`:

```sql
CREATE SOURCE json_source
  FROM KAFKA BROKER 'redpanda:9092' TOPIC 'shop_topic'
  FORMAT BYTES;
```

> Note: change `shop_topic` to the topic you've specified during the Airbyte setup.

Use `TAIL` to quickly see the data:

```sql
COPY (
    TAIL (
        SELECT
            CAST(data->>'_airbyte_data' AS JSON) AS data
        FROM (
            SELECT CAST(data AS jsonb) AS data
                FROM (
                    SELECT * FROM (
                        SELECT convert_from(data, 'utf8') AS data FROM json_source
                    )
                )
            )
        )
    )
TO STDOUT;
```

Next create a materialized view:

```sql
CREATE MATERIALIZED VIEW jsonified_kafka_source AS
  SELECT
    data->>'id' AS id,
    data->>'user_id' AS user_id,
    data->>'order_status' AS order_status,
    data->>'price' AS price,
    data->>'created_at' AS created_at,
    data->>'updated_at' AS updated_at
    FROM (
        SELECT
            CAST(data->>'_airbyte_data' AS JSON) AS data
        FROM (
            SELECT CAST(data AS jsonb) AS data
            FROM (
                SELECT * FROM (
                    SELECT convert_from(data, 'utf8') AS data FROM json_source
                )
            )
        )
    );
```

## Stop the demo

To stop the demo, run:

```bash
docker-compose down -v
```