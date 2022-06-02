#!/bin/bash

set -euo pipefail

wait-for-it --timeout=600 postgres:5432
wait-for-it --timeout=60 redpanda:9092
wait-for-it --timeout=120 debezium:8083

cd /datagen

bash datagen.sh