<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     *
     * @return void
     */
    public function run()
    {
        User::factory(10000)->create();
        DB::table('stocks')->insert([
            ['symbol'=>'AAPL', 'price'=>'172.17'],
            ['symbol'=>'MSFT', 'price'=>'314.04'],
            ['symbol'=>'GOOGL', 'price'=>'2740.34'],
            ['symbol'=>'GOOG', 'price'=>'2740.09'],
            ['symbol'=>'AMZN', 'price'=>'3251.08'],
            ['symbol'=>'TSLA', 'price'=>'1026.96'],
            ['symbol'=>'FB', 'price'=>'331.79'],
            ['symbol'=>'NVDA', 'price'=>'272.47'],
            ['symbol'=>'TSM', 'price'=>'123.50'],
            ['symbol'=>'JPM', 'price'=>'167.16'],
            ['symbol'=>'V', 'price'=>'216.96'],
            ['symbol'=>'JNJ', 'price'=>'173.95'],
            ['symbol'=>'UNH', 'price'=>'458.60'],
            ['symbol'=>'BAC', 'price'=>'49.18'],
            ['symbol'=>'HD', 'price'=>'393.61'],
            ['symbol'=>'WMT', 'price'=>'144.89'],
            ['symbol'=>'PG', 'price'=>'162.74'],
            ['symbol'=>'MA', 'price'=>'369.65'],
            ['symbol'=>'BABA', 'price'=>'129.81'],
            ['symbol'=>'PFE', 'price'=>'55.72'],
            ['symbol'=>'ASML', 'price'=>'756.10'],
            ['symbol'=>'XOM', 'price'=>'68.88'],
            ['symbol'=>'DIS', 'price'=>'157.83'],
            ['symbol'=>'TM', 'price'=>'200.44'],
            ['symbol'=>'NTES', 'price'=>'99.71']
        ]);
    }
}
