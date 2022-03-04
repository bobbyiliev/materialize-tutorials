<?php

namespace App\Http\Controllers;

use Carbon\Carbon;
use App\Models\Trade;
use App\Events\NewTrade;
use App\Models\MaterializeStream;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\StreamedResponse;

class StreamsController extends Controller
{
    public function ws()
    {
        return response()->stream(function () {
            DB::connection('materialize')->statement('BEGIN');
            DB::connection('materialize')->statement('DECLARE trades_c CURSOR FOR TAIL latest_trades');
            while (true) {
                echo "event: ping\n";
                $curDate = date(DATE_ISO8601);
                echo 'data: {"time": "' . $curDate . '"}';
                echo "\n\n";

                $trades = DB::connection('materialize')->select('FETCH ALL trades_c');

                foreach ($trades as $trade) {
                    echo 'data: {"id": "' . $trade->trade_id . '", "stock": "' . $trade->stock_symbol . '", "user": "' . $trade->user_name . '", "created_at": "' . $trade->created_at . '"}' . "\n\n";
                    event(new NewTrade($trade));
                }

                ob_flush();
                flush();
                if (connection_aborted()) {break;}
            }
        }, 200, [
            'Cache-Control' => 'no-cache',
            'Content-Type' => 'text/event-stream',
        ]);

    }

}