<?php

namespace Tests\Feature\Security\Auth;


use PHPUnit\Framework\Attributes\Group;
use App\Enums\UserStatus;
use App\Services\PlatformSettingsService;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Laravel\Sanctum\Sanctum;
use Tests\Feature\Security\Concerns\CreatesEnrollmentScenario;
use Tests\TestCase;

#[Group('security')]
class MeSecurityTest extends TestCase
{
    use CreatesEnrollmentScenario;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
        Cache::flush();
    }

    public function test_authenticated_student_receives_own_profile_only(): void
    {
        $studentA = $this->createStudent(['email' => 'me-a@rshd.test', 'name' => 'Student A']);
        $this->createStudent(['email' => 'me-b@rshd.test', 'name' => 'Student B']);

        Sanctum::actingAs($studentA);

        $response = $this->getJson('/api/v1/me')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.id', $studentA->id)
            ->assertJsonPath('data.email', 'me-a@rshd.test');

        $data = $response->json('data');
        $this->assertArrayNotHasKey('password', $data);
        $this->assertArrayNotHasKey('remember_token', $data);
    }

    public function test_anonymous_user_cannot_access_me(): void
    {
        $this->getJson('/api/v1/me')->assertUnauthorized();
    }

    public function test_me_response_does_not_expose_internal_secrets(): void
    {
        $student = $this->createStudent(['email' => 'me-secrets@rshd.test']);

        Sanctum::actingAs($student);

        $response = $this->getJson('/api/v1/me')->assertOk();

        $data = $response->json('data');
        $this->assertArrayNotHasKey('password', $data);
        $this->assertArrayNotHasKey('remember_token', $data);
        $this->assertArrayHasKey('id', $data);
        $this->assertArrayHasKey('email', $data);
        $this->assertArrayHasKey('role', $data);
    }

    public function test_unverified_student_is_blocked_when_verification_required(): void
    {
        app(PlatformSettingsService::class)->set('email_verification_required', true, 'registration');

        $student = $this->createStudent([
            'email' => 'me-unverified@rshd.test',
            'email_verified_at' => null,
        ]);

        Sanctum::actingAs($student);

        $this->getJson('/api/v1/me')->assertForbidden();
    }

    public function test_blocked_student_cannot_access_me(): void
    {
        $student = $this->createStudent(['email' => 'me-blocked@rshd.test']);
        $student->forceFill(['status' => UserStatus::Blocked])->save();

        Sanctum::actingAs($student);

        $this->getJson('/api/v1/me')->assertForbidden();
    }
}
