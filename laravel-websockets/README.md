# How to use Laravel WebSockets 🛰 with Materialize



# Introduction

In this guide, we will walk you through how to use Laravel WebSockets. We will be using the [Laravel WebSockets](https://beyondco.de/docs/laravel-websockets/) package which is a great replacement for [Pusher](https://pusher.com/).

The best way of using the Laravel WebSockets package is as a direct replacement for Pusher.

# Prerequisites

In order to follow along you would need to have Laravel installed

# Installing Laravel WebSockets

Commands:

```
composer require beyondcode/laravel-websockets
```

```
php artisan vendor:publish --provider="BeyondCode\LaravelWebSockets\WebSocketsServiceProvider" --tag="migrations"
```


```
php artisan migrate
```


```
php artisan vendor:publish --provider="BeyondCode\LaravelWebSockets\WebSocketsServiceProvider" --tag="config"
```

Starting the websocket server:

```
php artisan websockets:serve
```

# WebSockets Laravel Configuration

Install the Pusher package:

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
        'encrypted' => true,
        'host' => '127.0.0.1',
        'port' => 6001,
        'scheme' => 'http'
    ],
],
```

# Configuring Laravel Echo

Install the Laravel Echo dependency:

```
npm install --save-dev laravel-echo pusher-js
```

Then in the `resources/js/bootstrap.js` file, add the following code:


```javascript
import Echo from "laravel-echo"

window.Pusher = require('pusher-js');

window.Echo = new Echo({
    broadcaster: 'pusher',
    key: 'your-pusher-key',
    wsHost: window.location.hostname,
    wsPort: 6001,
    forceTLS: false,
    disableStats: true,
});
```

# WebSockets vs SSE

Advantages of SSE over Websockets:

- Transported over simple HTTP instead of a custom protocol
- Can be poly-filled with javascript to "backport" SSE to browsers that do not support it yet.
- Built in support for re-connection and event-id
- Simpler protocol
- No trouble with corporate firewalls doing packet inspection

Advantages of Websockets over SSE:

- Real time, two directional communication.
- Native support in more browsers

Ideal use cases of SSE:

- Stock ticker streaming
- twitter feed updating
- Notifications to browser

SSE gotchas:

- No binary support
- Maximum open connections limit

For a demo of SSE and Laravel check out this post here:

- [How to create a simple event streaming in Laravel?](https://devdojo.com/bobbyiliev/how-to-create-a-simple-event-streaming-in-laravel)

# Conclusion

In case that you like this guide, please starring the project on GitHub:

- [Laravel WebSockets 🛰](https://github.com/beyondcode/laravel-websockets)