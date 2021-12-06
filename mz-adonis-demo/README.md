---

title: Building a real-time web application with Materialize and AdonisJS
tags: materialize,sql,adonisjs,streami
image: https://user-images.githubusercontent.com/21223421/142488955-ed7de1c3-e174-471d-826c-44f48078da17.png
status: draft

---
![Streaming SQL with Materialize and AdonisJS](https://user-images.githubusercontent.com/21223421/142488955-ed7de1c3-e174-471d-826c-44f48078da17.png)

# Introduction

In this tutorial, we are going to build a web application using [AdonisJS](https://adonisjs.com/) and integrate it with [Materialize](https://materialize.com) to create a real-time dashboard based on streaming data using standard SQL.

Materialize lets you define views you want to maintain on your data, just as you would with any SQL table, and then get the results in real-time, unlike traditional databases which frequently act as if they've never been asked that question before.

# Prerequisites

You need to have the following things installed before getting started:

* [Install Docker](https://docs.docker.com/get-docker/)
* [Install Docker Compose](https://docs.docker.com/compose/install/)
* [Install Node.js](https://nodejs.org/en/download/package-manager)

# What is Materialize

**[Materialize](https://materialize.com) is a streaming database** that takes data coming from sources like Kafka, PostgreSQL, S3 buckets, and more and allows you to effectively transform it in real-time using SQL.

Unlike a traditional database, Materialize is able to incrementally maintain views on top of streaming data, providing fresh and correct results as new data arrives. This means that, instead of recomputing the view from scratch every time it needs to be updated, it only does work proportional to the changes in its inputs, so it is fast and efficient.

In the context of web development, Materialize can be used as a backend to power real-time applications (as we'll see in this demo)!

## Running a Materialize Demo

For the sake of this tutorial we are going to run the following Materialize Demo:

[Materialize - Log Parsing Demo](https://github.com/bobbyiliev/mz-http-logs)

The setup of the demo is the following:

![Materialize log parsing demo diagram](https://user-images.githubusercontent.com/21223421/141309644-d80cffe4-39f9-4afa-a211-907f9de7d74e.png)

We would not get into too much details here, but if you have not gone through this demo before, make sure to read it!

To run the demo, follow these steps:

First things first, before you could run the demo, you need to clone the repository:

* Clone the repository:

```
git clone https://github.com/bobbyiliev/mz-http-logs.git
```

* Once that is done, switch to the repository directory:

```
cd mz-http-logs
```

* Then start all services:

```
docker-compose up -d
```

With that, you would have your Materialize instance up and running. Next we will prepare our AdonisJS installation and use AdonisJS to create our Materialize sources and views!

# What is AdonisJS

AdonisJS is a web framework for Node.js. It includes everything that you would need to create a fully functional web application or an API.

AdonisJS has been inspired by Laravel and it has its own ORM, Auth support, and a CLI tool called Ace which is very similar to Artisan.

At the end we would extend the Log parsing Materialize demo and have the following setup:

![Streaming Data with AdonisJS and Materialize ](https://user-images.githubusercontent.com/21223421/142433682-36085296-0292-416d-811a-3d25be08fa24.png)

# Install AdonisJS

Let's start by installing AdonisJS. To do so, you would need to run the following command:

```
npm init adonis-ts-app@latest hello-materialize
```

Once you run that, you will be asked to select a project structure. You will be able to choose between an API, Web App, and a minimal possible AdonisJS app:

```
CUSTOMIZE PROJECT
❯ Select the project structure …  Press <ENTER> to select
  api   (Tailored for creating a REST API server)
❯ web   (Traditional web application with server-rendered templates)
  slim  (A smallest possible AdonisJS application)
```

For this tutorial let's go with the `web` app! Using your arrow keys select `web` and hit enter.

After that you will be asked to choose a name for the project, I will leave this as `hello-materialize` but feel free to choose a different name.

I will then press enter and say yes to the rest of the settings:

```
❯ Enter the project name · hello-materialize
❯ Setup eslint? (y/N) · y
❯ Configure webpack encore for compiling frontend assets? (y/N) › y
```

This will instantiate the project and might take up to a minute to complete:

![AdonisJS initialization](https://user-images.githubusercontent.com/21223421/142430318-49200f63-394e-4698-aed0-7461d8a8a060.png)

Once ready, you can `cd` into the new project directory:

```
cd hello-materialize
```

And then start the webserver:

```
node ace serve --watch
```

If you are coming from the Laravel world, this would be just like running `php artisan serve`. The `ace` CLI tool is just like `artisan` and comes with a lot of the same functionalities.

To check all of the `ace` commands, you can run: `node ace`.

# Installing Lucid

Lucid is the AdonisJS ORM. It is quite similar to Laravel Eloquent.

Lucid comes with an Active Record ORM, Query Builder, Migrations, Seeds, and Factories.

Let's go ahead and install it! To do so, just run the following command:

```
npm i @adonisjs/lucid
```

Once done, you would need to do a quick configuration.

## Configuring Lucid

In order to configure Lucid, you need to run the following `ace` command:

```
node ace configure @adonisjs/lucid
```

You will be asked to select the database driver that you want to use. As Materialize is wire-compatible with PostgreSQL, you can connect to it using any `pg` driver; here, make sure to select PostgreSQL!

```
![AdonisJS lucid configuration](https://user-images.githubusercontent.com/21223421/142431728-ac88085b-34cb-4ebb-83c7-b0cae9fb455d.png)
```

Next, you will be asked to select where you want to display the configuration instructions. I chose `In the terminal`, which prints out the necessary environment variables that you have to add to your `.env` file.

## Configure the Materialize env variables

In order to let our AdonisJS application connect to Materialize, we need to change the `PG_*` details in the `.env` file.

With your favorite text editor, open the `.env` file and update the `PG_` environment variables to:

```
DB_CONNECTION=pg
PG_HOST=localhost
PG_PORT=6875
PG_USER=materialize
PG_PASSWORD=
PG_DB_NAME=materialize
```

This will allow AdonisJS to connect to Materialize just as it would when connecting to PostgreSQL.

One thing to keep in mind is that Materialize doesn’t yet support the full system catalog of PostgreSQL (we're working on it!), which means that ORMs like Lucid, Prisma, Sequelize, or TypeORM might fail during some attempts to interact with Materialize. As we work to broaden [`pg_catalog` coverage](https://github.com/MaterializeInc/materialize/issues/2157), the integration with these tools will gradually improve!

# Creating a Controller

Let's create a controller where we will add the functionality that would allow us to connect to Materialize!

As the Materialize demo is simulating an application log with a lot of visitors, let's call our AdonisJS controller `VisitorsController`:

```
node ace make:controller VisitorsController
```

This will create a controller file at:

```
app/Controllers/Http/VisitorsController.ts
```

Next, let's create the routes that we would need!

## Creating the AdonisJS routes

Your routes file is stored at `start/routes.ts`. In there we can specify our application URLs and map them to different controllers and methods!

We do not yet have the methods ready, but we know that we would need the following routes:

* `/source`: When visited, this route would create a Materialize [source](https://materialize.com/docs/sql/create-source/)
* `/view`: When visited, this route would create a [materialized view](https://materialize.com/docs/sql/create-source/)
* `/visitors`: This route would return an event stream with all of the latest changes to our materialized view
* `/`: This will be the landing page where we will display the streaming data that we are getting from the `/visitors` endpoint and Materialize

Open your routes file at `start/routes.ts` and update it so that it has the following content:

```
import Route from '@ioc:Adonis/Core/Route'

Route.get('/', 'VisitorsController.index')
Route.get('/visitors', 'VisitorsController.visitors')
Route.get('/source', 'VisitorsController.source')
Route.get('/view', 'VisitorsController.view')
```

Next, let's add a method that would allow us to create a Materialize source as described in the [Materialize Log Parsing Demo](https://github.com/bobbyiliev/mz-http-logs)!

## Creating a Materialize Source from logs

If you were accessing Materialize directly via a SQL client (like `psql`), in order to access data from a continuously produced log file, you would execute the following statement:

```sql
CREATE SOURCE requests
FROM FILE '/log/requests' WITH (tail = true)
FORMAT REGEX '(?P<ip>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) - - \[(?P<ts>[^]]+)\] "(?P<path>(?:GET /search/\?kw=(?P<search_kw>[^ ]*) HTTP/\d\.\d)|(?:GET /detail/(?P<product_detail_id>[a-zA-Z0-9]+) HTTP/\d\.\d)|(?:[^"]+))" (?P<code>\d{3}) -';
```

Let's see how we could do that via AdonisJS!

First, open the `app/Controllers/Http/VisitorsController.ts` file with your favorite text editor.

The file would have the following content initially:

```
// import { HttpContextContract } from '@ioc:Adonis/Core/HttpContext'

export default class VisitorsController {}
```

There are a few things that we would want to do:

* Import Lucid:

```
import Database from '@ioc:Adonis/Lucid/Database'
```

* Then inside the VisitorsController class, let's create a method called `source` and

```javascript
// import { HttpContextContract } from '@ioc:Adonis/Core/HttpContext'
import Database from '@ioc:Adonis/Lucid/Database'

export default class VisitorsController {

    public async source({request, response}) {

        //Using Ludic to connect to Materialize, we are executing a CREATE SOURCE statement
        const res = await Database.rawQuery(
            `CREATE SOURCE requests
                FROM FILE '/log/requests' WITH (tail = true)
                FORMAT REGEX '(\\?P<ip>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) - - \[(\\?P<ts>[^]]+)\] "(\\?P<path>(\\?:GET /search/\\\?kw=(\\?P<search_kw>[^ ]*) HTTP/\d\.\d)|(\\?:GET /detail/(\\?P<product_detail_id>[a-zA-Z0-9]+) HTTP/\d\.\d)|(\\?:[^"]+))" (\\?P<code>\d{3}) -';`
            );
        return res;

    }

}
```

Now, if you were to visit the `/source` URL via your browser (`http://127.0.0.1:3333/source`) it would create your Materialize source:

![Source created](https://user-images.githubusercontent.com/21223421/142441564-24faddfb-5b3d-4ef8-8653-5156bcbea747.png)

## Creating a Materialize View

You may be familiar with materialized views from the world of traditional databases like PostgreSQL, which are essentially cached queries. The unique feature here is the materialized view we are about to create is automatically kept up-to-date.

Let's do the same thing as before, but to create a materialized view based on our file source! To do that, let's create a method called `view` with the following content:

> Add this right after the end of the `source` method

```javascript
    public async view({request, response}) {

        //Using Ludic to connect to Materialize, we are executing a CREATE VIEW statement
        const res = await Database.rawQuery(
            `CREATE OR REPLACE MATERIALIZED VIEW unique_visitors AS
             SELECT count(DISTINCT ip) FROM requests;`
            );
        return res;

    }
```

Our materialized view would show the count of the unique visitors flowing through our demo application.

To create the view, visit the `/view` URL via your browser (eg. `http://127.0.0.1:3333/view`).

With that, our view will be created and we can move on to the next step!

## Creating an event stream

You can query the new materialized view, that we've just created, as usual with a standard `SELECT` statement:

```sql
SELECT * FROM unique_visitors;
```

However, in order to take full advantage of the incrementally updated materialized view right from our AdonisJS app, rather than querying Materialize with a standard `SELECT` to get the state of the view at a point in time, we will use a `TAIL` statement to request a stream of updates as the view changes.

```javascript
    public async visitors({request, response}) {

        // First we set a header to identify that this would be an event stream
        response.response.setHeader('Content-Type',  'text/event-stream');

        // Then we declare a TAIL cursor
        await Database.rawQuery('BEGIN');
        await Database.rawQuery('DECLARE visitors_c CURSOR FOR TAIL unique_visitors');

        // Finally we use FETCH in a loop to retrieve each batch of results as soon as it is ready
        while (true) {
            const res = await Database.rawQuery('FETCH ALL visitors_c');
            response.response.write(`data: ${JSON.stringify(res.rows)}\n\n`)
        }
    }
```

For more information about `TAIL`, make sure to check out the official documentation here:

[Materialize `TAIL` statement](https://materialize.com/docs/sql/tail/).

If you were to now visit the `/visitors` URL via your browser, you would see the following output:

![adonisjs Materialize streaming data](https://user-images.githubusercontent.com/21223421/142487272-4ae77597-b871-453d-9b79-efbc5a534d5a.gif)

Next, let's create a view where we would use the `/visitors` endpoint as an event source and continuously update our web page.

### Displaying the number of unique visitors on the frontend

First, before we get started, make sure that you've executed the following command to configure Encore which is used to compile and serve the frontend assets for your AdonisJS app:

```
node ace configure encore
```

Then create a new file at:

```
resources/views/visitors.edge
```

And add the following content:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Materialize and AdonisJS</title>
  @entryPointStyles('app')
  @entryPointScripts('app')
</head>
<body>

  <main>
    <div>
      <h1 class="title"> Hi there! </h1>
      <p class="subtitle">
        The number of unique visitors is: <strong><span id="count"></span></strong>
      </p>
    </div>
  </main>
  <script>
    var eventSource = new EventSource("http://127.0.0.1:3333/visitors");

    const count = 0;
    eventSource.onmessage = function(e) {
        const data  = JSON.parse(e.data)
        //const count = omit(data, 'mz_timestamp', 'mz_diff', 'mz_progressed')
        const { mz_diff, mz_progressed } = data;
        data.forEach(entry => {
          if(entry.mz_diff == -1){
            console.log('Old count: ' + entry.count)
          } else {
            console.log('New count: ' + entry.count)
            let countDiv = document.getElementById("count");
            countDiv.innerHTML = entry.count;
          }
        })
    };
  </script>
</body>
</html>
```

A quick rundown of the main things to keep in mind:

* `new EventSource`: First we define a new `EventSource` and specify our `/visitors` endpoint.
* `eventSource.onmessage`: Then we listen for new messages to show in the EventStream.
* `JSON.parse(e.data)`: After that we parse our data
* `data.forEach`: Finally we run a loop and update the total unique visitors counter on the page.

Now if you were to visit your AdonisJS application you would see the following output:

![adonisjs Materialize event source](https://user-images.githubusercontent.com/21223421/142488313-234fe614-c9f8-4e9a-bf88-e116444167fc.gif)

As you can see, rather than making a huge amount of AJAX requests, we just tap into the stream and keep our web page up to date with the latest changes from Materialize!

# Conclusion

This is pretty much it! You've now built a web application using AdonisJS that connects to Materialize and pulls the number of unique visitors from your application as new data is logged.

As a next step, make sure to head over to the Materialize Docs and try out some of the available demos:

[Materialize Demos](https://materialize.com/docs/demos/)

To learn more about AdonisJS, you can also find the documentation here:

[AdonisJS documentation](https://docs.adonisjs.com/guides/context)

You can find a link to the AdonisJS source code from this demo here:

[Streaming Data wiht Materialize and AdonisJS Demo files](https://github.com/bobbyiliev/mz-adonisjs-demo)

To learn more about Streaming SQL, make sure to check out this post here:

[Streaming SQL: What is it, why is it useful?](https://materialize.com/streaming-sql-intro/)

Hope that this was helpful!