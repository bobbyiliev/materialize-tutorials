{{ config(materialized='source') }}

{% set source_name %}
    {{ mz_generate_name('users_raw') }}
{% endset %}

CREATE SOURCE {{ source_name }}
FROM KAFKA BROKER 'redpanda:9092' TOPIC 'mysql.db.users'
FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY 'http://redpanda:8081'
ENVELOPE DEBEZIUM;