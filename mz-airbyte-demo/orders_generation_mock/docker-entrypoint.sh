#!/bin/bash

set -euo pipefail

wait-for-it --timeout=60 mysql:3306
wait-for-it --timeout=60 redpanda:9092

cd /orders

bash orders.sh