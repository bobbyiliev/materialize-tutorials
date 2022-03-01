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
        echo "LatestTrades view created\n Waiting a few seconds for the view to be populated...\n";
        sleep(5);

        DB::connection('materialize')->statement(
            "CREATE MATERIALIZED VIEW latest_trades_new AS
            SELECT * FROM materialize_stream
                WHERE (mz_logical_timestamp() >= (extract('epoch' from created_at)*1000)::bigint
                AND mz_logical_timestamp() < (extract('epoch' from created_at)*1000)::bigint + 60000);"
        );
        sleep(5);

        // Some logic to check if the view is ready
        // while (true) {
        //     $count = DB::connection('materialize')->table('latest_trades')->count();
        //     $count_new = DB::connection('materialize')->table('latest_trades_new')->count();
        //     echo "Count: $count, Count_new: $count_new\n";
        //     if ($count == $count_new) {
        //         break;
        //     }
        //     sleep(1);
        // }

        // Rename the old view to the new view
        DB::connection('materialize')->statement(
            "ALTER VIEW latest_trades RENAME TO latest_trades_old;"
        );
        // Rename the new view to the old view
        DB::connection('materialize')->statement(
            "ALTER VIEW latest_trades_new RENAME TO latest_trades;"
        );
        // Drop the old view
        DB::connection('materialize')->statement(
            "DROP VIEW IF EXISTS latest_trades_old;"
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
            "DROP VIEW IF EXISTS latest_trades;"
        );
        DB::connection('materialize')->statement(
            "DROP VIEW IF EXISTS latest_trades_old;"
        );
        DB::connection('materialize')->statement(
            "DROP VIEW IF EXISTS latest_trades_new;"
        );
    }
}
