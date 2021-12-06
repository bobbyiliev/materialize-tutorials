#!/bin/bash

#Initialize Debezium (Kafka Connect Component)

while true; do
    echo "Waiting for Debezium to be ready"
    sleep 0.1
    curl -s -o /dev/null -w "%{http_code}" http://debezium:8083/connectors/ | grep 200
    if [ $? -eq 0 ]; then
        echo "Debezium is ready"
        break
    fi
done

curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://debezium:8083/connectors/ -d @/orders/register-mysql.json

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
        mysql -h mysql -u mysqluser -pmysqlpw -e "INSERT INTO shop.orders (user_id, order_status, price) VALUES ( ${user_id}, ${order_status}, ${price} );"
        sleep 0.01
    done

done