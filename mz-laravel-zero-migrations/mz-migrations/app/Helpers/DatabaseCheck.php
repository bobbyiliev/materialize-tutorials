<?php

if ( !function_exists('dbCheck') )
{
    function dbCheck()
    {
        $migrations_folder = $_SERVER['HOME'] . '/.mz_migrations';
        $database_folder = $_SERVER['HOME'] . '/.mz_migrations' . '/' . strtolower(config('app.name'));
        $database        = config('database.connections.sqlite.database');
        echo $database;
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
