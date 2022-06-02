#!/bin/bash

##
# Script to test the time it takes to ingest data from
# Direct Postgres source vs a Kafka / Redpanda source.
##

# Check if arguments are passed
if [ $# -ne 1 ]; then
    echo "Usage: $0 <postgres|redpanda>"
    exit 1
fi

# Start time
start_time=$(date)
# Clear the views and sources
psql -U materialize -h localhost -p 6875 -c "DROP VIEW IF EXISTS towns_view;"
psql -U materialize -h localhost -p 6875 -c "DROP SOURCE IF EXISTS towns;"
psql -U materialize -h localhost -p 6875 -c "DROP VIEW IF EXISTS towns_psql;"
psql -U materialize -h localhost -p 6875 -c "DROP SOURCE IF EXISTS mz_source;"

# Function to check when records are ingested and equal to 10 million
function postgres_check_ingestion {
    psql -U materialize -h localhost -p 6875 -c "CREATE SOURCE "mz_source" FROM POSTGRES CONNECTION 'user=postgres port=5432 host=postgres dbname=postgres password=postgres' PUBLICATION 'mz_source';"
    # Create the materialized view
    psql -U materialize -h localhost -p 6875 -c "CREATE MATERIALIZED VIEWS FROM SOURCE mz_source (towns as towns_psql);"

    records=$(psql -U materialize -h localhost -p 6875 -t -c "SELECT COUNT(*) FROM towns_psql;" | grep -v "COUNT" | tr -d ' ')
    # Check if the number of records is equal to 10 million
    while [ $records -lt 10000000 ]
    do
        sleep 1
        records=$(psql -U materialize -h localhost -p 6875 -t -c "SELECT COUNT(*) FROM towns_psql;" | grep -v "COUNT" | tr -d ' ')
    done
}

# Function to check when records are ingested and equal to 10 million
function redpanda_check_ingestion {
    psql -U materialize -h localhost -p 6875 -c "CREATE SOURCE towns FROM KAFKA BROKER 'redpanda:9092' TOPIC 'pg_repl.shop.towns' FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY 'http://redpanda:8081' ENVELOPE DEBEZIUM;"
    # Create the materialized view
    psql -U materialize -h localhost -p 6875 -c "CREATE MATERIALIZED VIEW towns_view AS SELECT * FROM towns;"

    records=$(psql -U materialize -h localhost -p 6875 -t -c "SELECT COUNT(*) FROM towns_view;" | grep -v "COUNT" | tr -d ' ')
    # Check if the number of records is equal to 10 million
    while [ $records -lt 10000000 ]
    do
        sleep 1
        records=$(psql -U materialize -h localhost -p 6875 -t -c "SELECT COUNT(*) FROM towns_view;" | grep -v "COUNT" | tr -d ' ')
    done
}

# Check for user input
if [ "$1" == "postgres" ]; then
    echo "Checking number of records in the table... (it may take a few minutes)"
    # Time the ingestion of data from the Postgres source
    time postgres_check_ingestion
elif [ "$1" == "redpanda" ]; then
    echo "Checking number of records in the table... (it may take a few minutes)"
    # Time the ingestion of data from the Redpanda source
    time redpanda_check_ingestion
else
    echo "Please specify the source to test (postgres or redpanda):"
    echo "./test.sh [postgres|redpanda]"
fi

# End time
end_time=$(date)
# Result
echo "Start time: $start_time"
echo "End time: $end_time"
