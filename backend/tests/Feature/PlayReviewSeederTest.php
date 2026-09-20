<?php

namespace Tests\Feature;

use App\Enums\AccessStatus;
use App\Enums\ContentStatus;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Models\Assignment;
use App\Models\Lesson;
use App\Models\LessonFile;
use App\Models\Quiz;
use App\Models\QuizAnswer;
use App\Models\QuizQuestion;
use App\Models\Subject;
use App\Models\SubjectStudent;
use App\Models\User;
use App\Models\Video;
use App\Services\DeviceService;
use Database\Seeders\PlayReviewSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class PlayReviewSeederTest extends TestCase
{
    use RefreshDatabase;

    protected function tearDown(): void
    {
        putenv('PLAY_REVIEW_EMAIL');
        putenv('PLAY_REVIEW_PASSWORD');

        parent::tearDown();
    }

    public function test_seeder_creates_idempotent_review_account_and_content(): void
    {
        Storage::fake('lesson_files');

        $admin = User::factory()->create([
            'role' => UserRole::Admin,
            'status' => UserStatus::Active,
        ]);

        putenv('PLAY_REVIEW_EMAIL=google-reviewer@rshd.test');
        putenv('PLAY_REVIEW_PASSWORD=review-password-12345');

        $this->seed(PlayReviewSeeder::class);
        $this->seed(PlayReviewSeeder::class);

        $reviewer = User::query()
            ->where('email', 'google-reviewer@rshd.test')
            ->firstOrFail();

        $this->assertSame(UserRole::Student, $reviewer->role);
        $this->assertSame(UserStatus::Active, $reviewer->status);
        $this->assertNotNull($reviewer->email_verified_at);
        $this->assertTrue(Hash::check('review-password-12345', $reviewer->password));
        $this->assertTrue($reviewer->preference(DeviceService::DEVICE_BINDING_EXEMPT_PREFERENCE));

        $subject = Subject::query()
            ->where('title', PlayReviewSeeder::SUBJECT_TITLE)
            ->firstOrFail();

        $this->assertSame($admin->id, $subject->instructor_id);
        $this->assertSame(ContentStatus::Active, $subject->status);
        $this->assertSame(1, Subject::query()->where('title', PlayReviewSeeder::SUBJECT_TITLE)->count());

        $lesson = Lesson::query()
            ->where('subject_id', $subject->id)
            ->where('title', PlayReviewSeeder::LESSON_TITLE)
            ->firstOrFail();

        $this->assertSame(1, Lesson::query()->where('subject_id', $subject->id)->count());
        $this->assertSame(1, Video::query()->where('lesson_id', $lesson->id)->count());
        $this->assertSame(1, LessonFile::query()->where('lesson_id', $lesson->id)->count());
        $this->assertSame(1, Assignment::query()->where('subject_id', $subject->id)->count());
        $this->assertSame(1, Quiz::query()->where('subject_id', $subject->id)->count());
        $this->assertSame(1, QuizQuestion::query()->whereHas('quiz', fn ($query) => $query->where('subject_id', $subject->id))->count());
        $this->assertSame(2, QuizAnswer::query()->whereHas('question.quiz', fn ($query) => $query->where('subject_id', $subject->id))->count());

        $enrollment = SubjectStudent::query()
            ->where('subject_id', $subject->id)
            ->where('student_id', $reviewer->id)
            ->firstOrFail();

        $this->assertSame(AccessStatus::Active, $enrollment->access_status);
        $this->assertSame($admin->id, $enrollment->activated_by);
        Storage::disk('lesson_files')->assertExists(PlayReviewSeeder::REVIEW_FILE_PATH);
    }

    public function test_seeder_fails_before_marking_review_file_ready_when_storage_write_fails(): void
    {
        User::factory()->create([
            'role' => UserRole::Admin,
            'status' => UserStatus::Active,
        ]);

        putenv('PLAY_REVIEW_EMAIL=google-reviewer@rshd.test');
        putenv('PLAY_REVIEW_PASSWORD=review-password-12345');

        $disk = \Mockery::mock();
        $disk->shouldReceive('put')
            ->once()
            ->with(PlayReviewSeeder::REVIEW_FILE_PATH, \Mockery::type('string'))
            ->andReturn(false);

        Storage::shouldReceive('disk')
            ->once()
            ->with('lesson_files')
            ->andReturn($disk);

        try {
            $this->seed(PlayReviewSeeder::class);
            $this->fail('Seeder should fail when the review PDF cannot be written.');
        } catch (\RuntimeException $exception) {
            $this->assertSame(
                'Failed to write Google Play review PDF.',
                $exception->getMessage(),
            );
        }

        $this->assertSame(
            0,
            LessonFile::query()
                ->where('file_path', PlayReviewSeeder::REVIEW_FILE_PATH)
                ->count(),
        );
    }

    public function test_seeder_refuses_to_take_over_existing_non_review_account(): void
    {
        User::factory()->create([
            'role' => UserRole::Admin,
            'status' => UserStatus::Active,
        ]);

        $existing = User::factory()->create([
            'email' => 'google-reviewer@rshd.test',
            'role' => UserRole::Student,
            'status' => UserStatus::Active,
            'password' => Hash::make('existing-password-12345'),
            'preferences' => ['theme' => 'dark'],
        ]);

        putenv('PLAY_REVIEW_EMAIL=google-reviewer@rshd.test');
        putenv('PLAY_REVIEW_PASSWORD=review-password-12345');

        try {
            $this->seed(PlayReviewSeeder::class);
            $this->fail('Seeder should refuse to take over an existing non-review account.');
        } catch (\RuntimeException $exception) {
            $this->assertSame(
                'PLAY_REVIEW_EMAIL already belongs to a non-review account.',
                $exception->getMessage(),
            );
        }

        $existing->refresh();

        $this->assertTrue(Hash::check('existing-password-12345', $existing->password));
        $this->assertSame(['theme' => 'dark'], $existing->preferences);
        $this->assertFalse(
            $existing->preference(DeviceService::DEVICE_BINDING_EXEMPT_PREFERENCE, false) === true,
        );
        $this->assertSame(
            0,
            Subject::query()->where('title', PlayReviewSeeder::SUBJECT_TITLE)->count(),
        );
    }

    public function test_seeder_requires_credentials_from_environment(): void
    {
        User::factory()->create([
            'role' => UserRole::Admin,
            'status' => UserStatus::Active,
        ]);

        putenv('PLAY_REVIEW_EMAIL');
        putenv('PLAY_REVIEW_PASSWORD');

        $this->expectException(\RuntimeException::class);
        $this->seed(PlayReviewSeeder::class);
    }
}
