<?php

namespace Tests\Feature\Filament;

use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Filament\Pages\Settings;
use App\Models\User;
use App\Services\PlatformSettingsService;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Livewire\Livewire;
use Tests\TestCase;

class SettingsSessionHelpTest extends TestCase
{
    use RefreshDatabase;

    public function test_settings_explain_sessions_and_show_the_value_in_force(): void
    {
        $this->seed(RolePermissionSeeder::class);
        $admin = User::factory()->create([
            'role' => UserRole::Admin,
            'status' => UserStatus::Active,
            'email_verified_at' => now(),
        ]);
        $admin->assignRole('admin');

        // An old out-of-range value is shown as the bound actually applied.
        app(PlatformSettingsService::class)->set('session_lifetime_minutes', 100000, 'security');

        $this->actingAs($admin);

        Livewire::test(Settings::class)
            ->assertFormFieldExists('session_lifetime_minutes', 'securityForm')
            ->assertSet('securityData.session_lifetime_minutes', PlatformSettingsService::PANEL_SESSION_MAX_MINUTES);
    }
}
