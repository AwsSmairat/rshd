<?php

namespace Tests\Feature\Security\Account;

use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Models\User;
use App\Services\DeviceService;
use App\Services\StudentSettingsService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\Group;
use Tests\TestCase;

#[Group('security')]
class StudentInternalPreferencesSecurityTest extends TestCase
{
    use RefreshDatabase;

    public function test_internal_device_binding_exemption_is_not_exposed_in_settings_payload(): void
    {
        $student = User::factory()->create([
            'role' => UserRole::Student,
            'status' => UserStatus::Active,
            'preferences' => [
                'theme' => 'dark',
                DeviceService::DEVICE_BINDING_EXEMPT_PREFERENCE => true,
            ],
        ]);

        $payload = app(StudentSettingsService::class)->buildSettingsPayload($student);

        $this->assertSame('dark', $payload['preferences']['theme']);
        $this->assertArrayNotHasKey(
            DeviceService::DEVICE_BINDING_EXEMPT_PREFERENCE,
            $payload['preferences'],
        );
    }

    public function test_student_preferences_update_cannot_change_internal_device_binding_exemption(): void
    {
        $student = User::factory()->create([
            'role' => UserRole::Student,
            'status' => UserStatus::Active,
            'preferences' => [
                DeviceService::DEVICE_BINDING_EXEMPT_PREFERENCE => true,
                'theme' => 'dark',
            ],
        ]);

        $updated = app(StudentSettingsService::class)->updatePreferences($student, [
            DeviceService::DEVICE_BINDING_EXEMPT_PREFERENCE => false,
            'theme' => 'light',
        ]);

        $this->assertTrue((bool) $updated->preference(DeviceService::DEVICE_BINDING_EXEMPT_PREFERENCE));
        $this->assertSame('light', $updated->preference('theme'));
    }
}
