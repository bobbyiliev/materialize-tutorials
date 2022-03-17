#!/bin/bash

##
# Orders generation mock script
# Table details:
# - name: orders
# - columns:
#   - id
#   - user_id
#   - order_status
#   - price
#   - created_at
#   - updated_at
##

# Start generating orders
while [[ ture ]] ; do

    # Generate orders for all users
    for user_id in {1..1000} ; do
        order_status=$(seq 0 1 | sort -R | head -n1)
        price=$(seq 1 100 | sort -R | head -n1)
        mysql -h mariadb -u airbyte -ppassword -e "INSERT INTO shop.orders (user_id, order_status, price) VALUES ( ${user_id}, ${order_status}, ${price} );"
        sleep 0.01
    done

done