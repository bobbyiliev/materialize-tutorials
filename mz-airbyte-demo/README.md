# MySQL -> Airbyte -> Kafka -> Materialize -> Live dashboard

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

```
docker-compose up -d
```

Let the ordergen service generate some orders and then stop the services:

```
docker-compose stop ordergen
```

## Airbyte

Setup the Airbyte service by visiting `your_server_ip:8080` and follow the instructions.

## Create a `SOURCE`

```
docker-compose run mzcli
```

Or if you have `psql` installed:

```
psql -U materialize -h localhost -p 6875 materialize
```

Create a `SOURCE`:

```
CREATE SOURCE json_source
  FROM KAFKA BROKER 'redpanda:9092' TOPIC 'shop_topic'
  FORMAT BYTES;
```

> Note: change `shop_topic` to the topic you've specified during the Airbyte setup.

Use `TAIL` to quickly see the data:

```
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

```
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