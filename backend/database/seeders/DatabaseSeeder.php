<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            RolePermissionSeeder::class,
            BaseUsersSeeder::class,
            LegalDocumentSeeder::class,
            // DemoDataSeeder intentionally not called — use only when needed for local demos.
        ]);
    }
}
