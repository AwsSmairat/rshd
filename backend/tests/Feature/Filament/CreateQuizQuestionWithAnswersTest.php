<?php

namespace Tests\Feature\Filament;

use App\Enums\ContentStatus;
use App\Enums\QuestionType;
use App\Enums\SubjectCategory;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Filament\Resources\QuizQuestionResource\Pages\CreateQuizQuestion;
use App\Models\Quiz;
use App\Models\QuizQuestion;
use App\Models\Subject;
use App\Models\User;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Livewire\Livewire;
use Tests\TestCase;

class CreateQuizQuestionWithAnswersTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
    }

    public function test_create_question_form_matches_quiz_answer_editor(): void
    {
        $admin = $this->createAdmin();
        $this->actingAs($admin);

        $this->get('/admin/quiz-questions/create')
            ->assertOk()
            ->assertSee('الاختبار')
            ->assertSee('تفاصيل السؤال')
            ->assertSee('نص السؤال')
            ->assertSee('الخيارات')
            ->assertSee('إضافة خيار');
    }

    public function test_creating_a_question_persists_options_and_correct_answer(): void
    {
        $admin = $this->createAdmin();
        $subject = Subject::query()->create([
            'instructor_id' => $admin->id,
            'title' => 'العلوم',
            'description' => 'وصف',
            'category' => SubjectCategory::General->value,
            'status' => ContentStatus::Active,
            'price' => 1,
        ]);
        $quiz = Quiz::query()->create([
            'subject_id' => $subject->id,
            'title' => 'اختبار العلوم',
            'description' => 'وصف',
            'duration_minutes' => 10,
            'status' => ContentStatus::Active,
        ]);

        $this->actingAs($admin);

        Livewire::test(CreateQuizQuestion::class)
            ->fillForm([
                'quiz_id' => $quiz->id,
                'question_text' => 'ما حالة الماء عند الغليان؟',
                'question_type' => QuestionType::Mcq->value,
                'points' => 3,
                'answers' => [
                    ['answer_text' => 'سائل', 'is_correct' => false],
                    ['answer_text' => 'غاز', 'is_correct' => true],
                    ['answer_text' => 'صلب', 'is_correct' => false],
                ],
            ])
            ->call('create')
            ->assertHasNoFormErrors();

        $question = QuizQuestion::query()->where('question_text', 'ما حالة الماء عند الغليان؟')->first();
        $this->assertNotNull($question);
        $this->assertSame($quiz->id, $question->quiz_id);
        $this->assertSame(3, $question->points);
        $this->assertSame(3, $question->answers()->count());
        $this->assertSame('غاز', $question->answers()->where('is_correct', true)->value('answer_text'));
        $this->assertSame(1, $question->answers()->where('is_correct', true)->count());
    }

    private function createAdmin(): User
    {
        $admin = User::factory()->create([
            'role' => UserRole::Admin,
            'status' => UserStatus::Active,
            'email_verified_at' => now(),
            'password_set_at' => now(),
        ]);
        $admin->assignRole(UserRole::Admin->value);

        return $admin;
    }
}
