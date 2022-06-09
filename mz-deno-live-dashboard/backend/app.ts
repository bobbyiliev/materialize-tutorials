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

// Create the sources and the views
await client.queryArray(`CREATE SOURCE IF NOT EXISTS score
FROM KAFKA BROKER 'redpanda:9092' TOPIC 'score_topic'
FORMAT BYTES;`);
await client.queryArray(`CREATE VIEW IF NOT EXISTS score_view AS
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
);`);
await client.queryArray(`CREATE MATERIALIZED VIEW IF NOT EXISTS score_view_mz AS
SELECT
    (SUM(score))::int AS user_score,
    user_id
FROM score_view GROUP BY user_id;`);

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