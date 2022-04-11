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
| import './routes/customer''
|
*/

import Route from '@ioc:Adonis/Core/Route'

Route.get('/', 'OrdersController.index')
Route.post('/order', 'OrdersController.order')
Route.get('/stream', 'OrdersController.stream')
Route.get('/delivery', 'OrdersController.delivery')
Route.get('/delivery/:id', 'OrdersController.deliveryStatus')

Route.get('/hello', async ({ view }) => {
  return view.render('welcome')
})
