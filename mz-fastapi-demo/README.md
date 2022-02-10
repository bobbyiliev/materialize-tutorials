# FastAPI and Materialize Demo

Components:

- [FastAPI](https://fastapi.tiangolo.com/)
- [Materialize](https://materialize.com/)
- [Redpanda](https://redpanda.com/)

## Diagram

![FastAPI and Materialize Demo](https://user-images.githubusercontent.com/21223421/153421516-e1453b97-86e0-471e-b5ec-ede4b608e2f0.png)

## Running the demo

Clone the repository:

```shell
git clone https://github.com/bobbyiliev/materialize-tutorials.git

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

Finally, run the demo:

```
docker-compose up
```

## Create the Materialize sources and views

Start by creating a Redpanda/Kafka source:

```sql
CREATE SOURCE sensors
FROM KAFKA BROKER 'redpanda:9092' TOPIC 'sensors'
FORMAT BYTES;
```

Then create a non-materialized view which is essentially an alias that we will use to create our materialized views:

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

Create a materialized view for all of the sensors data:

```sql
CREATE MATERIALIZED VIEW sensors_view AS
    SELECT
        *
    FROM sensors_data;
```

Create materialized view that will only include data from the last second so we can see the dataflow:

```sql
CREATE MATERIALIZED VIEW sensors_view_1s AS
    SELECT
        *
    FROM sensors_data
    WHERE
        mz_logical_timestamp() < (timestamp*1000 + 6000)::numeric
    ;
```

Finally visit the FastAPI demo app via your browser:

- Endpoint for the last 1000 records:

http://localhost/sensors

- SSE Endpoint streaming the latest records as they are generated:

http://localhost/stream
