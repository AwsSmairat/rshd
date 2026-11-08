<?php

namespace Tests\Feature\Security;

use App\Models\StudentDevice;
use App\Services\DeviceService;
use App\Services\PlatformSettingsService;
use App\Services\StudentSessionService;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use PHPUnit\Framework\Attributes\Group;
use Tests\Feature\Security\Concerns\CreatesEnrollmentScenario;
use Tests\TestCase;

/**
 * Student sessions never expire on their own; they end when the student or
 * an admin ends them. The admin panel session is bounded by the settings.
 */
#[Group('security')]
class StudentSessionLifecycleTest extends TestCase
{
    use CreatesEnrollmentScenario;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
    }

    public function test_login_issues_a_session_bound_to_the_device(): void
    {
        $student = $this->createStudent(['password' => Hash::make('secret-password')]);

        $this->postJson('/api/v1/login', [
            'email' => $student->email,
            'password' => 'secret-password',
            'device_id' => 'phone-a',
            'device_name' => 'Phone A',
            'platform' => 'ios',
        ])->assertOk();

        $this->assertSame(['device:phone-a'], $student->tokens()->pluck('name')->all());
    }

    public function test_student_sessions_have_no_time_limit(): void
    {
        app(PlatformSettingsService::class)->applySecurityPreferences();

        $this->assertNull(config('sanctum.expiration'));
    }

    public function test_the_panel_session_is_kept_within_its_bounds(): void
    {
        $settings = app(PlatformSettingsService::class);

        $settings->set('session_lifetime_minutes', 100000, 'security');
        $settings->applySecurityPreferences();
        $this->assertSame(PlatformSettingsService::PANEL_SESSION_MAX_MINUTES, config('session.lifetime'));

        $settings->set('session_lifetime_minutes', 1, 'security');
        $settings->applySecurityPreferences();
        $this->assertSame(PlatformSettingsService::PANEL_SESSION_MIN_MINUTES, config('session.lifetime'));
    }

    public function test_resetting_devices_signs_the_student_out_everywhere(): void
    {
        $student = $this->createStudent();
        $sessions = app(StudentSessionService::class);
        $sessions->issue($student, 'phone-a');
        $sessions->issue($student, 'tablet-b');

        app(DeviceService::class)->resetStudentDevices($student);

        $this->assertSame(0, $student->tokens()->count());
    }

    public function test_admin_sign_out_ends_every_session(): void
    {
        $student = $this->createStudent();
        $sessions = app(StudentSessionService::class);
        $sessions->issue($student, 'phone-a');
        $sessions->issue($student, null);

        $this->assertSame(2, $sessions->endAll($student));
        $this->assertSame(0, $student->tokens()->count());
    }

    public function test_revoking_a_device_signs_out_only_that_device(): void
    {
        $student = $this->createStudent();
        $sessions = app(StudentSessionService::class);
        $current = $sessions->issue($student, 'phone-a');
        $sessions->issue($student, 'tablet-b');

        $tablet = StudentDevice::query()->create([
            'student_id' => $student->id,
            'device_id' => 'tablet-b',
            'is_active' => true,
            'last_login_at' => now(),
        ]);

        $this->withToken($current->plainTextToken)
            ->deleteJson('/api/v1/student/devices/'.$tablet->id, [], ['X-Device-Id' => 'phone-a'])
            ->assertOk();

        $this->assertSame(['device:phone-a'], $student->tokens()->pluck('name')->all());
    }

    public function test_responses_carry_the_security_headers(): void
    {
        $this->get('/')
            ->assertHeader('X-Frame-Options', 'SAMEORIGIN')
            ->assertHeader('Content-Security-Policy', "frame-ancestors 'self'")
            ->assertHeader('X-Content-Type-Options', 'nosniff')
            ->assertHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
    }
}
