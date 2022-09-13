# Start the demo

```bash
export DEBEZIUM_VERSION=1.9
docker-compose up -d
```

# Initialize database and insert test data

```bash
cat debezium-sqlserver-init/inventory.sql | docker-compose exec -T sqlserver bash -c '/opt/mssql-tools/bin/sqlcmd -U sa -P $SA_PASSWORD'
```

# Start SQL Server connector

```bash
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @register-sqlserver.json
```

# Access Materialize

```bash
psql -U materialize -h localhost -p 6875 materialize
```

# Create a source for the SQL Server connector

```sql
CREATE SOURCE sqlserver_source
  FROM KAFKA BROKER 'kafka:9092' TOPIC 'server1.dbo.customers'
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY 'http://schema-registry:8081'
  ENVELOPE DEBEZIUM;
```

# Create a view for the source

```sql
CREATE MATERIALIZED VIEW customers AS
  SELECT id, first_name, last_name, email
  FROM sqlserver_source;
```

# Modify records in the database via SQL Server client (do not forget to add `GO` command to execute the statement)
docker-compose -f exec sqlserver bash -c '/opt/mssql-tools/bin/sqlcmd -U sa -P $SA_PASSWORD -d testDB'

> UPDATE customers SET first_name = 'Anne Marie' WHERE id = 1004;
> GO

# Shut down the cluster
docker-compose down

# [Demo source](https://github.com/debezium/debezium-examples/blob/main/tutorial/docker-compose-sqlserver.yaml)

Debezium resources: https://debezium.io/documentation/reference/stable/tutorial.html