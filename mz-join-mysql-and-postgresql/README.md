# Materialize Abandoned Cart Demo

This is a self-contained demo using [Materialize](https://materialize.com/).

This demo would show you how to use Materialize to keep an eye on your website orders and send you or your customers a notification when they have abandoned their cart for a long time without proceeding with their payment.

![mz-abandoned-cart-demo](https://user-images.githubusercontent.com/21223421/143267063-2dbb1ec2-d48d-4ba5-8da8-f0d9ac1404e4.png)

## Prerequisites

Before you get started, you need to make sure that you have Docker and Docker Compose installed.

You can follow the steps here on how to install Docker:

> [Installing Docker](https://materialize.com/docs/third-party/docker/)

## Overview

As shown in the diagram above we will have the following components:

- A mock service to continually generate orders.
- The orders would be stored in a MySQL database.
- As the database writes occur, Debezium streams the changes out of MySQL to a Redpanda topic.
- We also would have a Postgres database where we would get our users from.
- We would then ingest this Redpanda topic into Materialize directly along with the users from the Postgres database.
- In Materialize we will join our orders and users together, do some filtering and create a materialized view that shows the abandoned cart information.
- We will then create a sink to send the abandoned cart data out to a new Redpanda topic. 
- You could, later on, use the information from that new topic to send out notifications to your users and remind them that they have an abandoned cart.

> As a side note here, you would be perfectly fine using Kafka instead of Redpanda. I just like the simplicity that Redpanda brings to the table, as you can run a single Redpanda instance instead of all of the Kafka components.

## Running the demo

First, start by cloning the repository:

```
git clone https://github.com/bobbyiliev/mz-abandoned-cart-demo.git
```

After that you can access the directory:

```
cd mz-abandoned-cart-demo
```

Let's start by first running the Redpanda container:

```
docker-compose up -d redpanda
```

Build the images:

```
docker-compose build
```

Finally, start all of the services:

```
docker-compose up -d
```

In order to Launch the Materialize CLI, you can run the following command:

```
docker-compose run mzcli
```

> This is just a shortcut to a docker container with `postgres-client` pre-installed, if you already have `psql` you could run `psql -U materialize -h localhost -p 6875 materialize` instead.

### Create a Materialize Kafka Source

Now that you're in the Materialize CLI, let's define the `orders` tables in the `mysql.shop` database as Redpanda sources:

```sql
CREATE SOURCE orders
FROM KAFKA BROKER 'redpanda:9092' TOPIC 'mysql.shop.orders'
FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY 'http://redpanda:8081'
ENVELOPE DEBEZIUM;
```

If you were to check the available columns from the `orders` source by running the following statement:

```sql
SHOW COLUMNS FROM orders;
```

You would be able to see that, as Materialize is pulling the message schema data from the Redpanda registry, it knows the column types to use for each attribute:

```sql
    name      | nullable |   type
--------------+----------+-----------
 id           | f        | bigint
 user_id      | t        | bigint
 order_status | t        | integer
 price        | t        | numeric
 created_at   | f        | text
 updated_at   | t        | timestamp
```

### Create materialized views

Next, we will create our first Materialized View, to get all of the data from the `orders` Redpanda source:


```sql
CREATE MATERIALIZED VIEW orders_view AS
SELECT * FROM orders;
```

```sql
CREATE MATERIALIZED VIEW abandoned_orders AS
    SELECT
        user_id,
        order_status,
        SUM(price) as revenue,
        COUNT(id) AS total
    FROM orders_view
    WHERE order_status=0
    GROUP BY 1,2;
```

You can now use `SELECT * FROM abandoned_orders;` to see the results:

```sql
SELECT * FROM abandoned_orders;
```

For more information on creating materialized views, check out the [Materialized Views](https://materialize.com/docs/sql/create-materialized-view/) section of the Materialize documentation.

### Create Postgres source

To create a PostgreSQL Materialize Source run the following statement:

```sql
CREATE MATERIALIZED SOURCE "mz_source" FROM POSTGRES
CONNECTION 'user=postgres port=5432 host=postgres dbname=postgres password=postgres'
PUBLICATION 'mz_source';
```

A quick rundown of the above statement:

* `MATERIALIZED`: Materializes the PostgreSQL source’s data. All of the data is retained in memory and makes sources directly selectable.
* `mz_source`: The name for the PostgreSQL source.
* `CONNECTION`: The PostgreSQL connection parameters.
* `PUBLICATION`: The PostgreSQL publication, containing the tables to be streamed to Materialize.

Once we've created the PostgreSQL source, in order to be able to query the PostgreSQL tables, we would need to create views that represent the upstream publication’s original tables. In our case, we only have one table called `users` so the statement that we would need to run is:

```sql
CREATE VIEWS FROM SOURCE mz_source (users);
```

To see the available views execute the following statement:

```sql
SHOW FULL VIEWS;
```

Once that is done, you can query the new views directly:

```sql
SELECT * FROM users;
```

Next, let's go ahead and create a few more views.

### Create Kafka sink

[Sinks](https://materialize.com/docs/sql/create-sink/) let you send data from Materialize to an external source.

For this Demo, we will be using [Redpanda](https://materialize.com/docs/third-party/redpanda/).

Redpanda is a Kafka API-compatible and Materialize can process data from it just as it would process data from a Kafka source.

Let's create a materialized view, that will hold all of the high volume unpaid orders:

```sql
 CREATE MATERIALIZED VIEW high_value_orders AS
      SELECT
        users.id,
        users.email,
        abandoned_orders.revenue,
        abandoned_orders.total
      FROM users
      JOIN abandoned_orders ON abandoned_orders.user_id = users.id
      GROUP BY 1,2,3,4
      HAVING revenue > 2000;
```

As you can see, here we are actually joining the `users` view which is ingesting the data directly from our Postgres source, and the `abandond_orders` view which is ingesting the data from the Redpanda topic, together.

Let's create a Sink where we will send the data of the above materialized view:

```sql
CREATE SINK high_value_orders_sink
    FROM high_value_orders
    INTO KAFKA BROKER 'redpanda:9092' TOPIC 'high-value-orders-sink'
    FORMAT AVRO USING
    CONFLUENT SCHEMA REGISTRY 'http://redpanda:8081';
```

Now if you were to connect to the Redpanda container and use the `rpk topic consume` command, you will be able to read the records from the topic.

However, as of the time being, we won’t be able to preview the results with `rpk` because it’s AVRO formatted. Redpanda would most likely implement this in the future, but for the moment, we can actually stream the topic back into Materialize to confirm the format.

First, get the name of the topic that has been automatically generated:

```sql
SELECT topic FROM mz_kafka_sinks;
```

Output:

```sql
                              topic
-----------------------------------------------------------------
 high-volume-orders-sink-u12-1637586945-13670686352905873426
```

> For more information on how the topic names are generated check out the documentation [here](https://materialize.com/docs/sql/create-sink/#kafka-sinks).

Then create a new Materialized Source from this Redpanda topic:

```sql
CREATE MATERIALIZED SOURCE high_volume_orders_test
FROM KAFKA BROKER 'redpanda:9092' TOPIC ' high-volume-orders-sink-u12-1637586945-13670686352905873426'
FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY 'http://redpanda:8081';
```

> Make sure to change the topic name accordingly!

Finally, query this new materialized view:

```sql
SELECT * FROM high_volume_orders_test LIMIT 2;
```

Now that you have the data in the topic, you can have other services connect to it and consume it and then trigger emails or alerts for example.

## Metabase

In order to access the [Metabase](https://materialize.com/docs/third-party/metabase/) instance visit `http://localhost:3030` if you are running the demo locally or `http://your_server_ip:3030` if you are running the demo on a server. Then follow the steps to complete the Metabase setup.

Make sure to select Materialize as the source of the data.

Once ready you will be able to visualize your data just as you would with a standard PostgreSQL database.

## Stopping the Demo

To stop all of the services run the following command:

```
docker-compose down
```

## Helpful resources:

* [`CREATE SOURCE: PostgreSQL`](https://materialize.com/docs/sql/create-source/postgres/)
* [`CREATE SOURCE`](https://materialize.com/docs/sql/create-source/)
* [`CREATE VIEWS`](https://materialize.com/docs/sql/create-views)
* [`SELECT`](https://materialize.com/docs/sql/select)
