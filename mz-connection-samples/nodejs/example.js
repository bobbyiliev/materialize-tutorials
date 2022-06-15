const { Client } = require('pg');
const client = new Client('postgres://materialize@localhost:6875/materialize');

async function main() {
    await client.connect();
    /* Work with Materialize */
}

main();
