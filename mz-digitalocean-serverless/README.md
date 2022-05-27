# How to use Materialize with DigitalOcean Serverless Functions

## Introduction

[Materialize](https://materialize.com?utm_source=bobbyiliev) is a streaming database for real-time analytics. It was launched in 2019 to address the growing need for the ability to build real-time applications easily and efficiently on streaming data so that businesses can obtain actionable intelligence from streaming data.

This is a simple example of how to use the DigitalOcean serverless functions and query Materialize.

## Prerequisites

- DigitalOcean Account
- `doctl` CLI installed
- [A running Materialize instance](https://materialize.com/docs/install?utm_source=bobbyiliev)

## Configure Materialize

Once you have your Materialize instance running, let's quickly add some data in there.

You can use `psql` to access Materialize:

```
psql -U materialize -h localhost -p 6875
```

For the sake of simplicity, let's start by creating a simple table:

```sql
CREATE TABLE my_view (
  id INT(11),
  name VARCHAR(255) NOT NULL,
);
```

After that insert some data:

```sql
INSERT INTO my_view (id, name) VALUES (1, 'Bobby'), (2, 'John'), (3, 'Jane'), (4, 'Jack');
```

In a real-world scenario, you would probably want to add a source like Kafka and create a materialized view. For this example, we will use a simple table, but you can refer to the [Materialize documentation](https://materialize.com/docs/) for more information.

## Setup `doctl`

Once you have `doctl` installed as per the [DigitalOcean documentation](https://docs.digitalocean.com/reference/doctl/how-to/install/), you can go ahead and follow the steps here to create a new serverless function:

Start by installing the sandbox support:

```bash
doctl serverless install
```

Connect to the cloud portion of your sandbox:

```bash
doctl sandbox connect
```

Initialize a local file system directory for the serverless function:

```bash
doctl serverless init --language php materialize-php
```

Then rename the sample function to `materialize-php`:

```bash
mv materialize-php/packages/sample/ materialize-php/packages/materialize-php/
```

Note that you can do all this via the DigitalOcean Control Panel rather than the CLI.

### Create a `.env` file

As you will need to pass your Materialize login details securely, you should not define them in the `project.yaml` file. Instead, you should create a `.env` file at the root of your project.

Start by creating a `.env` file at the root of your project.

```
touch materialize-php/.env
```

Then add the following contents to the `.env` file:

```bash
# Your Materialize Host
MATERIALIZE_HOST=""
# Your Materialize App Specific Password
MATERIALIZE_PASSWORD=""
# Your Materialize App Username
MATERIALIZE_USER=""
# Materialize Port
MATERIALIZE_PORT="6875"
# Materialize Database Name
MATERIALIZE_DB="materialize"
```

Make sure to replace the values with your own.

### Update the `project.yml`

The `project.yml` contains the information for your serverless function. In there you can specify things like the name of the function, your environment variables, and more.

With your favorite text editor, open the `project.yml` file and add the following contents:

```yaml
targetNamespace: ''
parameters: {}
environment:
  MATERIALIZE_HOST: "${MATERIALIZE_HOST}"
  MATERIALIZE_PORT: "${MATERIALIZE_PORT}"
  MATERIALIZE_DB: "${MATERIALIZE_DB}"
  MATERIALIZE_USER: "${MATERIALIZE_USER}"
  MATERIALIZE_PASSWORD: "${MATERIALIZE_PASSWORD}"
packages:
  - name: materialize-php
    environment: {}
    parameters: {}
    annotations: {}
    actions:
      - name: hello
        binary: false
        main: ''
        runtime: 'php:default'
        web: true
        parameters: {}
        environment: {}
        annotations: {}
        limits: {}
```

The only thing that we've changed is the environment, where we've specified the database credentials. And also the name of the function: `materialize-php`.

### Create the serverless function

This is more or less all the configuration that we have to do. Next, we can create the function.

Let's use the default `hello.php` file that was automatically created for us when we ran the `doctl serverless init` command:

```
materialize-php/packages/materialize-php/hello/hello.php
```

Edit the file and add the following contents:

```php
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
```

A rundown of the function:

- `function connect()`: We start by creating a function that we can reuse to connect to Materialize. As Materialize is a PostgreSQL wire-compatible, we just use the default PHP `PDO` class to connect.
- `function main()`: This is the function that will be called when we want to run the function. As you can see we don't call the function directly, but instead we call it from the `doctl serverless invoke` command or access it via the URL provided by the DigitalOcean.
- Inside the `main()` function we run a simple query to get the data from Materialize and return it.

## Deploy the function

Finally, to deploy the serverless function, we can run:

```bash
doctl serverless deploy materialize-php --env materialize-php/.env
```

This will deploy the function to DigitalOcean and create a URL that we can access to invoke the function.

To get the URL, you can run:

```
doctl sbx fn get materialize-php/hello --url
```

Alternatively, you can also invoke the function directly with the following command:

```bash
doctl serverless functions invoke materialize-php/hello
```

You will get the following response:

```json
{
    "body": [
        {
            "id": 1,
            "name": "Bobby"
        },
        {
            "id": 2,
            "name": "Jane"
        },
        {
            "id": 3,
            "name": "John"
        },
        {
            "id": 4,
            "name": "Jack"
        }
    ]
}
```

As a further step, we can extend the function to accept different parameters and return different data like sorting and filtering.

## Conclusion

The new serverless functions allow you to quickly deploy your code without having to worry about the details of the infrastructure. Being able to query Materialize from your serverless function is a great way to get real-time data for your functions.

I am planning to add more examples of serverless functions with different languages. You will be able to find them at:

> https://github.com/bobbyiliev/materialize-tutorials/tree/main/mz-digitalocean-serverless

## Helpful resources:

* [`CREATE SOURCE: PostgreSQL`](https://materialize.com/docs/sql/create-source/postgres?utm_source=bobbyiliev)
* [`CREATE SOURCE`](https://materialize.com/docs/sql/create-source?utm_source=bobbyiliev)
* [`CREATE VIEWS`](https://materialize.com/docs/sql/create-views?utm_source=bobbyiliev)
* [`SELECT`](https://materialize.com/docs/sql/select?utm_source=bobbyiliev)

## Community

If you have any questions or comments, please join the [Materialize Slack Community](https://materialize.com/s/chat)!