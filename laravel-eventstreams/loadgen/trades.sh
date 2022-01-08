#!/bin/bash

# This script is used to generate trades for the real-time trading demo.
# The required parameters are:
#  - the user id: random number between 1 and 10000
#  - the stock id: range from 1 to 25
#  - the volume: random number between 1 and 100
#  - the type: buy or sell

while true; do
    for user_id in {1..10000} ; do
        stock_id=$((RANDOM % 25 + 1))
        volume=$((RANDOM % 100 + 1))
        type=$((RANDOM % 2))
        if [ $type -eq 0 ]; then
            type="buy"
        else
            type="sell"
        fi
        echo "{\"user_id\": $user_id, \"stock_id\": $stock_id, \"volume\": $volume, \"type\": \"$type\"}"
        #curl -X POST http://app/trade -d "user_id=$user_id&stock_id=$stock_id&volume=$volume&type=$type"
        curl -X POST http://localhost/trade -d "user_id=$user_id&stock_id=$stock_id&volume=$volume&type=$type"
    done
done