# How to use dbt with Materialize

This is a self-contained demo using [Materialize](https://materialize.com/).

This demo shows you how to use [dbt](https://docs.getdbt.com/docs/introduction) together with Materialize.

For this demo, we are going to monitor the reviews left by users on a demo website, and use dbt to model our business logic, like getting a list of important users that left bad reviews. We will then explore how to use this data to potentially reach out to the flagged users and improve our website experience.

![How to use dbt with Materialize](https://user-images.githubusercontent.com/21223421/148790925-fff39499-d8a3-4b2e-8488-13f61265b0a0.png)

## Prerequisites

Before you get started, you need to make sure that you have Docker and Docker Compose installed.

You can follow the steps here on how to install Docker:

> [Installing Docker](https://materialize.com/docs/third-party/docker/)

Also, you would need to make sure that you have `dbt` (v0.18.1+) installed:

> [Installing dbt](https://materialize.com/docs/third-party/dbt/)

You can find the files for this demo in this [GitHub repository here](https://github.com/bobbyiliev/materialize-tutorials/blob/main/mz-user-reviews-dbt-demo/).

## Overview

As shown in the diagram above, we will have the following components:

- A mock service to continually generate reviews and users.
- The reviews and the users will be stored in a MySQL database.
- As the database writes occur, Debezium streams the changes out of MySQL to a Redpanda topic.
- We then ingest this Redpanda topic into Materialize directly.
- After that, we use dbt to define transformations on the data and create a model that lists any VIP users that left bad reviews.
- You could, later on, visualize the data in a BI tool like Metabase.

> As a side note here, you would be perfectly fine using Kafka instead of Redpanda. I just like the simplicity that Redpanda brings to the table, as you can run a single Redpanda instance instead of all of the Kafka components.

## Running the demo

First, start by cloning the repository:

```
git clone https://github.com/bobbyiliev/materialize-tutorials.git
```

After that, you can access the directory:

```
cd materialize-tutorials/mz-user-reviews-dbt-demo
```

Let's start by running the Redpanda container:

```
docker-compose up -d redpanda
```

Build the images:

```
docker-compose build
```

Then pull all of the other Docker images:

```
docker-compose pull
```

Finally, start all of the services:

```
docker-compose up -d
```

In order to launch the Materialize CLI, you can run the following command:

```
docker-compose run mzcli
```

> This is just a shortcut to a Docker container with a compatible CLI pre-installed; if you already have `psql` installed, you could instead connect to the running Materialize instance using that: `psql -U materialize -h localhost -p 6875 materialize`.

As soon as the demo is running, the mock service will start generating reviews and users.

### Prepare dbt configuration

First, we will need to install the [`dbt-materialize`](https://pypi.org/project/dbt-materialize/) plugin:

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

After that, to make sure that the connection to the Materialize container is working, run:

```
dbt debug
```

Finally, we can use dbt to create materialized views on top of the 3 Redpanda/Kafka topics. To do so just run the following dbt command:

```
dbt run
```

This command generates executable SQL from our model files (found in the `models` directory of this project) and executes that SQL against the target database, creating our materialized views.

> Note: If you installed `dbt-materialize` in a virtual environment, make sure it's activated. If you don't have it installed, please revisit the setup above.

Finally, you can run your dbt tests:

```
dbt test
```

#### Verify the Materialized Views and Sources are created

Congratulations! You just used dbt to create materialized views in Materialize.

You can check the columns of the `reviews` source by running the following statement:

```sql
SHOW COLUMNS FROM analytics.reviews_raw;
```

You'll see that, as Materialize is pulling the message schema from the [Redpanda registry](https://vectorized.io/blog/schema_registry/), it knows the column types to use for each attribute:

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

You can verify the views were created from your psql shell connected to Materialize:

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
SELECT COUNT(*) FROM analytics.vipusersbadreviews;
```

You will be able to see that the result changes each time you run the query, meaning that the data is being incrementally updated without you having to run `dbt run` again.

### Generate the dbt docs

Once we have our materialized views created, we can generate the dbt docs. To do so, run the following command:

```
dbt docs generate
```

After that you can serve the docs by running the following command:

```
dbt docs serve
```

Then visit the docs at http://localhost:8080/dbt/docs/. There, you will have a list of all the views that were created and you can click on any of them to see the SQL that was generated. You would also see some nice Lineage Graphs that show the relationships between the views:

![dbt Lineage Graph](https://user-images.githubusercontent.com/21223421/148784371-21a454d4-560a-40a4-a6d1-e2aefc543617.png)

## Metabase

In order to access the [Metabase](https://materialize.com/docs/third-party/metabase/) instance, visit `http://localhost:3030` if you are running the demo locally or `http://your_server_ip:3030` if you are running the demo on a server. Then follow the steps to complete the Metabase setup.

Materialize integrates natively with Metabase using the official PostgreSQL connector. To connect to your Materialize database, specify the following connection properties:

Field             | Value
----------------- | ----------------
Database          | PostgreSQL
Name              | user_reviews
Host              | **materialized**
Port              | **6875**
Database name     | **materialize**
Database username | **materialize**
Database password | Leave empty

Once ready, you will be able to visualize your data just as you would with a standard PostgreSQL database.

## Stopping the Demo

To stop all of the services, run the following command:

```
docker-compose down
```

## Conclusion

As you can see, this is a barebones example of how to use Materialize together with dbt. You can use Materialize to ingest data from a variety of sources and then stream it to a variety of destinations.

To learn more about dbt and Materialize, check out the documentation here:

- [dbt + Materialize demo: Running dbt’s jaffle_shop with Materialize](https://materialize.com/dbt-materialize-jaffle-shop-demo/)
- [dbt + Materialize: streaming Wikipedia data demo](https://github.com/MaterializeInc/materialize/blob/main/play/wikirecent-dbt/README.md)
- [Materialize and dbt getting started guide](https://materialize.com/docs/guides/dbt/)

## Helpful resources:

* [`CREATE SOURCE`](https://materialize.com/docs/sql/create-source/)
* [`CREATE MATERIALIZED VIEW`](https://materialize.com/docs/sql/create-materialized-view/)
* [`SELECT`](https://materialize.com/docs/sql/select)