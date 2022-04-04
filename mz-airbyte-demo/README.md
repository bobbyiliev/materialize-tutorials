# Using Materialize and Airbyte with MySQL and Redpanda/Kafka

This is a self-contained demo using [Materialize](https://materialize.com).

This demo would show you how to use Materialize with Airbyte to create a live dashboard.

For this demo, we are going to monitor the orders on our demo website and generate events that could, later on, be used to send notifications when a cart has been abandoned for a long time.

This demo is an extension of the [How to join PostgreSQL and MySQL in a live Materialized view](https://devdojo.com/bobbyiliev/how-to-join-mysql-and-postgres-in-a-live-materialized-view) tutorial but rather than using Debezium CDC, we are going to use Airbyte to incrementally extract the orders from MySQL over [CDC](https://materialize.com/docs/connect/materialize-cdc/).

## Diagram:

<img width="1442" alt="image" src="https://user-images.githubusercontent.com/21223421/158989609-45cd719d-7326-4a60-bc01-e75b663851dd.png">

## Prerequisites

Before you get started, you need to make sure that you have Docker and Docker Compose installed.

You can follow the steps here on how to install Docker:

> [Installing Docker](https://materialize.com/docs/third-party/docker/)

Note that Airbyte Cloud currently does not support Kafka as a destination, this is why we can only follow this demo with a self-hosted Airbyte instance.

## Running the demo

**Note that for Mac with M1, you might have some issues with the Airbyte due to the following issue:**

> https://github.com/airbytehq/airbyte/issues/2017

So I would recommend using an Ubuntu VM to run the demo.

<!-- ```
export DOCKER_BUILD_PLATFORM=linux/arm64
export DOCKER_BUILD_ARCH=arm64
export ALPINE_IMAGE=arm64v8/alpine:3.14
export POSTGRES_IMAGE=arm64v8/postgres:13-alpine
export JDK_VERSION=17
``` -->

Start all services:

```bash
docker-compose up -d
```

## Airbyte

Setup the Airbyte service by visiting `your_server_ip:8000` and then follow the instructions.

### Adding a source

We are going to use [MySQL](https://www.mysql.com/) as our source where we will be extracting the orders from.

Via the Airbyte UI, click on the `Sources` tab and click on the `Add new source` button.

Fill in the following details:
- Name: `orders`
- Source type: `MySQL`
- Host: `your_server_ip`
- Port: `3306`
- Database: `shop`
- Username: `airbyte`
- Password: `password`
- Disable SSL
- Replication Method: `CDC`

Finally, click on the `Setup source` button.

### Adding a destination

Next, add a destination to Airbyte which will be used to send the events to.

For this demo, we are going to use Redpanda but it will work just fine with Kafka.

Start by clicking on the `Destinations` tab and click on the `Add new destination` button and fill in the following details:

- Name: `redpanda`
- Destination type: `Kafka`

Next, fill up all of the required fields and click on the `Setup destination` button.

Depending on your needs you might want to change some of the settings, but for this demo, we are going to use the defaults.

The important things to note down for this demo are:

- The `Topic` is `orders`
- The `Bootstrap Servers` is `redpanda:9092`

Finally, click on the `Save` button.

### Set up a connection

Now that you have a source and a destination, you need to set up a connection between them. This is needed so that Airbyte can send the events from the source to the destination based on a specific schedule like every day, every hour, every 5 minutes, etc.

For this demo, we are going to use a 5-minute schedule. Hopefully, in the future, Airbyte will allow you to customize this and reduce the schedule to 1 minute for example.

Click on the `Connections` tab and click on the `Add new connection` button and fill in the following details:

- Set the 'Replication frequency' to `5 minutes`
- Set the 'Destination Namespace' to 'Mirror source structure'
- Set the source to `orders` and the 'Sync mode' to `Incremental`

<img width="984" alt="image" src="https://user-images.githubusercontent.com/21223421/158997265-6890282a-a997-495e-b723-265818c8ed24.png">

Next click on the 'Setup connection' button. And finally, click on the `Sync now` button to start the synchronization.

It might take a few minutes for the connection to be established and the events to be sent.

After the synchronization is done, you can see the events in the Redpanda topic that you have specified when you set up the destination. Let's take a look at how to do that!

## Check the Redpanda topic

To check the auto-generated topic, you can run the following commands:

- Access the Redpanda container:

```
docker-compose exec redpanda bash
```

- List the topics:

```
rpk topic list
```

- Consume the topic:

```
rpk topic consume orders_topic
```

Note that if you've used a different topic name during the initial setup, you need to change it in the commands above.

If you don't see the topic yet, it would be possible that you might have to wait a few extra minutes and also make sure that the `ordergen` service mock is up and running.

Once you've verified that the topic has the CDC events, you can proceed and set up Materialize.

## Create a Materialize `SOURCE`

Next, we need to create a `SOURCE` in Materialize.

You can do that by heading back to your terminal and running the following commands:

- Access the `mzcli` container:

```bash
docker-compose run mzcli
```

Or if you have `psql` installed:

```bash
psql -U materialize -h localhost -p 6875 materialize
```

Create a Kafka `SOURCE` by executing the following statement:

```sql
CREATE SOURCE airbyte_source
  FROM KAFKA BROKER 'redpanda:9092' TOPIC 'orders_topic'
  FORMAT BYTES;
```

> Note: change `orders_topic` to the topic you've specified during the Airbyte setup.

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
                        SELECT convert_from(data, 'utf8') AS data FROM airbyte_source
                    )
                )
            )
        )
    )
TO STDOUT;
```

You will see a stream of your data as Airbyte sends it to the destination and Materialize processes it with a very minimal, submillisecond delay.

For more information on how to use `TAIL`, check out this blog post by [Joaquin Colacci](https://twitter.com/joacocolacci): [Subscribe to changes in a view with TAIL in Materialize](https://materialize.com/subscribe-to-changes-in-a-view-with-tail-in-materialize/)

## Create a [Materialized View](https://materialize.com/docs/sql/create-materialized-view/)

Now that we have a `SOURCE` in Materialize, we can create a materialized `VIEW`. A materialized view, lets you retrieve incrementally updated results of your data using standard SQL queries very quickly.

To create a materialized view execute the following statement:

```sql
CREATE MATERIALIZED VIEW airbyte_view AS
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
                    SELECT convert_from(data, 'utf8') AS data FROM airbyte_source
                )
            )
        )
    );
```

Next, run a query to see the data:

```sql
SELECT * FROM airbyte_view;
```

To visualize the data, you can use a BI tool like [Metabase](https://materialize.com/docs/third-party/metabase/) or alternatively, as Materialize is Postgres wire-compatible, you can use your favorite programming language and build your own dashboard. For more information on the supported tools and integrations, check out the [Materialized Views documentation](https://materialize.com/docs/third-party/supported-tools/)

## Stop the demo

To stop the demo, run:

```bash
docker-compose down -v
```

## Useful links

- [Materialize](https://materialize.com/)
- [Airbyte](https://airbyte.io/)
- [Materialize Cloud](https://cloud.materialize.com/)
- [Materialize demos](https://materialize.com/docs/demos/)
- [Redpanda](https://redpanda.com/)

## Community

If you have any questions or comments, please join the [Materialize Slack Community](https://materialize.com/s/chat)!