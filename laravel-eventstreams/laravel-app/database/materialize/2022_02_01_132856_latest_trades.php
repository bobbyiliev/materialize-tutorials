<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class LatestTrades extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        DB::connection('materialize')->statement(
            "CREATE MATERIALIZED VIEW latest_trades AS
            SELECT * FROM materialize_stream
                WHERE (mz_logical_timestamp() >= (extract('epoch' from created_at)*1000)::bigint
                AND mz_logical_timestamp() < (extract('epoch' from created_at)*1000)::bigint + 60000);"
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
            "DROP VIEW latest_trades"
        );
    }
}
