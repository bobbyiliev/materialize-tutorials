# Using WebSockets with Deno Chart.js and Materialize to build real-time charts

## Introduction

This is a self-contained example of a real-time chart powered by Deno, Web Sockets, Chart.js, and [Materialize](https://materialize.com).

[Deno](https://deno.land/) is a simple and secure runtime for JavaScript and TypeScript that uses V8. Deno, just like Materialize, is also written in Rust.

In this demo, we will build a simple live dashboard app that displays real-time data from a Deno Web Socket server. Deno will then connect to Materialize and [TAIL](https://materialize.com/docs/sql/tail/) our live materialized view to get the latest data and display it in a real-time chart using Chart.js.

## Overview

Here is a quick overview of the project:

- A mock service to continually generate user score events.
- Redpanda instance to store the user score events in a topic.
- Materialize instance that is connected to the Redpanda instance and ingests the data from the topic in a live materialized view which we can query in real-time using just SQL.
- A Deno backend service that connects to Materialize and TAIL the live materialized view to get the latest data and display it in a real-time chart.
- Frontend service that connects to the Deno app via a web socket and displays the data in a real-time chart using Chart.js.

Here is a diagram of the project:

![Materialize + Deno + Chart.js + Web Sockets](https://user-images.githubusercontent.com/21223421/172839011-a19476ca-a156-4a06-9148-915088f125a5.png)

## Prerequisites

To run this demo, you need to have the following installed.

* [Install Docker](https://docs.docker.com/get-docker/).
* [Install Docker Compose](https://docs.docker.com/compose/install/).

## Running the demo

To get started, clone the repository:

```
git clone git clone https://github.com/bobbyiliev/materialize-tutorials.git
```

Then you can access the directory:

```
cd materialize-tutorials/mz-deno-live-dashboard
```

With that you can then build the images:

```
docker-compose build
```

And finally, you can run all the containers:

```
docker-compose up -d
```

It might take a couple of minutes to start the containers and generate the demo data.

After that, you can visit `http://localhost` in your browser to see the demo:

![Deno websockets and chart.js](https://user-images.githubusercontent.com/21223421/172840971-8e1091ac-8ec9-4773-b414-b1e858b0c278.gif)

Next, let's review the Materialize setup.

## Materialize setup

The Deno service will execute the following DDL statements on boot so that we don't have to run them manually:

- Create a Kafka source: Creating a source in Materialize does not actually start the data ingestion. You can think of a non-materialized source as just the metadata needed for Materialize to connect to your source but not process any data:

```sql
CREATE SOURCE score
FROM KAFKA BROKER 'redpanda:9092' TOPIC 'score_topic'
FORMAT BYTES;
```

- Create a [create non-materialized view](https://materialize.com/docs/sql/create-view/), that essentially only provides us with an alias for the `SELECT` statements they include:

```sql
CREATE VIEW score_view AS
    SELECT
        *
    FROM (
        SELECT
            (data->>'user_id')::int AS user_id,
            (data->>'score')::int AS score,
            (data->>'created_at')::double AS created_at
        FROM (
            SELECT CAST(data AS jsonb) AS data
            FROM (
                SELECT convert_from(data, 'utf8') AS data
                FROM score
            )
        )
    );
```

- Create a materialized view:

```sql
CREATE MATERIALIZED VIEW score_view_mz AS
    SELECT
        (SUM(score))::int AS user_score,
        user_id
    FROM score_view GROUP BY user_id;
```

To check if the views and the sources were created, launch the Materialize CLI:

```shell session
docker-compose run mzcli
```

> This is just a shortcut to a docker container with postgres-client pre-installed, if you already have `psql` you could run `psql -U materialize -h localhost -p 6875 materialize`.

Then check the views and the sources:

```sql
SHOW VIEWS;
-- Output:
-- +-----------------+
-- | score_view      |
-- | score_view_mz   |
-- +-----------------+

SHOW sources;
-- Output:
-- +-----------------+
-- | score           |
-- +-----------------+
```

### Using `TAIL`

Next, to see the results in real-time we can use `TAIL`:

```sql
COPY ( TAIL score_view_mz ) TO STDOUT;
```

You will see a flow of the new user score that was generated in real-time.

We can also start a `TAIL` without a snapshot, which means that you will only see the latest records after the query is run:

```sql
COPY ( TAIL score_view_mz WITH (SNAPSHOT = false) ) TO STDOUT;
```

This is what we will use in our Deno application to get the top user scores and display them in a real-time chart.

For more information on how the `TAIL` function works, see the [Materialize documentation](https://materialize.com/docs/sql/tail/).

## Deno

Now that we have Materialize ready, let's review the Deno setup.

We would use two Deno modules:
- The Postgres module to connect to Materialize.
- The Web Sockets module to create a Web Socket connection to our Frontend service.

You can find the code in the [`backend` directory]().

```ts
import { WebSocketClient, WebSocketServer } from "https://deno.land/x/websocket@v0.1.4/mod.ts";
import { Client } from "https://deno.land/x/postgres/mod.ts";

// Specify your Materialize connection details
const client = new Client({
  user: "materialize",
  database: "materialize",
  hostname: "materialized",
  port: 6875,
});

await client.connect();
console.log("Connected to Postgres");

// Start a transaction
await client.queryObject('BEGIN');
// Declare a cursor without a snapshot
await client.queryObject(`DECLARE c CURSOR FOR TAIL score_view_mz WITH (SNAPSHOT = false)`);

const wss = new WebSocketServer(8080);

wss.on("connection", async function (ws: WebSocketClient) {
  console.log("Client connected");
  setInterval(async () => {
    const result = await client.queryObject<{ mz_timestamp: string; mz_diff: number, user_id: number, user_score: number}>(`FETCH ALL c`);
    for (const row of result.rows) {
      let message = { user_id: row.user_id, user_score: row.user_score };
      broadcastEvent(message);
    }
  } , 1000);

});

// Broadcast a message to all clients
const broadcastEvent = (message: any) => {
  wss.clients.forEach((ws: WebSocketClient) => {
    ws.send(JSON.stringify(message));
  });
}
```

Rundown of the code:

- As Materialize is Postgres wire compatible, first we import the `Client` class from the `https://deno.land/x/postgres/mod.ts` module. This is the class that we will use to connect to the Materialize instance.
- Next, we create a new `Client` instance and pass it the credentials for Materialize.
- Then we call the `connect()` method on the client instance to connect to Materialize.
- Next, we call the `queryObject()` method on the client instance to start a transaction and also call the `queryObject()` method on the client instance to declare a cursor without a snapshot.
- Finally, we create a new `WebSocketServer` instance and pass it the port to listen on.
- We then define a `connection` event handler on the `WebSocketServer` instance, which is called when a client connects.
- We then set an interval to fetch the latest data from Materialize and broadcast it to all clients.

## Frontend setup

For the frontend, we will not be using any JavaScript framework, but just the [Chart.js library](https://www.chartjs.org/).

Thanks to the web sockets connection, we can now receive the latest data from Materialize and display it in a real-time chart.

```html
<!DOCTYPE html>
<html lang="en">
    <head>
        <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    </head>
    <body>
        <div class="w-full mt-10">
            <canvas id="myChart"></canvas>
        </div>
    <script>
      const ctx = document.getElementById("myChart");
      const myChart = new Chart(ctx, {
        type: "bar",
        data: {
          labels: [ "Player 1", "Player 2", "Player 3", "Player 4", "Player 5", "Player 6" ],
          datasets: [
            {
              label: "# of points",
              data: [0, 0, 0, 0, 0, 0],
              backgroundColor: [
                "rgba(255, 99, 132, 0.2)",
                "rgba(54, 162, 235, 0.2)",
                "rgba(255, 206, 86, 0.2)",
                "rgba(75, 192, 192, 0.2)",
                "rgba(153, 102, 255, 0.2)",
                "rgba(255, 159, 64, 0.2)",
              ],
              borderColor: [
                "rgba(255, 99, 132, 1)",
                "rgba(54, 162, 235, 1)",
                "rgba(255, 206, 86, 1)",
                "rgba(75, 192, 192, 1)",
                "rgba(153, 102, 255, 1)",
                "rgba(255, 159, 64, 1)",
              ],
              borderWidth: 1,
            },
          ],
        },
        options: {
          scales: {
            y: {
              beginAtZero: true,
            },
          },
        },
      });

      webSocket = new WebSocket("ws://127.0.0.1:8080");
      webSocket.onmessage = function (message) {
        const data = message.data;
        const dataObj = JSON.parse(data);
        const dataArray = Object.values(dataObj);
        console.log(dataArray);
        index = dataArray[0] - 1;
        myChart.data.datasets[0].data[index] = dataArray[1];
        myChart.update();
      };
    </script>
  </body>
</html>
```

Rundown of the code:
- We first define the new chart using the `Chart.js` library: `new Chart()` and pass the different configuration options.
- Then we create a new `WebSocket` instance and pass it the URL of the Web Socket server with `webSocket = new WebSocket("ws://backend:8080");`
- Finally, we define an `onmessage` event handler on the `WebSocket` instance, which is called when a message is received and updates the chart.

You can find the code in the [`frontend` directory]().

## Conclusion

You can leave the Deno application running so that it would be subscribed to the Materialize instance and update the chart in real-time.

As a next step you can check out the Materialize + dbt + Redpanda demo which is based on the same user reviews mock data:

> [Materialize + dbt + Redpanda demo](https://devdojo.com/bobbyiliev/how-to-use-dbt-with-materialize-and-redpanda)


## Helpful resources:

* [`TAIL`](https://materialize.com/docs/sql/tail/)
* [`CREATE SOURCE`](https://materialize.com/docs/sql/create-source/)
* [`CREATE VIEWS`](https://materialize.com/docs/sql/create-views)
* [`SELECT`](https://materialize.com/docs/sql/select)

## Community

If you have any questions or comments, please join the [Materialize Slack Community](https://materialize.com/s/chat)!
