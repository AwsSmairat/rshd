<?php

namespace Tests\Feature\Security\Authorization;


use PHPUnit\Framework\Attributes\Group;
use App\Models\QuizAttempt;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Feature\Security\Concerns\CreatesEnrollmentScenario;
use Tests\TestCase;

#[Group('security')]
class QuizStartAuthorizationTest extends TestCase
{
    use CreatesEnrollmentScenario;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
    }

    public function test_anonymous_user_cannot_start_quiz(): void
    {
        [, $quiz] = $this->createEnrolledQuizScenario();

        $this->postJson('/api/v1/quizzes/'.$quiz->id.'/start')
            ->assertUnauthorized();
    }

    public function test_double_start_reuses_active_attempt_without_creating_unauthorized_attempt(): void
    {
        [$student, $quiz] = $this->createEnrolledQuizScenario();

        Sanctum::actingAs($student);

        $first = $this->postJson('/api/v1/quizzes/'.$quiz->id.'/start')
            ->assertOk()
            ->assertJsonPath('success', true);

        $second = $this->postJson('/api/v1/quizzes/'.$quiz->id.'/start')
            ->assertOk()
            ->assertJsonPath('success', true);

        $attemptId = $first->json('data.attempt_id');
        $this->assertSame($attemptId, $second->json('data.attempt_id'));

        $this->assertSame(
            1,
            QuizAttempt::query()
                ->where('quiz_id', $quiz->id)
                ->where('student_id', $student->id)
                ->whereNull('submitted_at')
                ->count(),
        );
    }
}
