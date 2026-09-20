<?php

namespace Tests\Feature\Security\Auth;


use PHPUnit\Framework\Attributes\Group;
use App\Models\StudentDevice;
use App\Models\User;
use App\Services\DeviceService;
use App\Services\PlatformSettingsService;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\RateLimiter;
use Tests\Feature\Security\Concerns\CreatesEnrollmentScenario;
use Tests\TestCase;

#[Group('security')]
class LoginDeviceMismatchTest extends TestCase
{
    use CreatesEnrollmentScenario;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
        RateLimiter::clear('auth-login');

        /** @var PlatformSettingsService $settings */
        $settings = app(PlatformSettingsService::class);
        $settings->set('email_verification_required', false, 'registration');
        $settings->set('device_binding_enabled', true, 'students');
        $settings->set('device_id_required', true, 'students');
        $settings->set('max_active_devices', 1, 'students');
    }

    public function test_login_with_valid_credentials_and_foreign_device_returns_device_mismatch(): void
    {
        $student = $this->createStudent([
            'email' => 'device-login@rshd.test',
            'password' => Hash::make('secret-password'),
        ]);

        $this->createActiveDevice($student, 'registered-device');

        $response = $this->postJson('/api/v1/login', [
            'email' => $student->email,
            'password' => 'secret-password',
            'device_id' => 'foreign-device',
            'device_name' => 'Other Phone',
            'platform' => 'ios',
        ]);

        $response
            ->assertForbidden()
            ->assertJsonPath('success', false)
            ->assertJsonPath('message', DeviceService::DEVICE_MISMATCH_MESSAGE)
            ->assertJsonPath('error_code', DeviceService::DEVICE_MISMATCH_CODE);
    }

    public function test_login_with_matching_device_succeeds(): void
    {
        $student = $this->createStudent([
            'email' => 'device-match@rshd.test',
            'password' => Hash::make('secret-password'),
        ]);

        $this->createActiveDevice($student, 'registered-device');

        $this->postJson('/api/v1/login', [
            'email' => $student->email,
            'password' => 'secret-password',
            'device_id' => 'registered-device',
            'device_name' => 'My Phone',
            'platform' => 'ios',
        ])
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['token', 'user']]);
    }

    public function test_foreign_device_returns_mismatch_before_password_check(): void
    {
        $student = $this->createStudent([
            'email' => 'device-early@rshd.test',
            'password' => Hash::make('secret-password'),
        ]);

        $this->createActiveDevice($student, 'registered-device');

        $this->postJson('/api/v1/login', [
            'email' => $student->email,
            'password' => 'wrong-password',
            'device_id' => 'foreign-device',
            'device_name' => 'Other Phone',
            'platform' => 'ios',
        ])
            ->assertForbidden()
            ->assertJsonPath('error_code', DeviceService::DEVICE_MISMATCH_CODE)
            ->assertJsonPath('message', DeviceService::DEVICE_MISMATCH_MESSAGE);
    }

    public function test_device_binding_exempt_student_can_login_from_foreign_device(): void
    {
        $student = $this->createStudent([
            'email' => 'reviewer-device-exempt@rshd.test',
            'password' => Hash::make('secret-password'),
            'preferences' => [
                DeviceService::DEVICE_BINDING_EXEMPT_PREFERENCE => true,
            ],
        ]);

        $this->createActiveDevice($student, 'registered-device');

        $this->postJson('/api/v1/login', [
            'email' => $student->email,
            'password' => 'secret-password',
            'device_id' => 'foreign-device',
            'device_name' => 'Google Play Reviewer Device',
            'platform' => 'android',
        ])
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['token', 'user']]);

        $this->assertSame(1, $student->studentDevices()->where('is_active', true)->count());
    }

    public function test_non_boolean_device_binding_exemption_does_not_bypass_device_binding(): void
    {
        $student = $this->createStudent([
            'email' => 'reviewer-non-boolean-exempt@rshd.test',
            'password' => Hash::make('secret-password'),
            'preferences' => [
                DeviceService::DEVICE_BINDING_EXEMPT_PREFERENCE => 'true',
            ],
        ]);

        $this->createActiveDevice($student, 'registered-device');

        $this->postJson('/api/v1/login', [
            'email' => $student->email,
            'password' => 'secret-password',
            'device_id' => 'foreign-device',
            'device_name' => 'Other Reviewer Device',
            'platform' => 'android',
        ])
            ->assertForbidden()
            ->assertJsonPath('error_code', DeviceService::DEVICE_MISMATCH_CODE)
            ->assertJsonPath('message', DeviceService::DEVICE_MISMATCH_MESSAGE);
    }

    protected function createActiveDevice(User $student, string $deviceId): StudentDevice
    {
        return StudentDevice::query()->create([
            'student_id' => $student->id,
            'device_id' => $deviceId,
            'device_name' => 'Registered Device',
            'platform' => 'ios',
            'is_active' => true,
            'last_login_at' => now(),
        ]);
    }
}
