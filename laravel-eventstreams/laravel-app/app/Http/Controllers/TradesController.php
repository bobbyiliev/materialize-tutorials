<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Stock;
use App\Models\Trade;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\StreamedResponse;

class TradesController extends Controller
{
    public function store(Request $request)
    {
        $this->validate($request, [
            'user_id' => 'required|exists:users,id',
            'stock_id' => 'required|exists:stocks,id',
            'volume' => 'required|numeric',
            'type' => 'required|in:buy,sell',
        ]);

        $user = User::findOrFail($request->user_id);
        $stock = Stock::findOrFail($request->stock_id);

        $user->trades()->create([
            'stock_id' => $stock->id,
            'volume' => $request->volume,
            'type' => $request->type,
        ]);

        return response()->json([
            'message' => 'Trade created successfully'
        ]);
    }

    public function index()
    {
        return response()->json([
            'trades' => User::first()->trades()->with('stock')->get()
        ]);
    }

    public function stream()
    {

        ob_start();
        return response()->stream(function () {
            while (true) {
                if (connection_aborted()) {
                    break;
                }
                if ($messages = Trade::where('created_at', '>=', \Carbon\Carbon::now()->subSeconds(60))->get()) {
                    echo "event: ping\n", "data: {$messages}", "\n\n";
                }
                ob_flush();
                flush();
                usleep(200000);
            }
        }, 200, [
            'Cache-Control' => 'no-cache',
            'Content-Type' => 'text/event-stream',
        ]);
    }
}