<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\TradesController;
use App\Http\Controllers\StreamsController;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/

Route::get('/ws', [StreamsController::class, 'ws']);

Route::get('/', function () {
    return view('welcome');
});
