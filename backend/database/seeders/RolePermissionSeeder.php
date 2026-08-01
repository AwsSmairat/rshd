<?php

namespace Database\Seeders;

use App\Enums\UserRole;
use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;

class RolePermissionSeeder extends Seeder
{
    public function run(): void
    {
        app()[\Spatie\Permission\PermissionRegistrar::class]->forgetCachedPermissions();

        $permissions = [
            'manage users',
            'manage instructors',
            'manage students',
            'manage subjects',
            'manage lessons',
            'manage videos',
            'manage files',
            'manage enrollments',
            'manage assignments',
            'manage quizzes',
            'manage grades',
            'manage announcements',
            'manage notifications',
            'view audit logs',
        ];

        foreach ($permissions as $permission) {
            Permission::firstOrCreate(['name' => $permission, 'guard_name' => 'web']);
            Permission::firstOrCreate(['name' => $permission, 'guard_name' => 'sanctum']);
        }

        $adminRole = Role::firstOrCreate(['name' => UserRole::Admin->value, 'guard_name' => 'web']);
        $instructorRole = Role::firstOrCreate(['name' => UserRole::Instructor->value, 'guard_name' => 'web']);
        $studentRole = Role::firstOrCreate(['name' => UserRole::Student->value, 'guard_name' => 'web']);

        Role::firstOrCreate(['name' => UserRole::Admin->value, 'guard_name' => 'sanctum']);
        Role::firstOrCreate(['name' => UserRole::Instructor->value, 'guard_name' => 'sanctum']);
        Role::firstOrCreate(['name' => UserRole::Student->value, 'guard_name' => 'sanctum']);

        $adminRole->syncPermissions(Permission::where('guard_name', 'web')->get());
        $instructorRole->syncPermissions([
            'manage subjects',
            'manage lessons',
            'manage videos',
            'manage files',
            'manage enrollments',
            'manage assignments',
            'manage quizzes',
            'manage grades',
            'manage announcements',
        ]);
    }
}
