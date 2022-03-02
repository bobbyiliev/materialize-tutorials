# How to use Laravel WebSockets 🛰



# Introduction

In this guide, we will walk you through how to use Laravel WebSockets. We will be using the [Laravel WebSockets](https://beyondco.de/docs/laravel-websockets/) package which is a great replacement for [Pusher](https://pusher.com/).

The Laravel WebSockets package emulates the Pusher API and allows you to easily connect to the WebSockets server and subscribe to channels, just as you would with Pusher.

The best way of using the Laravel WebSockets package is as a direct replacement for Pusher.

# Prerequisites

Before you start, you would need to have a Laravel application up and running.

I will be using a DigitalOcean Ubuntu Droplet for this demo. If you wish, you can use my affiliate code to get [free $100 DigitalOcean credit](https://m.do.co/c/2a9bba940f39) to spin up your own servers!

If you do not have that yet, you can follow the steps from this tutorial on how to do that:

* [How to Install Laravel on DigitalOcean with 1-Click](https://devdojo.com/bobbyiliev/how-to-install-laravel-on-digitalocean-with-1-click)

Or you could use this awesome script to do the installation:

* [LaraSail](https://devdojo.com/episode/laravel-on-digital-ocean-with-larasail)

We will use a model called `Post` as an example in this tutorial.

# Installing Laravel WebSockets

To install the Laravel WebSockets package, you need to run the following command:

```
composer require beyondcode/laravel-websockets
```

Then you have to publish the migration file by running the following command:

```
php artisan vendor:publish --provider="BeyondCode\LaravelWebSockets\WebSocketsServiceProvider" --tag="migrations"
```

The above publishes the migration file to your application's `database/migrations` directory. The WebSockets migration stores the definition of the WebSockets table which contains some statistics about the WebSockets events.

Before running the migrations command below, you need to make sure that you have configured your database credentials in your `.env` file. After that, you can run the migration command:

```
php artisan migrate
```

Next, you will also need to publish the WebSockets configuration file by running the following command:

```
php artisan vendor:publish --provider="BeyondCode\LaravelWebSockets\WebSocketsServiceProvider" --tag="config"
```

The above publishes the WebSockets configuration file to your application's `config/websockets.php` file. In there you can configure the WebSockets server settings. For more information about the configuration file, you can check the [documentation](https://beyondco.de/docs/laravel-websockets/getting-started/introduction).

# WebSockets Laravel Configuration

As the WebSockets package is fully compatible with Pusher, we can use the same configuration as we would use for Pusher.

So to install the Pusher package, you need to run the following command:

```
composer require pusher/pusher-php-server "~3.0"
```

In your `.env` file, change the `BROADCAST_DRIVER` to `pusher`:

```
BROADCAST_DRIVER=pusher
```

In the `config/broadcasting.php` file, update the `host` and the `port` values as follows:

```php
'pusher' => [
    'driver' => 'pusher',
    'key' => env('PUSHER_APP_KEY'),
    'secret' => env('PUSHER_APP_SECRET'),
    'app_id' => env('PUSHER_APP_ID'),
    'options' => [
        'cluster' => env('PUSHER_APP_CLUSTER'),
        // 'encrypted' => true,
        'host' => '127.0.0.1',
        'port' => 6001,
        'scheme' => 'http'
    ],
],
```

> Note that if you were using SSL for the WebSockets server, you would need to update the `scheme` value to `https` and uncomment the `encrypted` option.

Next in your `.env` file, set your Pusher details:

```
PUSHER_APP_ID=12345
PUSHER_APP_KEY=ABCDEFG
PUSHER_APP_SECRET=HIJKLMNOP
PUSHER_APP_CLUSTER=mt1
```

Make sure to change the values to some secure ones. It does not matter what you set them to, as long as they are secure.

# Running the Laravel WebSockets Server

To run the Laravel WebSockets server, you need to run the following command:

```
php artisan websockets:serve
```

This will start the WebSockets server on port `6001`.

If you were to visit `/laravel-websockets` in your browser, you would see the real-time statistics.

# Creating a new Event

Next, let's go ahead and test our WebSockets server by creating a new event.

You can do that by running the following command:

```
php artisan make:event NewTrade
```

This will create a new event called `NewTrade.php` in the `App/Events` directory.

Open the `NewTrade.php` file and update the file to:

```php
<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class NewTrade implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $trade;

    /**
     * Create a new event instance.
     *
     * @return void
     */
    public function __construct($trade)
    {
        $this->trade = $trade;
    }

    /**
     * Get the channels the event should broadcast on.
     *
     * @return \Illuminate\Broadcasting\Channel|array
     */
    public function broadcastOn()
    {
        return new Channel('trades');
    }
}
```

A quick rundown of the changes we've made to the default event:

- The `NewTrade` class now implements the `ShouldBroadcast` interface
- We've defined a new public property called `$trade`
- In the `constructor`, we've assigned the `$trade` property to the `$trade` parameter
- We've added a `broadcastOn` method that returns a new `Channel` instance with the name `trades`. For a private channel, you can use the `PrivateChannel` class.

Now to quickly test our event, we can use the Laravel tinker command:

```
php artisan tinker
```

Then trigger the event by running the following:

```
event (new \App\Events\NewTrade('test'))
```

Next, if you were to visit `/laravel-websockets` in your browser, you would see the event there:

![Laravel WebSockets demo event](https://user-images.githubusercontent.com/21223421/156309255-55e8755a-fd75-42cd-a9fa-8ab94b92ed72.png)

# Configuring Laravel Echo

With all the steps above the WebSockets server is now running and the backend is ready to receive events. The next step is to configure Laravel Echo so that we could use it to send those events to the frontend.

If you have not installed your `npm` dependencies yet, you can install them by running the following command:

```
npm install
```

Install the Laravel Echo dependency and the Pusher JS library:

```
npm install --save-dev laravel-echo pusher-js
```

Then in the `resources/js/bootstrap.js` file, add the following:

```javascript
import Echo from "laravel-echo"

window.Pusher = require('pusher-js');

window.Echo = new Echo({
    broadcaster: 'pusher',
    key: 'process.env.MIX_PUSHER_APP_KEY',
    wsHost: window.location.hostname,
    wsPort: 6001,
    forceTLS: false,
    disableStats: true,
});
```

Then compile the assets by running the following command:

```
npm run dev
```

> Note that you can also use the `npm run production` command to compile the assets for production.

With that, we're done with the Laravel Echo configuration! Next, let's go ahead and add this to our Blade view so we can see how it all works!

# Working with Laravel Echo on the Frontend

What you need to include in your Blade view is the following:

```javascript
    <script src="{{ asset('js/app.js') }}"></script>
    <script>
        Echo.channel('trades')
            .listen('NewTrade', (e) => {
                console.log(e.trade);
            })
    </script>
```

This includes the compiled assets and instantiates the Echo instance to listen to the `trades` channel.

To see this in action, let's update the `resources/views/welcome.blade.php` file to have the following content:

```html
<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">

        <title>Laravel EventStream</title>

        <meta name="csrf-token" content="{{ csrf_token() }}" />
        <link href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700&display=swap" rel="stylesheet">
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/tailwindcss/dist/tailwind.min.css">

    </head>
    <body>
        <div class="container w-full mx-auto pt-20">
            <div class="w-full px-4 md:px-0 md:mt-8 mb-16 text-gray-800 leading-normal">

                <div class="flex flex-wrap">
                    <div class="w-full md:w-2/2 xl:w-3/3 p-3">
                        <div class="bg-white border rounded shadow p-2">
                            <div class="flex flex-row items-center">
                                <div class="flex-shrink pr-4">
                                    <div class="rounded p-3 bg-yellow-600"><i class="fas fa-user-plus fa-2x fa-fw fa-inverse"></i></div>
                                </div>
                                <div class="flex-1 text-right md:text-center">
                                    <h5 class="font-bold uppercase text-gray-500">Latest trade</h5>
                                    <h3 class="font-bold text-3xl">
                                        <p>
                                            Name: <span id="latest_trade_user"></span>
                                        </p>
                                    </h3>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </body>
    <script src="{{ asset('js/app.js') }}"></script>
    <script>
        Echo.channel('trades')
            .listen('NewTrade', (e) => {
                console.log(e.trade);
                document.getElementById('latest_trade_user').innerText = e.trade;
            })
    </script>
</html>
```

After that visit `/` in your browser and you can try firing a few new events via the tinker command. And you should see the events in the console as follows:

![Laravel WebSocket example](https://user-images.githubusercontent.com/21223421/156316368-a2d07233-a145-4008-a4a6-3796c54bd175.gif)

As you can see from the gif, as soon as we fire a new trade event, we can see it in our browser.

# WebSockets vs SSE

Another way to send events is to use the [Server-Sent Events](https://en.wikipedia.org/wiki/Server-sent_events) protocol. There are many pros and cons to using WebSockets vs SSE, and here are some of them below:

- WebSockets provide you with a real-time two-directional connection
- SSE on the other hand is a one-way connection, meaning that you can only send events from the server to the client
- WebSockets has native support for most web browsers
- SSE is a simpler protocol and is transported over simple HTTP and does not require a custom protocol
- SSE offers easier scaling and does not require any custom firewall rules

For a demo of SSE and Laravel check out this post here:

- [How to create a simple event streaming in Laravel?](https://devdojo.com/bobbyiliev/how-to-create-a-simple-event-streaming-in-laravel)

# Conclusion

In case you like this guide, please starring the project on GitHub:

- [Laravel WebSockets 🛰](https://github.com/beyondcode/laravel-websockets)

To learn more about Laravel Echo, check out the [official documentation](https://laravel.com/docs/9.x/broadcasting).

For more information on how to use Laravel with Materialize and how to build real-time dashboards, check out this tutorial here:

- [Building Real-Time Dashboards with Laravel and Materialize](https://devdojo.com/bobbyiliev/how-to-connect-laravel-to-materialize)

If you war running this in production, you can follow the step from the official documentation on how to keeping the socket server running with supervisord:

- [Keeping the socket server running with supervisord](https://beyondco.de/docs/laravel-websockets/basic-usage/starting#keeping-the-socket-server-running-with-supervisord)

Hope that this helps!