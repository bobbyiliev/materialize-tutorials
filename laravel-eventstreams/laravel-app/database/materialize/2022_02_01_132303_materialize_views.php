<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class MaterializeViews extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        DB::connection('materialize')->statement(
            "CREATE VIEWS FROM SOURCE mz_source2 (users,stocks,trades)"
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
            "DROP VIEW users"
        );
        DB::connection('materialize')->statement(
            "DROP VIEW stocks"
        );
        DB::connection('materialize')->statement(
            "DROP VIEW trades"
        );
    }
}
