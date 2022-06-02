#!/bin/bash

#Initialize Debezium (Kafka Connect Component)

while true; do
    echo "Waiting for Debezium to be ready"
    sleep 0.1
    curl -s -o /dev/null -w "%{http_code}" http://debezium:8083/connectors/ | grep 200
    if [ $? -eq 0 ]; then
        echo "Debezium is ready"
        break
    fi
done

curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://debezium:8083/connectors/ -d @/datagen/register-postgres.json

if [ $? -eq 0 ]; then
    echo "Debezium connector registered"
else
    echo "Debezium connector registration failed"
    exit 1
fi