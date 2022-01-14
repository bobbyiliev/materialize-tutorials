{{ config(materialized='source') }}

{% set source_name %}
    {{ mz_generate_name('reviews_raw') }}
{% endset %}

CREATE SOURCE {{ source_name }}
FROM KAFKA BROKER 'redpanda:9092' TOPIC 'mysql.db.reviews'
FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY 'http://redpanda:8081'
ENVELOPE DEBEZIUM;