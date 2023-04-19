# YugabyteDB + Debezium + Materialize Example

This example shows how to use [Debezium](https://debezium.io/) to stream data from [YugabyteDB](https://www.yugabyte.com/) to [Redpanda](https://vectorized.io/redpanda/) and then to [Materialize](https://materialize.com/).

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)
- [`psql`](https://www.postgresql.org/docs/9.1/app-psql.html) (Postgres CLI)

## Running the demo

- Clone the repository:

    ```bash
    git clone https://github.com/bobbyiliev/materialize-tutorials.git
    cd materialize-tutorials/mz-yugabytedb-debezium-example
    ```

- Start all of the services:

    ```bash
    docker-compose up -d
    ```

- Wait for the services to start up, check the Debezium logs:

    ```bash
    docker-compose logs -f debezium
    ```

- Create the table in YugabyteDB:

    > Note: change the IP_ADDRESS to your IP address

    ```
    docker exec -it yugabyte bash
    ```

    While inside the container, connect to the YugabyteDB instance:

    ```bash
    ./bin/ysqlsh -h $IP
    ```

    Create a test table:

    ```sql
    create table test (id int primary key, name text, days_worked bigint);
    insert into test values (1, 'John', 10);
    exit
    ```

    Again, while still inside the container, create a change data stream:

    ```bash
    ./bin/yb-admin --master_addresses ${IP}:7100 create_change_data_stream ysql.yugabyte
    -- copy stream id
    ```

    Exit the container.

- Create the connector
    > Note: change the IP_ADDRESS to your IP address

    ```bash
    curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" \
    localhost:8083/connectors/ \
    -d '{
        "name": "ybconnector",
        "config": {
            "connector.class": "io.debezium.connector.yugabytedb.YugabyteDBConnector",
            "database.hostname":"$IP_ADDRESS",
            "database.port":"5433",
            "database.user": "yugabyte",
            "database.password": "yugabyte",
            "database.dbname" : "yugabyte",
            "transforms":"unwrap,extract",
            "database.master.addresses": "$IP_ADDRESS:7100",
            "transforms.unwrap.type":"io.debezium.connector.yugabytedb.transforms.PGCompatible",
            "transforms.unwrap.drop.tombstones":"false",
            "transforms.extract.type":"io.debezium.transforms.ExtractNewRecordState",
            "transforms.extract.drop.tombstones":"false",
            "transforms": "unwrap",
            "transforms.unwrap.delete.handling.mode": "rewrite",
            "database.server.name": "dbserver1",
            "table.include.list":"public.test",
            "database.streamid":"096c4cf1ca4c4cf4b7672ae80509a0ff",
            "snapshot.mode":"never"
        }
    }'
    ```

- Again access the container and insert some data:

    ```bash
    docker exec -it yugabyte bash
    ./bin/ysqlsh -h $IP
    ```

    Insert some data:

    ```sql
    insert into test values (2, 'Jane', 20);
    insert into test values (3, 'Bob', 30);
    ```

    Exit the container.

- Access to the Redpanda container:

    ```bash
    docker exec -it redpanda bash

    # Create if the topic exists

    rpk topic list

    # Output
    NAME                   PARTITIONS  REPLICAS
    _schemas               1           1
    dbserver1.public.test  1           1
    my_connect_configs     1           1
    my_connect_offsets     25          1
    my_connect_statuses    5           1
    ```

- Access Materialize:

    ```bash
    psql -h localhost -p 6875 -U materialize
    ```

    And run the following query:

    ```sql
    -- SQL:
    CREATE CONNECTION rpk_conn
    FOR KAFKA
    BROKER 'redpanda:9092';

    CREATE CONNECTION csr_conn
    FOR CONFLUENT SCHEMA REGISTRY
    URL 'http://redpanda:8081';

    CREATE SOURCE yugabyte
    FROM KAFKA CONNECTION rpk_conn
    (TOPIC 'dbserver1.public.test')
    FORMAT AVRO
    USING CONFLUENT SCHEMA REGISTRY CONNECTION csr_conn
    ENVELOPE DEBEZIUM
    WITH (SIZE = '1');

    select * from yugabyte;
    ```
