# Materialize Binary + Redpanda Cloud

- Download your Redpanda CA certificate
- Store the CA certificate same directory as the `docker-compose.yml` file and name the certificate file `ca.crt`
- Update the details in the `boot.sql` file to match your environment:

```sql
CREATE SOURCE test_topic
  FROM KAFKA BROKER 'YOUR_KAFKA_BROKER' TOPIC 'your_topic' WITH (
      sasl_mechanisms = 'SCRAM-SHA-256',
      security_protocol = 'SASL_SSL',
      sasl_username = 'your_username',
      sasl_password = 'your_password',
      ssl_ca_location = '/mnt/ca.crt'
  )
  FORMAT TEXT;

CREATE MATERIALIZED VIEW test_mv AS
SELECT * FROM your_topic;
```

- Start the demo:

```
docker-compose up -d
```

- Check if the service is running:

```
docker ps -a
```

- Access Materialize:

```
psql -U materialize -h localhost -p 6875
```

- Query the data:

```sql
SELECT * FROM test_mv;
```