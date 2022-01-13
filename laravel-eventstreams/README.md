# Real-time stock trades dashboard with Laravel and Materialize

## Architecture

> NOTE: For the sake of simplicity, the stocks and their prices have been extracted from the NASDAQ stock exchange and stored in a database statically for this tutorial, meaning that the stock prices will not change and is not acurate.

## Running the migrations

```
docker-compose run --rm composer install
docker-compose run --rm artisan migrate
docker-compose run --rm artisan db:seed
```

## Creating sources

Postgres:

```
psql -U postgres -h localhost -p 5432 postgres
```

```sql
ALTER TABLE materialize.users REPLICA IDENTITY FULL;
ALTER TABLE materialize.stocks REPLICA IDENTITY FULL;
ALTER TABLE materialize.trades REPLICA IDENTITY FULL;

CREATE PUBLICATION mz_source FOR ALL TABLES;
```

The Materialize:

```sql
CREATE MATERIALIZED SOURCE "mz_source" FROM POSTGRES                                                              CONNECTION 'user=postgres port=5432 host=postgres dbname=postgres password=postgres'
PUBLICATION 'mz_source';
```

```sql
CREATE VIEWS FROM SOURCE mz_source (users,stocks,trades);
```

Create Materialized View:

```sql
CREATE MATERIALIZED VIEW "materialize_stream" AS
    SELECT
        users.id AS user_id,
        users.name AS user_name,
        stocks.id AS stock_id,
        stocks.symbol AS stock_symbol,
        stocks.price AS stock_price,
        trades.id AS trade_id,
        trades.volume AS trade_volume,
        trades.type AS trade_type,
        trades.created_at AS created_at,
        trades.updated_at AS updated_at
    FROM users JOIN trades ON users.id = trades.user_id JOIN stocks ON trades.stock_id = stocks.id;
```

Create view to show the latest trades that occurred in the last 1 minute:

```sql
CREATE MATERIALIZED VIEW "latest_trades" AS
    SELECT * FROM materialize_stream
        WHERE (mz_logical_timestamp() >= (extract('epoch' from created_at)*1000)::bigint
        AND mz_logical_timestamp() < (extract('epoch' from created_at)*1000)::bigint + 60000);
```
