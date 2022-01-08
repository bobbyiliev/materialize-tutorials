<?php

namespace App\Http\Controllers;

use Carbon\Carbon;
use App\Models\Trade;
use Symfony\Component\HttpFoundation\StreamedResponse;

class StreamsController extends Controller
{
    /**
     * The stream source.
     *
     * @return \Illuminate\Http\Response
     */
    public function __invoke(){
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
                    echo 'data: {"latest_trade":"' . $latestTrades->user->name . ':' . $latestTrades->stock->symbol . '"}' . "\n\n";
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
}