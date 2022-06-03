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
export PGPASSWORD="materialize"
export MZ_HOST="localhost"
export MZ_USER="materialize"
export REDPANDA_HOST="redpanda"
export POSTGRES_HOST="postgres"

# Clear the views and sources
psql "postgres://${MZ_USER}@${MZ_HOST}:6875/materialize" -c "DROP VIEW IF EXISTS towns_count;"
psql "postgres://${MZ_USER}@${MZ_HOST}:6875/materialize" -c "DROP VIEW IF EXISTS towns_view;"
psql "postgres://${MZ_USER}@${MZ_HOST}:6875/materialize" -c "DROP SOURCE IF EXISTS towns;"
psql "postgres://${MZ_USER}@${MZ_HOST}:6875/materialize" -c "DROP VIEW IF EXISTS towns_psql;"
psql "postgres://${MZ_USER}@${MZ_HOST}:6875/materialize" -c "DROP SOURCE IF EXISTS mz_source;"

# Function to check when records are ingested and equal to 10 million
function postgres_check_ingestion {
    psql "postgres://${MZ_USER}@${MZ_HOST}:6875/materialize" -c "CREATE SOURCE "mz_source" FROM POSTGRES CONNECTION 'user=postgres port=5432 host=${POSTGRES_HOST} dbname=postgres password=postgres' PUBLICATION 'mz_source';"
    # Create the materialized view
    psql "postgres://${MZ_USER}@${MZ_HOST}:6875/materialize" -c "CREATE MATERIALIZED VIEWS FROM SOURCE mz_source (towns as towns_psql);"
    psql "postgres://${MZ_USER}@${MZ_HOST}:6875/materialize" -c "CREATE MATERIALIZED VIEW towns_count AS SELECT COUNT(*) FROM towns_psql;"

    records=$(psql -U "bobby\@materialize.com" -h ${MZ_HOST} -p psql "postgres://${MZ_USER}@${MZ_HOST}:6875/materialize" -t -c "SELECT * FROM towns_count;" | grep -v "COUNT" | tr -d ' ')
    # Check if the number of records is equal to 10 million
    while [ $records -lt 10000000 ]
    do
        sleep 1
        records=$(psql -U "bobby\@materialize.com" -h 4sqwpy4xpyjbb9q4vbi15cn3j.eu-west-1.aws.materialize.psql "postgres://${MZ_USER}@${MZ_HOST}:6875/materialize" -t -c "SELECT * FROM towns_count;" | grep -v "COUNT" | tr -d ' ')
    done
}

# Function to check when records are ingested and equal to 10 million
function redpanda_check_ingestion {
    psql "postgres://${MZ_USER}@${MZ_HOST}:6875/materialize" -c "CREATE SOURCE towns FROM KAFKA BROKER '${REDPANDA_HOST}:9092' TOPIC 'pg_repl.shop.towns' FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY 'http://${REDPANDA_HOST}:8081' ENVELOPE DEBEZIUM;"
    # Create the materialized view
    psql "postgres://${MZ_USER}@${MZ_HOST}:6875/materialize" -c "CREATE MATERIALIZED VIEW towns_view AS SELECT * FROM towns;"
    psql "postgres://${MZ_USER}@${MZ_HOST}:6875/materialize" -c "CREATE MATERIALIZED VIEW towns_count as SELECT COUNT(*) FROM towns_view;"

    records=$(psql -U "bobby\@materialize.com" -h ${MZ_HOST} -p psql "postgres://${MZ_USER}@${MZ_HOST}:6875/materialize" -t -c "SELECT * FROM towns_count;" | grep -v "COUNT" | tr -d ' ')
    # Check if the number of records is equal to 10 million
    while [ $records -lt 10000000 ]
    do
        sleep 1
        records=$(psql -U "bobby\@materialize.com" -h 4sqwpy4xpyjbb9q4vbi15cn3j.eu-west-1.aws.materialize.psql "postgres://${MZ_USER}@${MZ_HOST}:6875/materialize" -t -c "SELECT * FROM towns_count;" | grep -v "COUNT" | tr -d ' ')
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
