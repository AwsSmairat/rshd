<?php

namespace Tests\Feature\Security\Authorization;

use App\Enums\ContentStatus;
use App\Models\Quiz;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Feature\Security\Concerns\CreatesEnrollmentScenario;
use Tests\TestCase;

/**
 * @group security
 */
class QuizSubmitAuthorizationTest extends TestCase
{
    use CreatesEnrollmentScenario;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
    }

    public function test_enrolled_student_can_submit_quiz(): void
    {
        [$student, $quiz, $question, $correctAnswer] = $this->createEnrolledQuizScenario();

        Sanctum::actingAs($student);

        $this->postJson('/api/v1/quizzes/'.$quiz->id.'/start')
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->postJson('/api/v1/quizzes/'.$quiz->id.'/submit', [
            'answers' => [
                [
                    'question_id' => $question->id,
                    'answer_id' => $correctAnswer->id,
                ],
            ],
        ])
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => ['score', 'submitted_at'],
            ]);
    }

    public function test_non_enrolled_student_is_blocked_from_submit(): void
    {
        [, $quiz, $question, $correctAnswer] = $this->createEnrolledQuizScenario();
        $foreignStudent = $this->createStudent(['email' => 'foreign-quiz@rshd.test']);

        Sanctum::actingAs($foreignStudent);

        $this->postJson('/api/v1/quizzes/'.$quiz->id.'/start')
            ->assertForbidden();

        $this->postJson('/api/v1/quizzes/'.$quiz->id.'/submit', [
            'answers' => [
                [
                    'question_id' => $question->id,
                    'answer_id' => $correctAnswer->id,
                ],
            ],
        ])->assertForbidden();
    }

    public function test_expired_enrollment_is_blocked_from_submit(): void
    {
        [$student, $quiz, $question, $correctAnswer] = $this->createEnrolledQuizScenario(
            expiresAt: now()->subDay(),
        );

        Sanctum::actingAs($student);

        $this->postJson('/api/v1/quizzes/'.$quiz->id.'/start')
            ->assertForbidden();

        $this->postJson('/api/v1/quizzes/'.$quiz->id.'/submit', [
            'answers' => [
                [
                    'question_id' => $question->id,
                    'answer_id' => $correctAnswer->id,
                ],
            ],
        ])->assertForbidden();
    }

    public function test_foreign_quiz_is_blocked_for_enrolled_student(): void
    {
        [$student] = $this->createEnrolledQuizScenario();
        $otherSubject = $this->createSubject();
        $otherLesson = $this->createLesson($otherSubject);
        $foreignQuiz = Quiz::query()->create([
            'subject_id' => $otherSubject->id,
            'lesson_id' => $otherLesson->id,
            'title' => 'اختبار خارجي',
            'description' => 'وصف',
            'duration_minutes' => 15,
            'status' => ContentStatus::Active,
        ]);

        Sanctum::actingAs($student);

        $this->postJson('/api/v1/quizzes/'.$foreignQuiz->id.'/start')
            ->assertForbidden();
    }

    public function test_foreign_quiz_question_does_not_inflate_score(): void
    {
        [$student, $quiz, $question] = $this->createEnrolledQuizScenario();
        [, $foreignQuiz, $foreignQuestion, $foreignCorrect] = $this->createEnrolledQuizScenario();

        $foreignQuiz->forceFill([
            'subject_id' => $quiz->subject_id,
            'lesson_id' => $quiz->lesson_id,
        ])->save();
        $foreignQuestion->forceFill(['quiz_id' => $foreignQuiz->id, 'points' => 100])->save();

        Sanctum::actingAs($student);

        $this->postJson('/api/v1/quizzes/'.$quiz->id.'/start')->assertOk();

        $response = $this->postJson('/api/v1/quizzes/'.$quiz->id.'/submit', [
            'answers' => [
                [
                    'question_id' => $question->id,
                    'answer_id' => null,
                ],
                [
                    'question_id' => $foreignQuestion->id,
                    'answer_id' => $foreignCorrect->id,
                ],
            ],
        ])->assertOk();

        $this->assertEquals(0.0, (float) $response->json('data.score'));
    }
}
