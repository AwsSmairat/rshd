<?php

namespace Tests\Feature\Filament;

use App\Enums\ContentStatus;
use App\Enums\QuestionType;
use App\Enums\SubjectCategory;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Filament\Resources\QuizResource\Pages\CreateQuiz;
use App\Models\Quiz;
use App\Models\Subject;
use App\Models\User;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Livewire\Livewire;
use Tests\TestCase;

class CreateQuizWithQuestionsTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
    }

    public function test_create_quiz_form_includes_questions_and_answer_options(): void
    {
        $admin = $this->createAdmin();
        $this->actingAs($admin);

        $this->get('/admin/quizzes/create')
            ->assertOk()
            ->assertSee('الأسئلة')
            ->assertSee('نص السؤال')
            ->assertSee('الخيارات')
            ->assertSee('إضافة سؤال');
    }

    public function test_creating_a_quiz_persists_nested_questions_and_correct_answer(): void
    {
        $admin = $this->createAdmin();
        $subject = Subject::query()->create([
            'instructor_id' => $admin->id,
            'title' => 'الرياضيات',
            'description' => 'وصف',
            'category' => SubjectCategory::General->value,
            'status' => ContentStatus::Active,
            'price' => 1,
        ]);

        $this->actingAs($admin);

        Livewire::test(CreateQuiz::class)
            ->fillForm([
                'subject_id' => $subject->id,
                'title' => 'اختبار الوحدة الأولى',
                'description' => 'وصف الاختبار',
                'duration_minutes' => 15,
                'status' => ContentStatus::Active->value,
                'questions' => [
                    [
                        'question_text' => 'عاصمة الأردن؟',
                        'question_type' => QuestionType::Mcq->value,
                        'points' => 2,
                        'answers' => [
                            ['answer_text' => 'عمّان', 'is_correct' => true],
                            ['answer_text' => 'إربد', 'is_correct' => false],
                            ['answer_text' => 'الزرقاء', 'is_correct' => false],
                        ],
                    ],
                ],
            ])
            ->call('create')
            ->assertHasNoFormErrors();

        $quiz = Quiz::query()->where('title', 'اختبار الوحدة الأولى')->first();
        $this->assertNotNull($quiz);
        $this->assertSame(1, $quiz->questions()->count());

        $question = $quiz->questions()->first();
        $this->assertSame('عاصمة الأردن؟', $question->question_text);
        $this->assertSame(2, $question->points);
        $this->assertSame(3, $question->answers()->count());
        $this->assertSame('عمّان', $question->answers()->where('is_correct', true)->value('answer_text'));
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
