#!/bin/bash

sleep 10

# Create Redpanda topic
rpk topic create sensors

# Infinite loop to produce data
while true ; do

    # Simulate 10000 air quality sensors
    for id in {1..10000} ; do

        # Generate random values
        # PM is also called Particulate Matter or particle pollution
        ## PM2.5 refers to the atmospheric particulate matter that has a diameter of less than 2.5 micrometres, which is about 3% of the diameter of human hair.
        ## PM10 are the particles with a diameter of 10 micrometers and they are also called fine particles.
        pm25=$(($RANDOM % 100))
        pm10=$(($RANDOM % 100))

        timestamp=$(date +%s)
        # Random latitude and longitude
        geo_lat=$(seq -90 90 | shuf -n 1)
        geo_lon=$(seq -180 180 | shuf -n 1)

        JSON_STRING=$( jq -n --arg id "${id}" --arg pm25 "${pm25}" --arg pm10 "${pm10}" --arg timestamp "${timestamp}" --arg geo_lat "${geo_lat}" --arg geo_lon "${geo_lon}" '{id: $id, pm25: $pm25, pm10: $pm10, timestamp: $timestamp, geo_lat: $geo_lat, geo_lon: $geo_lon}' )
        # Send the message
        echo ${JSON_STRING} ; done | rpk topic produce sensors
    done
done
