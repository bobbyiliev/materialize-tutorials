#!/bin/bash

##
# Raspberry Pi Temperature Generation Mock Script
# On a Raspberry Pi, you would use the /opt/vc/bin/vcgencmd measure_temp command to show you the current temperature
##

if [[ -z ${NAME} ]] ; then
    NAME="raspberry"
fi

# Generate a random temperature number
function temperature(){
    temp=$(seq 40.1 83.1 | sort -R | head -n 1)
    echo $temp
}

# Get the current time
function timestamp(){
    time=$(date +%s)
    echo $time
}

# Start generating data
while [[ true ]] ; do
    # Mock 50 Raspberry Pi devices
    for i in {1..50} ; do

        echo ${NAME}-${i},$(timestamp),$(temperature)

        # Save the data into a PostgreSQL
        curl -X GET "http://tempapi:3333/temperature?name=${NAME}-${i}&timestamp=$(timestamp)&temperature=$(temperature)"

        sleep 0.04

    done
    sleep 1
done