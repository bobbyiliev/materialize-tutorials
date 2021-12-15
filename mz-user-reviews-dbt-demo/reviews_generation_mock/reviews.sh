#!/bin/bash

#Initialize Debezium (Kafka Connect Component)

sleep 10
while true; do
    echo "Waiting for Debezium to be ready"
    sleep 0.1
    curl -s -o /dev/null -w "%{http_code}" http://debezium:8083/connectors/ | grep 200
    if [ $? -eq 0 ]; then
        echo "Debezium is ready"
        break
    fi
done

curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://debezium:8083/connectors/ -d @/reviews/register-mysql.json

##
# Reviews generation mock script
# Table details:
# - name: reviews
# - columns:
#   - id
#   - user_id
#   - review_text
#   - review_rating
#   - created_at
#   - updated_at
##

# Start generating reviews
id=1
while [[ ture ]] ; do

    # Define variables
    user_role=$(seq 1 4 | sort -R | head -n1)
    review_rating=$(seq 1 10 | sort -R | head -n1)
    review_text="Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."

    # Generate users
    mysql -h mysql -u mysqluser -pmysqlpw -e "INSERT INTO db.users (id, name, email, role_id) VALUES ( ${id}, 'user${id}', 'user${id}@demo.com', ${user_role} );" 2> /dev/null

    # Generate reviews
    mysql -h mysql -u mysqluser -pmysqlpw -e "INSERT INTO db.reviews (user_id, review_text, review_rating, created_at, updated_at) VALUES ( ${id}, '${review_text}', ${review_rating}, NOW(), NOW() );" 2> /dev/null

    # Increment id
    ((id=id+1))

done