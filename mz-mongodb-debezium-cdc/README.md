# MongoDB Debezium CDC + Materialize

WIP

## Overview

This demo shows how to use [Debezium](https://debezium.io/) to capture changes from a MongoDB database and stream them to [Redpanda](https://vectorized.io/redpanda) and [Materialize](https://materialize.com/).

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

## Running the demo

- Start the demo:

```bash
docker-compose up -d
```

- Initialize MongoDB replica set and insert some test data:

```
docker-compose exec mongodb bash -c '/usr/local/bin/init-inventory.sh'
```

- Start MongoDB connector

```bash
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @register-mongodb.json
```

- List the available topics:

```bash
docker-compose exec redpanda rpk topic list
```

- Consume messages from a topic:

```bash
docker-compose exec redpanda rpk topic consume dbserver1.inventory.customers
```

- Modify records in the database via MongoDB client

```bash
docker-compose exec mongodb bash -c 'mongo -u debezium -p dbz --authenticationDatabase admin inventory'
```

- Insert a new record

```js
db.customers.insert([
    { _id : NumberLong("1005"), first_name : 'Bob', last_name : 'Hopper', email : 'thebob@example.com', unique_id : UUID() }
]);
```

- Delete a record

```json
db.customers.deleteOne({ _id : NumberLong("1005") });
```

## Materialize

- Connect to Materialize

```bash
psql -U materialize -h localhost -p 6875
```

- Create a Kafka and CSR connections

```sql
CREATE CONNECTION rpk_conn
    FOR KAFKA
    BROKER 'redpanda:9092';

CREATE CONNECTION csr_conn
    FOR CONFLUENT SCHEMA REGISTRY
    URL 'http://redpanda:8081';
```

- Create a source

```sql
CREATE SOURCE mongodb_source
    FROM KAFKA CONNECTION rpk_conn
    (TOPIC 'dbserver1.inventory.customers')
    FORMAT AVRO
    USING CONFLUENT SCHEMA REGISTRY CONNECTION csr_conn
    ENVELOPE DEBEZIUM
    WITH (SIZE = '1');

SELECT * FROM mongodb_source;
```

## Shut down the demo

To shut down the demo and remove all data, run:

```bash
docker-compose down -v
```
