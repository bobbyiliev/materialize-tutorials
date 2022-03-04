<?php

/*
    * Create a connection to Materialize
    * You need to make sure that the `pdo_pgsql` module is installed:
    * - https://www.php.net/manual/en/ref.pdo-pgsql.php
*/

/*
    * Create a connection to locally running Materialize example
*/
function connect(string $host, int $port, string $db, string $user, string $password): PDO
{
    try {
        $dsn = "pgsql:host=$host;port=$port;dbname=$db;";

        // make a database connection
        return new PDO(
            $dsn,
            $user,
            $password,
            [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
        );
    } catch (PDOException $e) {
        die($e->getMessage());
    }
}

/*
    * Create a connection to Materialize Cloud example
*/
function cloudConnect(string $host, int $port, string $db, string $user, string $password): PDO
{
    try {
        $dsn = "pgsql:host=$host;port=$port;dbname=$db;sslmode=verify-full;sslcert=materialize.crt;sslkey=materialize.key;sslrootcert=ca.crt";

        // make a database connection
        return new PDO(
            $dsn,
            $user,
            $password,
            [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
        );
    } catch (PDOException $e) {
        die($e->getMessage());
    }
}

$connection = cloudConnect('your_instance_here.materialize.cloud', 6875, 'materialize', 'materialize', 'materialize');

/*
    * Show views example
*/
function showViews()
{
    $views = "SHOW VIEWS";
    $statement = $connection->query($views);
    $result = $statement->fetchAll(PDO::FETCH_ASSOC);
    var_dump($result);
}

/*
    * Create view example
*/
function createView(Type $var = null)
{
    $sql = "CREATE VIEW market_orders_2 AS
            SELECT
                val->>'symbol' AS symbol,
                (val->'bid_price')::float AS bid_price
            FROM (SELECT text::jsonb AS val FROM market_orders_raw_2)";

    $statement = $connection->prepare($sql);
    $statement->execute();

    $views = "SHOW VIEWS";
    $statement = $connection->query($views);
    $result = $statement->fetchAll(PDO::FETCH_ASSOC);
    var_dump($result);
}

/*
    * Create a source example
*/
function createSource()
{
    $sql = "CREATE SOURCE market_orders_raw_2 FROM PUBNUB
    SUBSCRIBE KEY 'sub-c-4377ab04-f100-11e3-bffd-02ee2ddab7fe'
    CHANNEL 'pubnub-market-orders'";

    $statement = $connection->prepare($sql);
    $statement->execute();

    $sources = "SHOW SOURCES";
    $statement = $connection->query($sources);
    $result = $statement->fetchAll(PDO::FETCH_ASSOC);
    var_dump($result);
}

/*
    * Insert data example
*/
function insertData()
{
    $sql = 'INSERT INTO countries (name, code) VALUES (?, ?)';
    $statement = $connection->prepare($sql);
    $statement->execute(['United States', 'US']);
    $statement->execute(['Canada', 'CA']);
    $statement->execute(['Mexico', 'MX']);
    $statement->execute(['Germany', 'DE']);

    $countStmt = "SELECT COUNT(*) FROM countries";
    $count = $connection->query($countStmt);
    while (($row = $count->fetch(PDO::FETCH_ASSOC)) !== false) {
        var_dump($row);
    }

}

/*
    * Query example
*/
function queryExample()
{

    $sql = 'SELECT * FROM demo LIMIT 10';
    $statement = $connection->query($sql);

    while (($row = $statement->fetch(PDO::FETCH_ASSOC)) !== false) {
        var_dump($row);
    }

}

/*
    * TAIL example
*/
function tail()
{
    // Begin a transaction
    $connection->beginTransaction();
    // Declare a cursor
    $statement = $connection->prepare('DECLARE c CURSOR FOR TAIL demo');
    // Execute the statement
    $statement->execute();

    /* Fetch all of the remaining rows in the result set */
    while (true) {
        //$result = $statement->fetchAll();
        $tail = $connection->prepare('FETCH ALL c');
        $tail->execute();
        $result = $tail->fetchAll(PDO::FETCH_ASSOC);
        print_r($result);
    }
}