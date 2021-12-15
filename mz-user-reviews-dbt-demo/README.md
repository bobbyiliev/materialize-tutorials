# How to use dbt with Materialize

This is a self-contained demo using [Materialize](https://materialize.com/).

This demo would show you how to use dbt together with Materialize.

For this demo, we are going to monitor the reviews left by users on our demo website, and we will use dbt models to get a list of important users that left bad reviews so we could use this data and potentially reach out to them and improve our website.

![How to use dbt with Materialize](https://user-images.githubusercontent.com/21223421/146195691-e24401ab-20b5-43a2-b921-3dd6627d7f1f.png)

## Prerequisites

Before you get started, you need to make sure that you have Docker and Docker Compose installed.

You can follow the steps here on how to install Docker:

> [Installing Docker](https://materialize.com/docs/third-party/docker/)

Also, you would need to make sure that you have the `dbt` command installed:

> [Installing dbt](https://materialize.com/docs/third-party/dbt/)

## Overview

As shown in the diagram above we will have the following components:

- A mock service to continually generate reviews and users.
- The reviews and the users would be stored in a MySQL database.
- As the database writes occur, Debezium streams the changes out of MySQL to a Redpanda topic.
- We would then ingest this Redpanda topic into Materialize directly.
- After that, we will use dbt to transform the data and create a model that can be used to get a list of VIP users that left bad reviews.
- You could, later on, use the information and visualize it in a BI tool like Metabase.

> As a side note here, you would be perfectly fine using Kafka instead of Redpanda. I just like the simplicity that Redpanda brings to the table, as you can run a single Redpanda instance instead of all of the Kafka components.

## Running the demo

First, start by cloning the repository:

```
git clone https://github.com/bobbyiliev/materialize-tutorials.git
```

After that you can access the directory:

```
cd materialize-tutorials/mz-user-reviews-dbt-demo
```

Let's start by first running the Redpanda container:

```
docker-compose up -d redpanda
```

Build the images:

```
docker-compose build
```

Finally, start all of the services:

```
docker-compose up -d
```

In order to Launch the Materialize CLI, you can run the following command:

```
docker-compose run mzcli
```

> This is just a shortcut to a docker container with `postgres-client` pre-installed, if you already have `psql` you could run `psql -U materialize -h localhost -p 6875 materialize` instead.

As soon as the demo is running, the mock service will start generating reviews and users.

### Create a Materialize Kafka/Redpanda Source

Now that you're in the Materialize CLI, let's define the `users`, `roles` and `reviews` tables in the `mysql.db` database as Kafka/Redpanda sources:

```sql
CREATE SOURCE users
FROM KAFKA BROKER 'redpanda:9092' TOPIC 'mysql.db.users'
FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY 'http://redpanda:8081'
ENVELOPE DEBEZIUM;

CREATE SOURCE roles
FROM KAFKA BROKER 'redpanda:9092' TOPIC 'mysql.db.roles'
FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY 'http://redpanda:8081'
ENVELOPE DEBEZIUM;

CREATE SOURCE reviews
FROM KAFKA BROKER 'redpanda:9092' TOPIC 'mysql.db.reviews'
FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY 'http://redpanda:8081'
ENVELOPE DEBEZIUM;
```

If you were to check the available columns from the `reviews` source by running the following statement:

```sql
SHOW COLUMNS FROM reviews;
```

You would be able to see that, as Materialize is pulling the message schema data from the Redpanda registry, it knows the column types to use for each attribute:

```sql
     name      | nullable |   type
---------------+----------+-----------
 id            | f        | bigint
 user_id       | t        | bigint
 review_text   | t        | text
 review_rating | t        | integer
 created_at    | t        | text
 updated_at    | t        | timestamp
```

### Prepare dbt configuration

First, we will need to install the `dbt-materialize` plugin:

```
python3 -m venv dbt-venv
source dbt-venv/bin/activate
pip install dbt-materialize
```

After that, with your favorite text editor, open the `~/.dbt/project.yml` file and add the following lines:

```yaml
user_reviews:
  outputs:
    dev:
      type: materialize
      threads: 1
      host: localhost
      port: 6875
      user: materialize
      pass: pass
      dbname: materialize
      schema: analytics

  target: dev
```

After that to make sure that the connection to the Materialize container is working run:

```
dbt debug
```

Finally, we can use dbt to create materialized views on top of the 3 Redpanda/Kafka topics. To do so just run the following dbt command:

```
dbt run
```

This command generates executable SQL from our model files (found in the `models` directory of this project) and executes that SQL against the target database, creating our materialized views.

> Note: If you installed dbt-materialize in a virtual environment, make sure it's activated. If you don't have it installed, please revisit the setup above.

#### Verify the Materialized Views are created

Congratulations! You just used dbt to create materialized views in Materialize. You can verify the views were created from your psql shell connected to Materialize:

```sql
SHOW VIEWS FROM analytics;
```

Output:

```sql
        name
--------------------
 badreviews
 vipusers
 vipusersbadreviews
```

You can also verify the data is being pulled from Redpanda by running the following query a few times:

```sql
SELECT COUNTS(*) FROM vipusersbadreviews;
```

You will be able to see that the result changes each time you run the query meaning that the data is being pulled from Redpanda continuously without having to run `dbt run` again.

### Generate the dbt docs

Once we have our materialized views created, we can generate the dbt docs. To do so, run the following command:

```
dbt docs generate
```

After that you can serve the docs by running the following command:

```
dbt docs serve
```

Then visit the docs at http://localhost:8080/dbt/docs/.

## Metabase

In order to access the [Metabase](https://materialize.com/docs/third-party/metabase/) instance visit `http://localhost:3030` if you are running the demo locally or `http://your_server_ip:3030` if you are running the demo on a server. Then follow the steps to complete the Metabase setup.

Make sure to select Materialize as the source of the data.

Once ready you will be able to visualize your data just as you would with a standard PostgreSQL database.

## Stopping the Demo

To stop all of the services run the following command:

```
docker-compose down
```

## Conclusion

As you can see, this is a very simple example of how to use Materialize together with dbt. You can use Materialize to ingest data from a variety of sources and then stream it to a variety of destinations.

To learn more about dbt and Materialize, check out the documentation here:

- [dbt + Materialize demo: Running dbt’s jaffle_shop with Materialize](https://materialize.com/dbt-materialize-jaffle-shop-demo/)
- [dbt + Materialize: streaming Wikipedia data demo](https://github.com/MaterializeInc/materialize/blob/main/play/wikirecent-dbt/README.md)
- [Materialize and dbt docs](https://materialize.com/docs/guides/dbt/)

## Helpful resources:

* [`CREATE SOURCE: PostgreSQL`](https://materialize.com/docs/sql/create-source/postgres/)
* [`CREATE SOURCE`](https://materialize.com/docs/sql/create-source/)
* [`CREATE VIEWS`](https://materialize.com/docs/sql/create-views)
* [`SELECT`](https://materialize.com/docs/sql/select)