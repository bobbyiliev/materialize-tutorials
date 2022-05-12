#!/bin/bash

sleep 10

# Create Redpanda topic
rpk topic create users_topic
rpk topic create roles_topic

function generate_users () {
    for id in {1..10000} ; do
        ROLE_ID=$((RANDOM % 4 + 1))
        USER_DATA=$(jq -n --arg id "${id}" --arg username "user${id}" --arg email "user${id}@example.com" --arg role_id "${ROLE_ID}" '{id: $id, username: $username, email: $email, role_id: $role_id }' )
        echo ${USER_DATA} | rpk topic produce users_topic
    done
}

function generate_roles () {
    admin=$(jq -n --arg id "1" --arg name "admin" '{id: $id, name: $name }' )
    moderator=$(jq -n --arg id "2" --arg name "moderator" '{id: $id, name: $name }' )
    vip=$(jq -n --arg id "3" --arg name "vip" '{id: $id, name: $name }' )
    user=$(jq -n --arg id "4" --arg name "user" '{id: $id, name: $name }' )
    echo ${admin} | rpk topic produce roles_topic
    echo ${moderator} | rpk topic produce roles_topic
    echo ${vip} | rpk topic produce roles_topic
    echo ${user} | rpk topic produce roles_topic
}

function main () {
    generate_roles
    generate_users
}
main