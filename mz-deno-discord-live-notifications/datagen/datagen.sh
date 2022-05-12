#!/bin/bash

sleep 10

# Create Redpanda topic
rpk topic create reviews_topic

function generate_reviews () {

    review_text="Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."

    # Infinite loop to produce data
    while true ; do

        for id in {1..10000} ; do
            created_at=$(date +%s)
            review_rating=$(seq 1 10 | sort -R | head -n1)
            JSON_STRING=$( jq -n --arg user_id "${id}" --arg rating "${review_rating}" --arg review_text "${review_text}" --arg created_at "${created_at}" '{user_id: $user_id, rating: $rating, review_text: $review_text, created_at: $created_at }' )
            # Send the message
            echo ${JSON_STRING} | rpk topic produce reviews_topic
            sleep 1
        done

    done

}

function main () {
    generate_reviews
}
main