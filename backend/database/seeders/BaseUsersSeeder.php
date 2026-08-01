<?php

namespace Database\Seeders;

use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

/**
 * Essential accounts only — no demo subjects, lessons, or student activity.
 */
class BaseUsersSeeder extends Seeder
{
    public function run(): void
    {
        $admin = User::updateOrCreate(
            ['email' => 'admin@rshdacademy.com'],
            [
                'name' => 'RSHD Admin',
                'password' => Hash::make('password'),
                'role' => UserRole::Admin,
                'status' => UserStatus::Active,
                'password_set_at' => now(),
                'email_verified_at' => now(),
            ]
        );
        $admin->syncRoles([UserRole::Admin->value]);

        $instructor = User::updateOrCreate(
            ['email' => 'instructor@rshdacademy.com'],
            [
                'name' => 'د. محمد العبدالله',
                'password' => Hash::make('password'),
                'role' => UserRole::Instructor,
                'status' => UserStatus::Active,
                'password_set_at' => now(),
                'email_verified_at' => now(),
            ]
        );
        $instructor->syncRoles([UserRole::Instructor->value]);

        $student = User::updateOrCreate(
            ['email' => 'student@rshdacademy.com'],
            [
                'name' => 'أوس السميات',
                'phone' => '07901234567',
                'password' => Hash::make('password'),
                'role' => UserRole::Student,
                'status' => UserStatus::Active,
                'password_set_at' => now(),
                'email_verified_at' => now(),
            ]
        );
        $student->syncRoles([UserRole::Student->value]);
    }
}
