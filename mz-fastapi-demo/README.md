# FastAPI and Materialize Demo

This is a self-contained demo of FastAPI and [Materialize](https://materialize.com).

This demo project contains the following components:

- [FastAPI](https://fastapi.tiangolo.com/): A fast, modern, and feature-rich framework for building APIs with Python.
- [Redpanda](https://redpanda.com/): Kafka® compatible event streaming platform written in C++.
- [Materialize](https://materialize.com/): A streaming database for real-time analytics.
- A mock service written in [BASH for producing records to a Redpanda topic](https://devdojo.com/bobbyiliev/how-to-produce-records-to-a-topic-in-redpanda-from-a-shell-script). The mock service simulates data of air quality readings of IoT devices.

## Diagram

![FastAPI and Materialize Demo](https://user-images.githubusercontent.com/21223421/153422573-ef8d360e-4c31-42fa-ae8f-4327741659e7.png)

## Running the demo

Clone the repository:

```shell
git clone https://github.com/bobbyiliev/materialize-tutorials.git
```

Access the FastAPI demo project directory:

```
cd mz-fastapi-demo
```

Pull all Docker images:

```
docker-compose pull
```

Build the project:

```
docker-compose build
```

Finally, run all containers:

```
docker-compose up
```

## Create the Materialize sources and views

Once the demo is running, you can create the Materialize sources and views.

Let's start by creating a Redpanda/Kafka [source](https://materialize.com/docs/sql/create-source/):

```sql
CREATE SOURCE sensors
FROM KAFKA BROKER 'redpanda:9092' TOPIC 'sensors'
FORMAT BYTES;
```

Then create a [non-materialized view](https://materialize.com/docs/sql/create-view/#memory) which you can think of essentially an alias that we will use to create our materialized views. The non-materialized views do not store the results of the query:

```sql
CREATE VIEW sensors_data AS
    SELECT
        *
    FROM (
        SELECT
            (data->>'id')::int AS id,
            (data->>'pm25')::double AS pm25,
            (data->>'pm10')::double AS pm10,
            (data->>'geo_lat')::double AS geo_lat,
            (data->>'geo_lon')::double AS geo_lon,
            (data->>'timestamp')::double AS timestamp
        FROM (
            SELECT CAST(data AS jsonb) AS data
            FROM (
                SELECT convert_from(data, 'utf8') AS data
                FROM sensors
            )
        )
    );
```

After that, create a materialized view that will hold all records in the last 10 minutes:

```sql
CREATE MATERIALIZED VIEW sensors_view AS
    SELECT
        *
    FROM sensors_data
    WHERE
        mz_logical_timestamp() < (timestamp*1000 + 100000)::numeric;
```

> Note that we are using the `mz_logical_timestamp()` function rather than the `now()` function. This is because in Materialize `now()` doesn’t represent the system time, as it does in most systems; it represents the time with timezone when the query was executed. It cannot be used when creating views. For more information, see the documentation [here](https://materialize.com/docs/sql/functions/now_and_mz_logical_timestamp/s).

Next, let's create materialized view that will only include data from the last second so we can see the dataflow and use it for our Server-Sent Events (SSE) demo later on:

```sql
CREATE MATERIALIZED VIEW sensors_view_1s AS
    SELECT
        *
    FROM sensors_data
    WHERE
        mz_logical_timestamp() < (timestamp*1000 + 6000)::numeric;
```

With that our materialized views are ready and we can visit the FastAPI demo project in the browser!

## FastAPI Demo

Finally, visit the FastAPI demo app via your browser:

- Endpoint for all records in the last 10 minutes:

http://localhost/sensors

- SSE Endpoint streaming the latest records as they are generated using [`TAIL`](https://materialize.com/docs/sql/tail):

http://localhost/stream

Example response:

![SSE FastAPI with Materialize](https://user-images.githubusercontent.com/21223421/153751873-fdf77049-d0ef-40aa-b097-303472d69703.gif)

## Materialize Cloud

If you want to run the demo on the cloud, you would need the following:

- A publicly accessible Redpanda/Kafka instance so that you can connect to it.
- A Materialize Cloud account. You can sign up for a free [Materialize Cloud](https://materialize.com/cloud) account to get started with Materialize Cloud.

If you already have that setup, you would need to make the following changes to the demo project:

- When creating the source, change the `redpanda:9092` to your Redpanda/Kafka instance:

```
CREATE SOURCE sensors
FROM KAFKA BROKER 'your_redpanda_instance:9092' TOPIC 'sensors'
FORMAT BYTES;
```

- Change the `DATABASE_URL` environment variable to your Materialize Cloud database URL and uncomment the certificate-specific environment variables in the `docker-compose.yml` file.
 in the `docker-compose.yml` file.

- Download the Materialize instance certificate files from your Materialize Cloud dashboard.

## Stop the demo

To stop the demo, run the following command:

```
docker-compose down -v
```

You can also stop only the data generation container:

```
docker-compose stop datagen
```

## Helpful Links

- [Materialize](https://materialize.com)
- [Materialize Cloud](https://materialize.com/cloud)
- [Redpanda](https://redpanda.com)
- [`CREATE SOURCE`](https://materialize.com/docs/sql/create-source/)
- [`CREATE VIEW`](https://materialize.com/docs/sql/create-view/)
- [`CREATE MATERIALIZED VIEW`](https://materialize.com/docs/sql/create-materialized-view/)

## Community

If you have any questions or comments, please join the [Materialize Slack Community](https://materialize.com/s/chat)!