import { Client } from "https://deno.land/x/postgres/mod.ts";
const client = new Client({
    user: "materialize",
    database: "materialize",
    password: "materialize",
    hostname: "127.0.0.1",
    port: 6875
})
const main = async ({ response }: { response: any }) => {
    try {
        await client.connect()
        /* Work with Materialize */
    } catch (err) {
        response.status = 500
        response.body = {
            success: false,
            msg: err.toString()
        }
    } finally {
        await client.end()
    }
}
export { main }