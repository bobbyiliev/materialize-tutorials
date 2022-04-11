## Order Tracking Demo App - Materialize

This is a self-contained demo using [Materialize](https://materialize.com/) to process orders and display the delivery status and coordinates in real-time.


## Prerequisites

Before you get started, you need to make sure that you have Docker and Docker Compose installed.

You can follow the steps here on how to install Docker:

* [Install Docker](https://docs.docker.com/get-docker/)
* [Install Docker Compose](https://docs.docker.com/compose/install/)

## Diagram

![Order Tracking Demo App - Materialize](https://user-images.githubusercontent.com/21223421/162715764-13a1fbc9-033b-409e-8570-797eeed1476e.png)

## Running the Demo

Clone the repository and run the following command:

```bash
git clone https://github.com/bobbyiliev/materialize-tutorials.git
```

Then access the `mz-order-tracking-dashboard` directory and run the following command:

```bash
cd mz-order-tracking-dashboard
```

Then start the demo:

```bash
docker-compose up
```

Give it a few seconds to start up.

## Create a Redpanda topic

Once all services are running, you can create a Redpanda topic to receive order delivery coordinates.

```bash
docker-compose exec redpanda rpk topic create coordinates
```

## Access Materialize

First access the Materialize instance by running the following command:
```
docker-compose run mzcli
```

> Note: if you have `psql` installed, you could use it instead of `mzcli`: `psql -U materialize -h localhost -p 6875`

## Create the Materialize [Postgres Source](https://materialize.com/docs/sql/create-source/)

All orders are stored in a `orders` table in the Postgres container.

By using the [Direct Postgres source](https://materialize.com/docs/guides/cdc-postgres/#direct-postgres-source) you can connect your Postgres source directly to Materialize.

To create the Postgres source, run the following command:

```sql
CREATE MATERIALIZED SOURCE "mz_source" FROM POSTGRES
CONNECTION 'user=postgres port=5432 host=postgres dbname=postgres password=postgres'
PUBLICATION 'mz_source';
```

Next, create views for all the tables in the source:

```sql
CREATE VIEWS FROM SOURCE mz_source (users, orders, coordinates);
```

After, that let's create a view, that will store only the latest order for our user:

```sql
CREATE VIEW last_order AS SELECT * FROM orders ORDER BY id DESC LIMIT 1;
```

## Create the Redpanda/[Kafka Source](https://materialize.com/docs/sql/create-source/kafka/)

The demo app has a mock function that will simulate the delivery of orders. It will send the coordinates to the Redpanda topic every second. That way we can use Materialize to display the coordinates in real-time by processing the Redpanda topic.

To create the Kafka source execute the following statement:

```sql
CREATE SOURCE coordinates_source
  FROM KAFKA BROKER 'redpanda:9092' TOPIC 'coordinates'
  FORMAT BYTES;
```

We can use [`TAIL`](https://materialize.com/docs/sql/tail/) to quickly check the structure of the data:

```sql
COPY (
    TAIL (
        SELECT
            (data->>'latitude')::FLOAT AS latitude,
            (data->>'longitude')::FLOAT AS longitude,
            (data->>'user_id')::INT AS user_id,
            (data->>'order_id')::INT AS order_id,
            (data->>'distance')::FLOAT AS distance,
            data->>'timestamp' AS timestamp
        FROM (
            SELECT CAST(data AS jsonb) AS data
                FROM (
                    SELECT * FROM (
                        SELECT convert_from(data, 'utf8') AS data FROM coordinates_source
                    )
                )
            )
        )
    )
TO STDOUT;
```

Next we will create a NON-materialized View, which you can think of as kind of a reusable template to be used in other materialized view:

```sql
CREATE VIEW coordinates_view AS
    SELECT
        (data->>'latitude')::FLOAT AS latitude,
        (data->>'longitude')::FLOAT AS longitude,
        (data->>'user_id')::INT AS user_id,
        (data->>'order_id')::INT AS order_id,
        (data->>'distance')::FLOAT AS distance,
        data->>'timestamp' AS timestamp
    FROM (
        SELECT CAST(data AS jsonb) AS data
            FROM (
                SELECT * FROM (
                    SELECT convert_from(data, 'utf8') AS data FROM coordinates_source
                )
            )
        )
    ;
```

After that the materialized view to get the last coordinates of each order:

```sql
CREATE MATERIALIZED VIEW coordinates_mv AS
    SELECT DISTINCT ON (order_id)
        order_id,
        user_id,
        latitude,
        longitude,
        distance,
        timestamp
    FROM coordinates_view
    WHERE
        order_id IS NOT NULL
    GROUP BY
        order_id,
        user_id,
        latitude,
        longitude,
        distance,
        timestamp
    ORDER BY
        order_id,
        timestamp DESC
    ;
```

Lastly let's join the last order that we get from Postgres with the coordinates from Kafka:

```sql
CREATE VIEW last_order_with_coordinates AS
    SELECT
        o.id AS order_id,
        o.user_id AS user_id,
        o.status AS status,
        o.created_at AS created_at,
        o.updated_at AS updated_at,
        c.latitude AS latitude,
        c.longitude AS longitude,
        c.distance AS distance,
        c.timestamp AS timestamp
    FROM last_order o
    LEFT JOIN coordinates_mv c ON o.id = c.order_id
    ;
```

We are going to use the above view to display the last coordinates on the real-time dashboard.

## View the dashboard

Now that we have all the materialized views, we can access the dashboard via your browser:

> http://localhost:3333

You will see the following dashboard:

![Order Tracking Demo App - Materialize dashboard](https://user-images.githubusercontent.com/21223421/162720649-53b4e0bd-8a6e-463b-81df-71cf9361c580.png)

To place an order, click on the `Add New Order` button. This will trigger the following workflow:

- The order will be created in the Postgres database
- The order tracking coordinates will be sent to the Redpanda topic every second
- Materialize will then join the order with the coordinates and the order details
- Over SSE using `TAIL` we will be able to see the coordinates in real-time on the dashboard

![Order tracking demo dashboard - Materialize](https://user-images.githubusercontent.com/21223421/162725774-94aa3e71-ef41-49a5-afa5-3797ae25a7e1.gif)

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

## Community

If you have any questions or comments, please join the [Materialize Slack Community](https://materialize.com/s/chat)!