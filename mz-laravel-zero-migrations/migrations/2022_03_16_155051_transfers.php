<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        // Create the new `transfers_new` view
        DB::connection('materialize')->statement(
            "CREATE TABLE transfers_new (id int, name text, amount int)"
        );
        // Rename the old `transfers` view to `transfers_old`
        DB::connection('materialize')->statement(
            "ALTER TABLE transfers RENAME TO transfers_old"
        );
        // Rename the new `transfers_new` view to `transfers`
        DB::connection('materialize')->statement(
            "ALTER TABLE transfers_new RENAME TO transfers"
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
            "DROP TABLE IF EXISTS transfers, transfers_old, transfers_new"
        );
    }
};
