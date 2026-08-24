<?php

namespace Tests\Feature\Security\Auth;

use App\Enums\GradeSourceType;
use App\Models\Grade;
use App\Services\PlatformSettingsService;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Feature\Security\Concerns\CreatesEnrollmentScenario;
use Tests\TestCase;

/**
 * @group security
 */
class UnverifiedStudentSessionTest extends TestCase
{
    use CreatesEnrollmentScenario;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
        app(PlatformSettingsService::class)->set('email_verification_required', true, 'registration');
    }

    public function test_unverified_student_cannot_access_authenticated_learning_routes(): void
    {
        $student = $this->createStudent([
            'email' => 'unverified-grades@rshd.test',
            'email_verified_at' => null,
        ]);
        $subject = $this->createSubject();
        Grade::query()->create([
            'student_id' => $student->id,
            'subject_id' => $subject->id,
            'source_type' => GradeSourceType::Manual,
            'source_id' => null,
            'grade' => 80,
            'notes' => 'unverified-session-grade',
        ]);
        $token = $student->createToken('api')->plainTextToken;

        $this->withToken($token)->getJson('/api/v1/me')->assertForbidden();
        $this->withToken($token)->getJson('/api/v1/grades')->assertForbidden();
        $this->withToken($token)->getJson('/api/v1/quizzes')->assertForbidden();
        $this->withToken($token)->getJson('/api/v1/assignments')->assertForbidden();
        $this->withToken($token)->getJson('/api/v1/subjects')->assertForbidden();
    }

    public function test_unverified_student_can_still_logout(): void
    {
        $student = $this->createStudent([
            'email' => 'unverified-logout@rshd.test',
            'email_verified_at' => null,
        ]);
        $token = $student->createToken('api')->plainTextToken;

        $this->withToken($token)
            ->postJson('/api/v1/logout')
            ->assertOk()
            ->assertJsonPath('success', true);
    }
}
