import {
  encode,
  BufReader,
  TextProtoReader,
  green, red
} from "./deps.ts";

import { WebSocketClient, StandardWebSocketClient } from "https://deno.land/x/websocket@v0.1.4/mod.ts";

const endpoint = Deno.args[0] || "ws://127.0.0.1:8080";

// Return index.html

const ws: WebSocketClient = new StandardWebSocketClient(endpoint);
ws.on("open", function() {
  Deno.stdout.write(encode(green("ws connected!\n")));
});

ws.on("message", function (message: string) {
  Deno.stdout.write(encode(`${message}\n`));
});
