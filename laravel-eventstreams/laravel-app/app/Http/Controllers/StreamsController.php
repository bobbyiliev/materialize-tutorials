<?php

namespace App\Http\Controllers;

use Carbon\Carbon;
use App\Models\Trade;
use App\Models\MaterializeStream;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\StreamedResponse;

class StreamsController extends Controller
{
    /**
     * The stream source.
     *
     * @return \Illuminate\Http\Response
     */
    public function stream(){
        return response()->stream(function () {
            while (true) {
                echo "event: ping\n";
                $curDate = date(DATE_ISO8601);
                echo 'data: {"time": "' . $curDate . '"}';
                echo "\n\n";

                $trades = Trade::latest()->get();
                echo 'data: {"total_trades":' . $trades->count() . '}' . "\n\n";

                $latestTrades = Trade::with('user', 'stock')->latest()->first();
                if ($latestTrades) {
                    echo 'data: {"latest_trade_user":"' . $latestTrades->user->name . '", "latest_trade_stock":"' . $latestTrades->stock->symbol . '", "latest_trade_volume":"' . $latestTrades->volume . '", "latest_trade_price":"' . $latestTrades->stock->price . '", "latest_trade_type":"' . $latestTrades->type . '"}' . "\n\n";
                }

                //If you want to loop through a collection of items you can use the following:
                // if (count($trades) > 0) {
                //     foreach ($trades as $trade) {
                //         echo 'data: {"id": "' . $trade->id . '", "stock": "' . $trade->stock->symbol . '", "user": "' . $trade->user->name . '", "created_at": "' . $trade->created_at . '"}' . "\n\n";
                //     }
                // }

                ob_flush();
                flush();
                if (connection_aborted()) {break;}
                usleep(50000); // 50ms
            }
        }, 200, [
            'Cache-Control' => 'no-cache',
            'Content-Type' => 'text/event-stream',
        ]);
    }

    /**
     * The stream source.
     *
     * @return \Illuminate\Http\Response
     */
    public function tail()
    {

        return response()->stream(function () {
            DB::connection('materialize')->statement('BEGIN');
            DB::connection('materialize')->statement('DECLARE trades_c CURSOR FOR TAIL materialize_stream');
            while (true) {
                echo "event: ping\n";
                $curDate = date(DATE_ISO8601);
                echo 'data: {"time": "' . $curDate . '"}';
                echo "\n\n";

                $trades = DB::connection('materialize')->select('FETCH ALL trades_c');

                foreach ($trades as $trade) {
                    echo 'data: {"id": "' . $trade->trade_id . '", "stock": "' . $trade->stock_symbol . '", "user": "' . $trade->user_name . '", "created_at": "' . $trade->created_at . '"}' . "\n\n";
                }

                ob_flush();
                flush();
                if (connection_aborted()) {break;}
                usleep(50000); // 50ms
            }
        }, 200, [
            'Cache-Control' => 'no-cache',
            'Content-Type' => 'text/event-stream',
        ]);
    }

    /**
     * The stream source.
     *
     * @return \Illuminate\Http\Response
     */
    public function mzStream()
    {
        return response()->stream(function () {

            while (true) {
                echo "event: ping\n";
                $curDate = date(DATE_ISO8601);
                echo 'data: {"time": "' . $curDate . '"}';
                echo "\n\n";

                $trades = MaterializeStream::get();
                $latestTrades = MaterializeStream::latest()->first();

                echo 'data: {"total_trades":' . count($trades) . '}' . "\n\n";

                if ($latestTrades) {
                    echo 'data: {"latest_trade_user":"' . $latestTrades->user_name . '", "latest_trade_stock":"' . $latestTrades->stock_symbol . '", "latest_trade_volume":"' . $latestTrades->trade_volume . '", "latest_trade_price":"' . $latestTrades->stock_price . '", "latest_trade_type":"' . $latestTrades->trade_type . '"}' . "\n\n";
                }

                ob_flush();
                flush();
                if (connection_aborted()) {break;}
                usleep(50000); // 50ms
            }
        }, 200, [
            'Cache-Control' => 'no-cache',
            'Content-Type' => 'text/event-stream',
        ]);
    }
}