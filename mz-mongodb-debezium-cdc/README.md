# MongoDB Debezium CDC + Materialize

WIP:

```
ERROR:  Incorrect type for Debezium value, expected Record, got Jsonb

{"subject":"dbserver1.inventory.customers-value","version":1,"id":4,"schema":"{\"type\":\"record\",\"name\":\"Envelope\",\"namespace\":\"dbserver1.inventory.customers\",\"fields\":[{\"name\":\"after\",\"type\":[\"null\",{\"type\":\"string\",\"connect.version\":1,\"connect.name\":\"io.debezium.data.Json\"}],\"default\":null},{\"name\":\"patch\",\"type\":[\"null\",{\"type\":\"string\",\"connect.version\":1,\"connect.name\":\"io.debezium.data.Json\"}],\"default\":null},{\"name\":\"filter\",\"type\":[\"null\",{\"type\":\"string\",\"connect.version\":1,\"connect.name\":\"io.debezium.data.Json\"}],\"default\":null},{\"name\":\"updateDescription\",\"type\":[\"null\",{\"type\":\"record\",\"name\":\"updatedescription\",\"namespace\":\"io.debezium.connector.mongodb.changestream\",\"fields\":[{\"name\":\"removedFields\",\"type\":[\"null\",{\"type\":\"array\",\"items\":\"string\"}],\"default\":null},{\"name\":\"updatedFields\",\"type\":[\"null\",{\"type\":\"string\",\"connect.version\":1,\"connect.name\":\"io.debezium.data.Json\"}],\"default\":null},{\"name\":\"truncatedArrays\",\"type\":[\"null\",{\"type\":\"array\",\"items\":{\"type\":\"record\",\"name\":\"truncatedarray\",\"fields\":[{\"name\":\"field\",\"type\":\"string\"},{\"name\":\"size\",\"type\":\"int\"}],\"connect.name\":\"io.debezium.connector.mongodb.changestream.truncatedarray\"}}],\"default\":null}],\"connect.name\":\"io.debezium.connector.mongodb.changestream.updatedescription\"}],\"default\":null},{\"name\":\"source\",\"type\":{\"type\":\"record\",\"name\":\"Source\",\"namespace\":\"io.debezium.connector.mongo\",\"fields\":[{\"name\":\"version\",\"type\":\"string\"},{\"name\":\"connector\",\"type\":\"string\"},{\"name\":\"name\",\"type\":\"string\"},{\"name\":\"ts_ms\",\"type\":\"long\"},{\"name\":\"snapshot\",\"type\":[{\"type\":\"string\",\"connect.version\":1,\"connect.parameters\":{\"allowed\":\"true,last,false,incremental\"},\"connect.default\":\"false\",\"connect.name\":\"io.debezium.data.Enum\"},\"null\"],\"default\":\"false\"},{\"name\":\"db\",\"type\":\"string\"},{\"name\":\"sequence\",\"type\":[\"null\",\"string\"],\"default\":null},{\"name\":\"rs\",\"type\":\"string\"},{\"name\":\"collection\",\"type\":\"string\"},{\"name\":\"ord\",\"type\":\"int\"},{\"name\":\"h\",\"type\":[\"null\",\"long\"],\"default\":null},{\"name\":\"tord\",\"type\":[\"null\",\"long\"],\"default\":null},{\"name\":\"stxnid\",\"type\":[\"null\",\"string\"],\"default\":null},{\"name\":\"lsid\",\"type\":[\"null\",\"string\"],\"default\":null},{\"name\":\"txnNumber\",\"type\":[\"null\",\"long\"],\"default\":null}],\"connect.name\":\"io.debezium.connector.mongo.Source\"}},{\"name\":\"op\",\"type\":[\"null\",\"string\"],\"default\":null},{\"name\":\"ts_ms\",\"type\":[\"null\",\"long\"],\"default\":null},{\"name\":\"transaction\",\"type\":[\"null\",{\"type\":\"record\",\"name\":\"ConnectDefault\",\"namespace\":\"io.confluent.connect.avro\",\"fields\":[{\"name\":\"id\",\"type\":\"string\"},{\"name\":\"total_order\",\"type\":\"long\"},{\"name\":\"data_collection_order\",\"type\":\"long\"}]}],\"default\":null}],\"connect.name\":\"dbserver1.inventory.customers.Envelope\"}"
```

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
