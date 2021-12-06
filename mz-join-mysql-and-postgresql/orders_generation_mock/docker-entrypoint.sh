#!/bin/bash

set -euo pipefail

wait-for-it --timeout=60 mysql:3306
wait-for-it --timeout=60 redpanda:9092
wait-for-it --timeout=120 debezium:8083

cd /orders

bash orders.sh