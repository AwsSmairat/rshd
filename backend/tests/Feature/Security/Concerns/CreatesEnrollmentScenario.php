<?php

namespace Tests\Feature\Security\Concerns;

use App\Enums\AccessStatus;
use App\Enums\ContentStatus;
use App\Enums\FileType;
use App\Enums\LessonFileStorageStatus;
use App\Enums\PaymentStatus;
use App\Enums\QuestionType;
use App\Enums\SubjectCategory;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Models\Lesson;
use App\Models\LessonFile;
use App\Models\Quiz;
use App\Models\QuizAnswer;
use App\Models\QuizQuestion;
use App\Models\Subject;
use App\Models\SubjectStudent;
use App\Models\User;
use Illuminate\Support\Carbon;

trait CreatesEnrollmentScenario
{
    /**
     * @return array{0: User, 1: LessonFile}
     */
    protected function createEnrolledLessonFileScenario(?Carbon $expiresAt = null): array
    {
        $student = $this->createStudent();
        $subject = $this->createSubject();
        $lesson = $this->createLesson($subject);

        SubjectStudent::query()->create([
            'subject_id' => $subject->id,
            'student_id' => $student->id,
            'payment_status' => PaymentStatus::Paid,
            'access_status' => AccessStatus::Active,
            'activated_at' => now()->subDay(),
            'expires_at' => $expiresAt,
        ]);

        $file = $this->createBunnyLessonFile($lesson);

        return [$student, $file];
    }

    /**
     * @return array{0: User, 1: Quiz, 2: QuizQuestion, 3: QuizAnswer}
     */
    protected function createEnrolledQuizScenario(?Carbon $expiresAt = null): array
    {
        $student = $this->createStudent();
        $subject = $this->createSubject();
        $lesson = $this->createLesson($subject);

        SubjectStudent::query()->create([
            'subject_id' => $subject->id,
            'student_id' => $student->id,
            'payment_status' => PaymentStatus::Paid,
            'access_status' => AccessStatus::Active,
            'activated_at' => now()->subDay(),
            'expires_at' => $expiresAt,
        ]);

        $quiz = Quiz::query()->create([
            'subject_id' => $subject->id,
            'lesson_id' => $lesson->id,
            'title' => 'اختبار تجريبي',
            'description' => 'وصف',
            'duration_minutes' => 30,
            'status' => ContentStatus::Active,
        ]);

        $question = QuizQuestion::query()->create([
            'quiz_id' => $quiz->id,
            'question_text' => 'سؤال تجريبي؟',
            'question_type' => QuestionType::Mcq,
            'points' => 10,
        ]);

        $correctAnswer = QuizAnswer::query()->create([
            'question_id' => $question->id,
            'answer_text' => 'الإجابة الصحيحة',
            'is_correct' => true,
        ]);

        QuizAnswer::query()->create([
            'question_id' => $question->id,
            'answer_text' => 'إجابة خاطئة',
            'is_correct' => false,
        ]);

        return [$student, $quiz, $question, $correctAnswer];
    }

    protected function createBunnyLessonFile(Lesson $lesson): LessonFile
    {
        return LessonFile::query()->create([
            'lesson_id' => $lesson->id,
            'title' => 'ملف PDF تجريبي',
            'file_type' => FileType::Pdf,
            'file_url' => '',
            'file_path' => 'lesson-files/local-pilot.pdf',
            'original_file_name' => 'pilot.pdf',
            'file_size' => 60_271,
            'file_mime_type' => 'application/pdf',
            'storage_provider' => 'bunny',
            'storage_disk' => 'test-zone',
            'external_path' => 'lesson-files/'.$lesson->id.'/pilot.pdf',
            'storage_status' => LessonFileStorageStatus::Ready,
            'uploaded_at' => now(),
        ]);
    }

    protected function createSubject(?User $instructor = null): Subject
    {
        $instructor ??= User::factory()->create([
            'role' => UserRole::Instructor,
            'status' => UserStatus::Active,
            'email_verified_at' => now(),
        ]);

        return Subject::query()->create([
            'instructor_id' => $instructor->id,
            'title' => 'مادة تجريبية',
            'description' => 'وصف',
            'category' => SubjectCategory::General->value,
            'status' => ContentStatus::Active,
            'price' => 10,
        ]);
    }

    protected function createLesson(Subject $subject): Lesson
    {
        return Lesson::query()->create([
            'subject_id' => $subject->id,
            'title' => 'درس تجريبي',
            'description' => 'وصف',
            'status' => ContentStatus::Active,
        ]);
    }

    /**
     * @param  array<string, mixed>  $overrides
     */
    protected function createStudent(array $overrides = []): User
    {
        return User::factory()->create(array_merge([
            'role' => UserRole::Student,
            'status' => UserStatus::Active,
            'email_verified_at' => now(),
        ], $overrides));
    }
}
