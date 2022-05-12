import { Client } from "https://deno.land/x/postgres/mod.ts";

// Specify your Discord webhook URL
const discord_webhook_url = "";

// Specify your Materialize connection details
const client = new Client({
    user: "materialize",
    database: "materialize",
    hostname: "127.0.0.1",
    port: 6875,
});

const tail = async () => {
    // Connect to Materialize
    await client.connect();

    // Start a transaction
    await client.queryObject('BEGIN');
    // Declare a cursor without a snapshot
    await client.queryObject('DECLARE c CURSOR FOR TAIL bad_vip_reviews WITH (SNAPSHOT = false)');

    // Start a loop to get the latest records
    while (true) {
        // Get the next record
        const result = await client.queryObject<{ mz_timestamp: string; mz_diff: number, user_id: number, 
rating: number, review_text: number, created_at: string, username: string, email: string }>('FETCH ALL c');

        // Loop through the records and send them to Discord
        for (const row of result.rows) {
            if (row.mz_diff > 0) {
                console.log(`${row.username} has left a bad review with rating ${row.rating}. Email: ${row.email}`);
                // Make an HTTP request to post to the Discord webhook
                if (discord_webhook_url) {
                    await fetch(discord_webhook_url, {
                        method: "POST",
                        headers: {
                            "Content-Type": "application/json",
                        },
                        body: JSON.stringify({
                            content: `${row.username} has left a bad review!\nRating ${row.rating}.\nEmail: ${row.email}`,
                        }),
                    });
                }
            }
        }
    }

    await client.end();
}

tail();
