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