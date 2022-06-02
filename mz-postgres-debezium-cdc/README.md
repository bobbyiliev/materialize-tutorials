# Materialize: Test ingestion of Postgres Debezium CDC vs Direct Postgres

This is a quick test to compare the ingestion of Postgres Debezium CDC vs Direct Postgres.

The Postgres init script generates 10 million rows of data.

## Running the demo

```
# Clone the repository:
git clone https://github.com/bobbyiliev/materialize-tutorials.git

# Access the directory:
cd materialize-tutorials/mz-postgres-debezium-cdc

# Build the images:
docker-compose build

# Then pull all of the other Docker images:
docker-compose pull

# Finally, start all of the services:
docker-compose up -d
```

Give the services some time to start up, check the Debezium logs:

```
docker-compose logs -f debezium
```

> Note, initially it takes Debezium ~10 minutes to export the data to Kafka. Depending on the server resources, this can vary.

Once ready, run the test:

```
# For Direct Postgres:
bash test.sh postgres
# For Redpanda/Kafka:
bash test.sh redpanda
```

## Results

Server details:
- CPU: 4 vCPU
- RAM: 8 GB
- dataflow workers: 2

Postgres + Debezium + Redpanda:

```
real	8m28.391s
user	0m5.014s
sys	0m2.250s

Start time: Thu Jun  2 17:16:34 UTC 2022
End time: Thu Jun  2 17:25:02 UTC 2022
```

Direct Postgres:

```
real	3m4.963s
user	0m0.189s
sys	0m0.127s

Start time: Thu Jun  2 17:13:13 UTC 2022
End time: Thu Jun  2 17:16:19 UTC 2022
```

## Helpful resources:

* [`CREATE SOURCE: PostgreSQL`](https://materialize.com/docs/sql/create-source/postgres?utm_source=bobbyiliev)
* [`Postgres + Kafka + Debezium`](https://materialize.com/docs/integrations/cdc-postgres/#kafka--debezium?utm_source=bobbyiliev)
* [`CREATE SOURCE`](https://materialize.com/docs/sql/create-source?utm_source=bobbyiliev)
* [`CREATE MATERIALIZED VIEW`](https://materialize.com/docs/sql/create-materialized-view?utm_source=bobbyiliev)

## Community

If you have any questions or comments, please join the [Materialize Slack Community](https://materialize.com/s/chat)!