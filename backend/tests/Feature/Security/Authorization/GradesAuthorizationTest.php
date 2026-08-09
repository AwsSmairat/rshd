<?php

namespace Tests\Feature\Security\Authorization;

use App\Enums\GradeSourceType;
use App\Enums\UserStatus;
use App\Models\Grade;
use App\Models\User;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Feature\Security\Concerns\CreatesEnrollmentScenario;
use Tests\TestCase;

/**
 * @group security
 */
class GradesAuthorizationTest extends TestCase
{
    use CreatesEnrollmentScenario;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
    }

    public function test_student_sees_only_own_grades(): void
    {
        $studentA = $this->createStudent(['email' => 'grades-a@rshd.test']);
        $studentB = $this->createStudent(['email' => 'grades-b@rshd.test']);

        $gradeA = $this->createGradeFor($studentA, 88.5, 'grade-a-marker');
        $gradeB = $this->createGradeFor($studentB, 42.0, 'grade-b-marker');

        Sanctum::actingAs($studentA);

        $response = $this->getJson('/api/v1/grades')
            ->assertOk()
            ->assertJsonPath('success', true);

        $gradeIds = collect($response->json('data'))->pluck('id')->all();

        $this->assertContains($gradeA->id, $gradeIds);
        $this->assertNotContains($gradeB->id, $gradeIds);
    }

    public function test_student_cannot_scope_grades_via_query_parameters(): void
    {
        $studentA = $this->createStudent(['email' => 'grades-query-a@rshd.test']);
        $studentB = $this->createStudent(['email' => 'grades-query-b@rshd.test']);

        $gradeA = $this->createGradeFor($studentA, 91.0, 'grade-query-a');
        $gradeB = $this->createGradeFor($studentB, 55.0, 'grade-query-b');

        Sanctum::actingAs($studentA);

        $response = $this->getJson('/api/v1/grades?'.http_build_query([
            'student_id' => $studentB->id,
            'user_id' => $studentB->id,
            'id' => $studentB->id,
        ]))
            ->assertOk()
            ->assertJsonPath('success', true);

        $gradeIds = collect($response->json('data'))->pluck('id')->all();

        $this->assertContains($gradeA->id, $gradeIds);
        $this->assertNotContains($gradeB->id, $gradeIds);
    }

    public function test_anonymous_user_cannot_list_grades(): void
    {
        $this->getJson('/api/v1/grades')
            ->assertUnauthorized();
    }

    public function test_blocked_student_current_grades_policy(): void
    {
        $student = $this->createStudent(['email' => 'grades-blocked@rshd.test']);
        $this->createGradeFor($student, 70.0, 'blocked-grade');
        $student->forceFill(['status' => UserStatus::Blocked])->save();

        Sanctum::actingAs($student);

        // GradePolicy::viewAny does not deny blocked students today.
        $this->getJson('/api/v1/grades')
            ->assertOk()
            ->assertJsonPath('success', true);
    }

    protected function createGradeFor(User $student, float $value, string $notes): Grade
    {
        $subject = $this->createSubject();

        return Grade::query()->create([
            'student_id' => $student->id,
            'subject_id' => $subject->id,
            'source_type' => GradeSourceType::Manual,
            'source_id' => null,
            'grade' => $value,
            'notes' => $notes,
        ]);
    }
}
