<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class MaterializeSource extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        DB::connection('materialize')->statement(
            "CREATE MATERIALIZED SOURCE mz_source2 FROM POSTGRES
            CONNECTION 'user=postgres port=5432 host=postgres dbname=postgres password=postgres'
            PUBLICATION 'mz_source'"
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
            "DROP SOURCE mz_source2"
        );
    }
}
