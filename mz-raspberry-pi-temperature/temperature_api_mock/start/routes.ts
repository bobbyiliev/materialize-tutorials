/*
|--------------------------------------------------------------------------
| Routes
|--------------------------------------------------------------------------
|
| This file is dedicated for defining HTTP routes. A single file is enough
| for majority of projects, however you can define routes in different
| files and just make sure to import them inside this file. For example
|
| Define routes in following two files
| ├── start/routes/cart.ts
| ├── start/routes/customer.ts
|
| and then import them inside `start/routes.ts` as follows
|
| import './routes/cart'
| import './routes/customer'
|
*/

import Route from '@ioc:Adonis/Core/Route'
import Database from '@ioc:Adonis/Lucid/Database'

Route.get('/temperature', async ({ request }) => {


  let name = 'raspberry-1';
  if (request.qs().name != null) {
    name = request.qs().name;
  }

  let timestamp = '2021-11-21 19:52:49';
  if (request.qs().timestamp != null) {
    timestamp = request.qs().timestamp;
  }

  let temperature = '41.1';
  if (request.qs().temperature != null) {
    temperature = request.qs().temperature;
  }

  console.log(name, timestamp, temperature)

  await Database
  .insertQuery()
  .table('iot.sensors')
  .insert({ name: name, timestamp: timestamp, temperature: temperature})

})
