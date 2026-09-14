<?php

namespace Tests\Feature\Security\Auth;


use PHPUnit\Framework\Attributes\Group;
use App\Enums\GradeSourceType;
use App\Enums\UserStatus;
use App\Models\Grade;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Feature\Security\Concerns\CreatesEnrollmentScenario;
use Tests\TestCase;

#[Group('security')]
class BlockedStudentSessionTest extends TestCase
{
    use CreatesEnrollmentScenario;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
    }

    public function test_blocking_a_student_revokes_existing_api_tokens(): void
    {
        $student = $this->createStudent(['email' => 'block-revoke@rshd.test']);
        $token = $student->createToken('api')->plainTextToken;

        $this->withToken($token)->getJson('/api/v1/me')->assertOk();

        $student->forceFill(['status' => UserStatus::Blocked])->save();

        $this->assertSame(0, $student->fresh()->tokens()->count());

        $this->app['auth']->forgetGuards();

        $this->withToken($token)->getJson('/api/v1/me')->assertUnauthorized();
    }

    public function test_blocked_student_cannot_access_authenticated_learning_routes(): void
    {
        $student = $this->createStudent(['email' => 'block-grades@rshd.test']);
        $subject = $this->createSubject();
        Grade::query()->create([
            'student_id' => $student->id,
            'subject_id' => $subject->id,
            'source_type' => GradeSourceType::Manual,
            'source_id' => null,
            'grade' => 70,
            'notes' => 'blocked-session-grade',
        ]);
        $student->forceFill(['status' => UserStatus::Blocked])->saveQuietly();
        $token = $student->createToken('api')->plainTextToken;

        $this->withToken($token)->getJson('/api/v1/grades')->assertForbidden();
        $this->withToken($token)->getJson('/api/v1/quizzes')->assertForbidden();
        $this->withToken($token)->getJson('/api/v1/assignments')->assertForbidden();
        $this->withToken($token)->getJson('/api/v1/notifications')->assertForbidden();
    }

    public function test_blocked_student_can_still_logout(): void
    {
        $student = $this->createStudent(['email' => 'block-logout@rshd.test']);
        $student->forceFill(['status' => UserStatus::Blocked])->saveQuietly();
        $token = $student->createToken('api')->plainTextToken;

        $this->withToken($token)
            ->postJson('/api/v1/logout')
            ->assertOk()
            ->assertJsonPath('success', true);
    }
}
