<?php

namespace Database\Seeders;

use App\Enums\AccessStatus;
use App\Enums\ContentStatus;
use App\Enums\FileType;
use App\Enums\GradeSourceType;
use App\Enums\LessonFileStorageStatus;
use App\Enums\PaymentStatus;
use App\Enums\QuestionType;
use App\Enums\SubjectCategory;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Enums\VideoStatus;
use App\Models\AppNotification;
use App\Models\Assignment;
use App\Models\Grade;
use App\Models\Lesson;
use App\Models\LessonFile;
use App\Models\Quiz;
use App\Models\QuizAnswer;
use App\Models\QuizQuestion;
use App\Models\Subject;
use App\Models\SubjectStudent;
use App\Models\User;
use App\Models\Video;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Hash;

/**
 * Staging-only validation dataset — fake users, no production data.
 *
 * Run on a clean staging DB:
 *   php artisan migrate --force
 *   php artisan db:seed --class=StagingDataSeeder --force
 *
 * Passwords: set STAGING_SEED_PASSWORD in server env (never commit real values).
 */
class StagingDataSeeder extends Seeder
{
    public function run(): void
    {
        $password = (string) env('STAGING_SEED_PASSWORD', 'change-me-on-staging-server');

        $this->call(RolePermissionSeeder::class);

        $admin = $this->seedUser(
            email: 'admin@staging.rshd.test',
            name: 'Staging Admin',
            role: UserRole::Admin,
            password: $password,
        );

        $instructor = $this->seedUser(
            email: 'instructor@staging.rshd.test',
            name: 'Staging Instructor',
            role: UserRole::Instructor,
            password: $password,
        );

        $instructorOther = $this->seedUser(
            email: 'instructor-other@staging.rshd.test',
            name: 'Other Instructor',
            role: UserRole::Instructor,
            password: $password,
        );

        $studentActive = $this->seedUser(
            email: 'student-active@staging.rshd.test',
            name: 'Active Student',
            role: UserRole::Student,
            password: $password,
        );

        $studentPending = $this->seedUser(
            email: 'student-pending@staging.rshd.test',
            name: 'Pending Student',
            role: UserRole::Student,
            password: $password,
        );

        $studentExpired = $this->seedUser(
            email: 'student-expired@staging.rshd.test',
            name: 'Expired Student',
            role: UserRole::Student,
            password: $password,
        );

        $studentBlocked = $this->seedUser(
            email: 'student-blocked@staging.rshd.test',
            name: 'Blocked Student',
            role: UserRole::Student,
            password: $password,
            status: UserStatus::Blocked,
        );

        $studentGuest = $this->seedUser(
            email: 'student-guest@staging.rshd.test',
            name: 'Non-enrolled Student',
            role: UserRole::Student,
            password: $password,
        );

        $subject = Subject::updateOrCreate(
            [
                'instructor_id' => $instructor->id,
                'title' => 'Staging Validation Course',
            ],
            [
                'description' => 'Primary staging course for E2E validation (Bunny upload via Filament).',
                'category' => SubjectCategory::It,
                'status' => ContentStatus::Active,
                'price' => 25,
            ]
        );

        $otherSubject = Subject::updateOrCreate(
            [
                'instructor_id' => $instructorOther->id,
                'title' => 'Other Instructor Scope Course',
            ],
            [
                'description' => 'Used to verify Filament/API instructor scope isolation.',
                'category' => SubjectCategory::Medicine,
                'status' => ContentStatus::Active,
                'price' => 30,
            ]
        );

        $lesson = Lesson::updateOrCreate(
            ['subject_id' => $subject->id, 'title' => 'Staging Lesson 1'],
            ['order' => 1, 'status' => ContentStatus::Active]
        );

        Lesson::updateOrCreate(
            ['subject_id' => $otherSubject->id, 'title' => 'Scoped Lesson'],
            ['order' => 1, 'status' => ContentStatus::Active]
        );

        Video::updateOrCreate(
            ['lesson_id' => $lesson->id, 'title' => 'Staging Bunny Video'],
            [
                'storage_provider' => 'bunny',
                'video_url' => '',
                'status' => VideoStatus::Uploading,
                'duration_seconds' => 0,
            ]
        );

        LessonFile::updateOrCreate(
            ['lesson_id' => $lesson->id, 'title' => 'Staging Bunny PDF'],
            [
                'file_type' => FileType::Pdf,
                'file_url' => '',
                'storage_provider' => 'bunny',
                'storage_status' => LessonFileStorageStatus::Pending,
                'file_size' => 0,
            ]
        );

        $assignment = Assignment::updateOrCreate(
            ['subject_id' => $subject->id, 'title' => 'Staging Assignment'],
            [
                'lesson_id' => $lesson->id,
                'description' => 'Submit a short answer for staging validation.',
                'due_date' => now()->addDays(14),
                'status' => ContentStatus::Active,
            ]
        );

        $quiz = Quiz::updateOrCreate(
            ['subject_id' => $subject->id, 'title' => 'Staging Quiz'],
            [
                'lesson_id' => $lesson->id,
                'description' => 'Single-question staging quiz.',
                'duration_minutes' => 10,
                'status' => ContentStatus::Active,
            ]
        );

        $question = QuizQuestion::updateOrCreate(
            ['quiz_id' => $quiz->id, 'question_text' => 'Staging validation question?'],
            ['question_type' => QuestionType::TrueFalse, 'points' => 1]
        );

        QuizAnswer::updateOrCreate(
            ['question_id' => $question->id, 'answer_text' => 'صح'],
            ['is_correct' => true]
        );
        QuizAnswer::updateOrCreate(
            ['question_id' => $question->id, 'answer_text' => 'خطأ'],
            ['is_correct' => false]
        );

        $this->enroll($subject, $studentActive, $admin, AccessStatus::Active, PaymentStatus::Paid, now()->addMonths(6));
        $this->enroll($subject, $studentPending, $admin, AccessStatus::Pending, PaymentStatus::Unpaid);
        $this->enroll($subject, $studentExpired, $admin, AccessStatus::Expired, PaymentStatus::Paid, now()->subDay());
        $this->enroll($subject, $studentBlocked, $admin, AccessStatus::Active, PaymentStatus::Paid, now()->addMonths(3));

        Grade::updateOrCreate(
            [
                'student_id' => $studentActive->id,
                'subject_id' => $subject->id,
                'source_type' => GradeSourceType::Manual,
                'source_id' => null,
                'notes' => 'Staging manual grade',
            ],
            ['grade' => 88.0]
        );

        AppNotification::updateOrCreate(
            [
                'user_id' => $studentActive->id,
                'type' => 'custom',
                'title' => 'Staging notification',
            ],
            [
                'body' => 'Welcome to the RSHD staging environment.',
                'is_read' => false,
            ]
        );

        unset($assignment, $quiz, $studentGuest, $otherSubject);
    }

    protected function seedUser(
        string $email,
        string $name,
        UserRole $role,
        string $password,
        UserStatus $status = UserStatus::Active,
    ): User {
        $user = User::updateOrCreate(
            ['email' => $email],
            [
                'name' => $name,
                'password' => Hash::make($password),
                'role' => $role,
                'status' => $status,
                'password_set_at' => now(),
                'email_verified_at' => $status === UserStatus::Active ? now() : null,
            ]
        );
        $user->syncRoles([$role->value]);

        return $user;
    }

    protected function enroll(
        Subject $subject,
        User $student,
        User $admin,
        AccessStatus $access,
        PaymentStatus $payment,
        ?Carbon $expiresAt = null,
    ): void {
        SubjectStudent::updateOrCreate(
            [
                'subject_id' => $subject->id,
                'student_id' => $student->id,
            ],
            [
                'activated_by' => $admin->id,
                'payment_status' => $payment,
                'access_status' => $access,
                'activated_at' => now()->subDays(7),
                'expires_at' => $expiresAt,
            ]
        );
    }
}
