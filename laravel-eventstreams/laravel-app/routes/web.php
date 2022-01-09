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

Route::post('/trade', [TradesController::class, 'store']);
Route::get('/stream', [StreamsController::class, 'stream']);
Route::get('/mz-stream', [StreamsController::class, 'mzStream']);
Route::get('/tail', [StreamsController::class, 'tail']);

Route::get('/', function () {
    return view('welcome');
});
