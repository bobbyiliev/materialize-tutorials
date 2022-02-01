<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class MaterializeStream extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        DB::connection('materialize')->statement(
            "CREATE VIEW materialize_stream AS
            SELECT
                users.id AS user_id,
                users.name AS user_name,
                stocks.id AS stock_id,
                stocks.symbol AS stock_symbol,
                stocks.price AS stock_price,
                trades.id AS trade_id,
                trades.volume AS trade_volume,
                trades.type AS trade_type,
                trades.created_at AS created_at,
                trades.updated_at AS updated_at
            FROM users JOIN trades ON users.id = trades.user_id JOIN stocks ON trades.stock_id = stocks.id"
        );
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        DB::connection('materialize')->statement(
            "DROP VIEW materialize_stream"
        );
    }
}
