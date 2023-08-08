#!/bin/bash

# Variables
SECRET="some-secret-value" # The shared secret used to generate the HMAC signature
NAME="raspberry" # The name of the device
URL="https://4dofcj3e2j1r5zve6cle2olh9.us-east-1.aws.staging.materialize.cloud/api/webhook/materialize/public/my_webhook_source" # The URL of the webhook source


# Generate a random temperature number
function temperature(){
    temp=$(seq 40.1 83.1 | sort -R | head -n 1)
    echo $temp
}

# Get the current time
function timestamp(){
    time=$(TZ="UTC" date +"%Y-%m-%dT%H:%M:%S%z")
    echo $time
}

# Start generating data
while [[ true ]] ; do
    # Mock 50 Raspberry Pi devices
    for i in {1..50} ; do
        payload="{\"device\": \"${NAME}-${i}\",\"timestamp\": \"$(timestamp)\",\"temperature\": $(temperature)}"

        # Compute the HMAC signature for this payload
        signature=$(echo -n ${payload} | openssl dgst -sha256 -hmac "${SECRET}" -binary | base64)

        echo ${payload}

        # Send the data to the Materialize webhook source
        curl -X POST ${URL} \
             -H "Content-Type: application/json" \
             -H "x-signature: ${signature}" \
             -d "${payload}"

        sleep 0.1 # Sleep for half a second
    done
    sleep 1
done
