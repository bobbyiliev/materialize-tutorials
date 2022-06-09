FROM denoland/deno:1.22.0

EXPOSE 8080

WORKDIR /app

USER deno

COPY . .

RUN deno cache app.ts

CMD ["deno", "run", "--allow-env", "--allow-net", "app.ts"]
