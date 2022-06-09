#!/bin/bash

# Create Redpanda topic
rpk topic create score_topic

function generate_score () {


    # Infinite loop to produce data
    while true ; do

        for id in {1..6} ; do
            created_at=$(date +%s)
            score=$((RANDOM%5+1))
            JSON_STRING=$( jq -n --arg user_id "${id}" --arg score "${score}" --arg created_at "${created_at}" '{user_id: $user_id, score: $score, created_at: $created_at }' )
            # Send the message
            echo ${JSON_STRING} | rpk topic produce score_topic
            sleep 0.1
        done

    done

}

function main () {
    generate_score
}
main