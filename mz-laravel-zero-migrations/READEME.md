# How to manage your Materialize migrations with Laravel Zero
---

## Introduction

Managing your schema migrations is essential for any application. In this tutorial, we will show you how to manage your Materialize schema migrations with Laravel Zero.

[Materialize](https://materialize.com) is a streaming database that takes data coming from different sources like Kafka, PostgreSQL, S3 buckets, and more and allows users to write views that aggregate/materialize that data and let you query those views using pure SQL with very low latency.

## Prerequisites

Before you start this tutorial, you need to have the following:

- A running instance of Materialize: [Install Materialize](https://materialize.com/docs/install/)
- PHP 8.x or higher

## What is Laravel Zero?

Laravel Zero is an open-source PHP framework that can be used for creating console applications.

Laravel Zero is not an official Laravel package but was created by Nuno Maduro, who is also a Software Engineer at Laravel, so I have no doubts about the code quality.

For more information on how to get started with Laravel Zero, I would suggest the following article:

- [What is Laravel Zero and how to get started](https://devdojo.com/bobbyiliev/what-is-laravel-zero-and-how-to-get-started)

## Demo project

I have prepared a demo project that you can use to try out Laravel Zero and Materialize!

- [`mzschema` demo project](https://github.com/bobbyiliev/mzschema)

### Downloading the `mzschema` binary

Rather than cloning the repository, you can also use the following command to download only the executable file:

```
wget https://github.com/bobbyiliev/mzschema/raw/main/builds/mzschema
```

Then make the file executable:

```
chmod +x mzschema
```

And finally, run the installer:

```
./mzschema install
```

Output:

```
   Materialize Migrations  SQLite database created successfully at:

$HOME/.mz_migrations/mzschema/database.sqlite
```

The above command creates a SQLite database in `$HOME/.mz_migrations/mzschema/database.sqlite`. The SQLite database is used to store the schema migration history.

> Note: As of the time being, this is a required workaround for Materialize and would not be needed once the following issue is resolved: [sql: support "SERIAL" type](https://github.com/MaterializeInc/materialize/issues/8779).

### Clone the `mzschema` repository (optional)

Alternatively, you could clone the project and build it with the following commands:

```
git clone https://github.com/MaterializeInc/materialize/issues/8779
cd mzschema
php mzschema app:build
```

This generates the single `mzschema` build file that you can run independently.

## Environment variables

If your Materialize instance is running on a different host than the one you are running Laravel Zero, you can set the following environment variables to point to the correct host:

- Create a file called `.env` in the same directory as the `mzschema` binary.
- Add the following lines to the `.env` file:

```
MZ_CONNECTION=pgsql
MZ_HOST=127.0.0.1
MZ_PORT=6875
MZ_DATABASE=materialize
MZ_USERNAME=materialize
MZ_PASSWORD=materialize
```

Change the values to match your Materialize instance.

If Materialize is running on the same host as Laravel Zero, you don't need to set any environment variables.

## Creating a migration

Once you have the `mzschema` binary installed, you can create a new directory called `migrations` in the same directory as the `mzschema` binary:

```
mkdir migrations
```

Then you can create a new migration file in the `migrations` directory.

Let's go ahead and create a migration called `2022_03_16_155051_create_users_table.php` and add the following code:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        DB::connection('materialize')->statement(
            "CREATE TABLE transfers (id int, name text)"
        );
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        DB::connection('materialize')->statement(
            "DROP TABLE IF EXISTS transfers"
        );
    }
};
```

A quick rundown of the migration file:

- In the `up()` method, we create the `transfers` table. You can change this according to your needs and define your `SOURCE` and `VIEWS` DDL statements.
- In the `down()` method, we drop the `transfers` table. In there you would always want to define your `DROP` DDL statement.

## Running the migrations

To run the migration, you can use the following command:

```
./mzschema migrate --path=./migrations/ --realpath
```

Output:

```
 Do you really wish to run this command? (yes/no) [no]:
 > yes

Migrating: 2022_03_16_155051_create_transfers_table
Migrated:  2022_03_16_155051_create_transfers_table (8.97ms)
```

Next, you could try adding a new migration file and run the migration again!

> Note: you can change the `--path=./migrations/` to match your project's migrations directory.

Here is a quick demo of how it all works:

![mzschema example gif](https://user-images.githubusercontent.com/21223421/157834798-94926576-dff5-41ed-87ad-73c8b78d4416.gif)

## Checking migration status

To check the migration status, you can use the following command:

```
./mzschema migrate:status --path=./migrations/ --realpath
```

The output will look like this:

```sql
+------+------------------------------------------+-------+
| Ran? | Migration                                | Batch |
+------+------------------------------------------+-------+
| Yes  | 2022_03_16_155051_create_transfers_table | 2     |
+------+------------------------------------------+-------+
```

## Rolling back the migrations

In some cases, you might want to undo a migration. To do that, you can roll back the migration, you can use the following command:

```
./mzschema migrate:rollback --path=./migrations/ --realpath
```

Or if you want to roll back all migrations, you can use the following command:

```
./mzschema migrate:refresh --path=./migrations/ --realpath
```

## Limitations

As of the time of being, Materialize does not support `ALTER` statements for [`SOURCE`](https://materialize.com/docs/sql/create-source/) and [`VIEW`](https://materialize.com/docs/sql/create-views/), meaning that you will have to manually create a new migration to change the source of your data.

Let's review two possible solutions to this problem:

### Renaming

A possible solution to this is to create a new migration that will drop the old `VIEW` and create a new one with your new structure.

So it could look like this, let's say you have a view called `transfers` which you want to add an `amount` column to:

- Create a new migration that creates a new `VIEW` with your new structure called `transfers_new`
- In the same migration, rename the old `VIEW` to `transfers_old`
- Then rename the new `VIEW` from `transfers_new` to `transfers`

An example code snippet for the above migration:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        // Create the new `transfers_new` view
        DB::connection('materialize')->statement(
            "CREATE TABLE transfers_new (id int, name text, amount int)"
        );
        // Rename the old `transfers` view to `transfers_old`
        DB::connection('materialize')->statement(
            "ALTER TABLE transfers RENAME TO transfers_old"
        );
        // Rename the new `transfers_new` view to `transfers`
        DB::connection('materialize')->statement(
            "ALTER TABLE transfers_new RENAME TO transfers"
        );
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        DB::connection('materialize')->statement(
            "DROP TABLE IF EXISTS transfers, transfers_old, transfers_new"
        );
    }
};
```

If you are using this with a Materialized view, you might have to add some logic to check if the view is ready before you can rename it.

### Branching

Another approach to this problem is to create a new migration that creates a new `SOURCE` and `VIEWS` with a specific version appended to the name.

For example, if you have a `transfers` view and you want to add an `amount` column to it, you can create a new migration that creates a new `VIEWS` called `transfers_v2`.

That way you would have the two views in your database, `transfers` and `transfers_v2` at the same time and you will have to handle the logic to decide which one to use in your application.

This is a good approach as your database will be more stable and you will be able to roll back to the previous version of your application, the `transfers` view will always be available.

## Blue-green deployments

Both of the above solutions could be used in a blue-green deployment scenario.

For more information on blue-green deployments, please refer to the following article:

- [Blue-green deployments with Materialize](https://devdojo.com/bobbyiliev/blue-green-deployments-with-materialize)

## Conclusion

This tutorial has covered the basics of managing your schema migrations with Laravel Zero.

How do you manage your schema migrations? I would love to hear about the tools that you use and give them a try with Materialize!

To learn more about Materialize, check out the [official Materialize documentation](https://materialize.com/docs/).

If you need any help, please join the [Materialize Community Slack channel](https://materialize.com/s/chat).