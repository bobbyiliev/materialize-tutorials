<?php

namespace App\Commands;

use Illuminate\Console\Scheduling\Schedule;
use LaravelZero\Framework\Commands\Command;
use function Termwind\{render};

class InstallCommand extends Command
{
    /**
     * The signature of the command.
     *
     * @var string
     */
    protected $signature = 'install {name=Artisan}';

    /**
     * The description of the command.
     *
     * @var string
     */
    protected $description = 'Setup the initial SQLite database';

    /**
     * Execute the console command.
     *
     * @return mixed
     */
    public function handle()
    {

        if($this->dbCheck()){
            render(<<<'HTML'
                <div class="py-1 ml-2">
                    <div class="px-1 bg-blue-300 text-black">Materialize Migrations</div>
                    <em class="ml-1">
                    SQLite database created successfully:
                    </em>
                </div>
            HTML);
            $this->info(config('database.connections.sqlite.database'));
        } else {
            render(<<<'HTML'
                <div class="py-1 ml-2">
                    <div class="px-1 bg-red-300 text-black">Materialize Migrations</div>
                    <em class="ml-1">
                    SQLite database already exists at:
                    </em>
                </div>
            HTML);
            $this->info(config('database.connections.sqlite.database'));
        }

    }

    /**
     * Define the command's schedule.
     *
     * @param  \Illuminate\Console\Scheduling\Schedule  $schedule
     * @return void
     */
    public function schedule(Schedule $schedule)
    {
        // $schedule->command(static::class)->everyMinute();
    }

    public function dbCheck()
    {

        $migrations_folder = $_SERVER['HOME'] . '/.mz_migrations';
        $database_folder = $_SERVER['HOME'] . '/.mz_migrations' . '/' . strtolower(config('app.name'));
        $database        = config('database.connections.sqlite.database');

        if (!\File::exists($database_folder)) {
            try {
                \File::makeDirectory($migrations_folder, 0700);
                \File::makeDirectory($database_folder, 0700);
            } catch (\Throwable $th) {
                return "An error occured while creating your .todoist folder " . $database_folder;
            }
        }

        if (!\File::exists($database)) {
            try {
                touch($database);
                chmod($database, 0600);
                return true;
            } catch (\Throwable $th) {
                // throw $th;
                return "An error occured while creating your database at " . $database;
            }
        }

        // if (!Schema::hasTable('users')) {
        //     Artisan::call('migrate');
        // }
        return false;

    }
}
