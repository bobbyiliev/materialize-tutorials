<?php
// Function that connects to Materialize Cloud and returns the response
function connect(string $host, int $port, string $db, string $user, string $password): PDO
{
    try {
        $dsn = "pgsql:host=$host;port=$port;dbname=$db;";
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

function main() : array
{
    $host = getenv('MATERIALIZE_HOST');
    $port = getenv('MATERIALIZE_PORT');
    $db = getenv('MATERIALIZE_DB');
    $user = getenv('MATERIALIZE_USER');
    $password = getenv('MATERIALIZE_PASSWORD');

    $connection = connect($host, $port, $db, $user, $password);

    $sql = 'SELECT * FROM my_view';

    $statement = $connection->query($sql);
    $results = [];
    while (($row = $statement->fetch(PDO::FETCH_ASSOC)) !== false) {
        $results[] = $row;
    }

    return ["body" => $results];
}