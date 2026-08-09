<?php

namespace Tests\Feature\Security;

use App\Enums\AccessStatus;
use App\Enums\ContentStatus;
use App\Enums\PaymentStatus;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Enums\VideoStatus;
use App\Models\Lesson;
use App\Models\Subject;
use App\Models\SubjectStudent;
use App\Models\User;
use App\Models\Video;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\RateLimiter;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * @group security
 */
class VideoProgressAbuseTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
        RateLimiter::clear('video-progress');
    }

    public function test_negative_progress_values_are_rejected(): void
    {
        [$student, $video] = $this->createScenario();

        Sanctum::actingAs($student);

        $this->postJson('/api/v1/videos/'.$video->id.'/progress', [
            'watched_seconds' => -1,
            'current_position' => -5,
        ])->assertStatus(422);
    }

    public function test_over_duration_progress_is_rejected(): void
    {
        [$student, $video] = $this->createScenario(durationSeconds: 120);

        Sanctum::actingAs($student);

        $this->postJson('/api/v1/videos/'.$video->id.'/progress', [
            'watched_seconds' => 9999,
            'current_position' => 9999,
        ])->assertStatus(422);
    }

    public function test_foreign_student_cannot_update_progress(): void
    {
        [, $video] = $this->createScenario();
        $foreign = $this->createStudent(['email' => 'foreign-progress@rshd.test']);

        Sanctum::actingAs($foreign);

        $this->postJson('/api/v1/videos/'.$video->id.'/progress', [
            'watched_seconds' => 10,
            'current_position' => 10,
        ])->assertForbidden();
    }

    public function test_progress_flooding_is_throttled(): void
    {
        [$student, $video] = $this->createScenario();

        Sanctum::actingAs($student);

        for ($i = 0; $i < 120; $i++) {
            $this->postJson('/api/v1/videos/'.$video->id.'/progress', [
                'watched_seconds' => min($i, 100),
                'current_position' => min($i, 100),
            ]);
        }

        $this->postJson('/api/v1/videos/'.$video->id.'/progress', [
            'watched_seconds' => 100,
            'current_position' => 100,
        ])->assertStatus(429);
    }

    /**
     * @return array{0: User, 1: Video}
     */
    protected function createScenario(int $durationSeconds = 600): array
    {
        $student = $this->createStudent();
        $instructor = User::factory()->create([
            'role' => UserRole::Instructor,
            'status' => UserStatus::Active,
        ]);
        $subject = Subject::query()->create([
            'instructor_id' => $instructor->id,
            'title' => 'مادة',
            'description' => 'وصف',
            'category' => 'general',
            'status' => ContentStatus::Active,
            'price' => 10,
        ]);
        $lesson = Lesson::query()->create([
            'subject_id' => $subject->id,
            'title' => 'درس',
            'description' => 'وصف',
            'status' => ContentStatus::Active,
        ]);

        SubjectStudent::query()->create([
            'subject_id' => $subject->id,
            'student_id' => $student->id,
            'payment_status' => PaymentStatus::Paid,
            'access_status' => AccessStatus::Active,
        ]);

        $video = Video::query()->create([
            'lesson_id' => $lesson->id,
            'title' => 'فيديو',
            'storage_provider' => 'local',
            'video_url' => '',
            'video_path' => 'videos/test.mp4',
            'duration_seconds' => $durationSeconds,
            'status' => VideoStatus::Ready,
            'is_free' => false,
        ]);

        return [$student, $video];
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
