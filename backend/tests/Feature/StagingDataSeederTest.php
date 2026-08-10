<?php

namespace Tests\Feature;

use Database\Seeders\StagingDataSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class StagingDataSeederTest extends TestCase
{
    use RefreshDatabase;

    public function test_staging_data_seeder_runs_on_clean_database(): void
    {
        $this->seed(StagingDataSeeder::class);

        $this->assertDatabaseHas('users', ['email' => 'admin@staging.rshd.test']);
        $this->assertDatabaseHas('users', ['email' => 'student-active@staging.rshd.test']);
        $this->assertDatabaseHas('users', ['email' => 'student-blocked@staging.rshd.test']);
        $this->assertDatabaseHas('subjects', ['title' => 'Staging Validation Course']);
        $this->assertDatabaseHas('videos', ['title' => 'Staging Bunny Video']);
        $this->assertDatabaseHas('lesson_files', ['title' => 'Staging Bunny PDF']);
    }
}
