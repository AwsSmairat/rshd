<?php

namespace Tests\Feature\Security\Authorization;

use App\Enums\ContentStatus;
use App\Models\QuizAnswer;
use App\Models\QuizAttempt;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use PHPUnit\Framework\Attributes\Group;
use Tests\Feature\Security\Concerns\CreatesEnrollmentScenario;
use Tests\TestCase;

/**
 * A quiz is answered once per question, only while it is published, and only
 * within its time limit.
 */
#[Group('security')]
class QuizAnswerStuffingTest extends TestCase
{
    use CreatesEnrollmentScenario;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
    }

    public function test_sending_every_option_for_a_question_is_refused(): void
    {
        [$student, $quiz, $question] = $this->createEnrolledQuizScenario();
        Sanctum::actingAs($student);
        $this->postJson('/api/v1/quizzes/'.$quiz->id.'/start')->assertOk();

        $everyOption = QuizAnswer::query()
            ->where('question_id', $question->id)
            ->pluck('id')
            ->map(fn (int $id) => ['question_id' => $question->id, 'answer_id' => $id])
            ->all();

        $this->postJson('/api/v1/quizzes/'.$quiz->id.'/submit', ['answers' => $everyOption])
            ->assertUnprocessable();

        $this->assertDatabaseMissing('grades', ['student_id' => $student->id]);
    }

    public function test_repeating_the_right_answer_is_refused(): void
    {
        [$student, $quiz, $question, $correctAnswer] = $this->createEnrolledQuizScenario();
        Sanctum::actingAs($student);
        $this->postJson('/api/v1/quizzes/'.$quiz->id.'/start')->assertOk();

        $this->postJson('/api/v1/quizzes/'.$quiz->id.'/submit', [
            'answers' => array_fill(0, 3, [
                'question_id' => $question->id,
                'answer_id' => $correctAnswer->id,
            ]),
        ])->assertUnprocessable();
    }

    public function test_one_right_answer_scores_full_marks(): void
    {
        [$student, $quiz, $question, $correctAnswer] = $this->createEnrolledQuizScenario();
        Sanctum::actingAs($student);
        $this->postJson('/api/v1/quizzes/'.$quiz->id.'/start')->assertOk();

        $this->postJson('/api/v1/quizzes/'.$quiz->id.'/submit', [
            'answers' => [['question_id' => $question->id, 'answer_id' => $correctAnswer->id]],
        ])
            ->assertOk()
            ->assertJsonPath('data.score', '100.00');
    }

    public function test_an_unpublished_quiz_cannot_be_taken(): void
    {
        [$student, $quiz] = $this->createEnrolledQuizScenario();
        $quiz->update(['status' => ContentStatus::Inactive]);
        Sanctum::actingAs($student);

        $this->postJson('/api/v1/quizzes/'.$quiz->id.'/start')->assertForbidden();
    }

    public function test_answers_after_the_time_limit_are_not_counted(): void
    {
        [$student, $quiz, $question, $correctAnswer] = $this->createEnrolledQuizScenario();
        $quiz->update(['duration_minutes' => 10]);
        Sanctum::actingAs($student);
        $this->postJson('/api/v1/quizzes/'.$quiz->id.'/start')->assertOk();

        $this->travel(13)->minutes();

        $this->postJson('/api/v1/quizzes/'.$quiz->id.'/submit', [
            'answers' => [['question_id' => $question->id, 'answer_id' => $correctAnswer->id]],
        ])->assertUnprocessable();

        $attempt = QuizAttempt::query()->where('student_id', $student->id)->firstOrFail();
        $this->assertNotNull($attempt->submitted_at);
        $this->assertEquals(0, (float) $attempt->score);
    }

    public function test_answers_inside_the_grace_period_still_count(): void
    {
        [$student, $quiz, $question, $correctAnswer] = $this->createEnrolledQuizScenario();
        $quiz->update(['duration_minutes' => 10]);
        Sanctum::actingAs($student);
        $this->postJson('/api/v1/quizzes/'.$quiz->id.'/start')->assertOk();

        $this->travel(11)->minutes();

        $this->postJson('/api/v1/quizzes/'.$quiz->id.'/submit', [
            'answers' => [['question_id' => $question->id, 'answer_id' => $correctAnswer->id]],
        ])
            ->assertOk()
            ->assertJsonPath('data.score', '100.00');
    }
}
