<?php

namespace Tests\Feature;

use App\Enums\AccessStatus;
use App\Enums\ContentStatus;
use App\Enums\PaymentStatus;
use App\Enums\SubjectCategory;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Enums\VideoStatus;
use App\Models\Lesson;
use App\Models\Subject;
use App\Models\SubjectStudent;
use App\Models\User;
use App\Models\Video;
use App\Services\Video\BunnyStreamVideoProvider;
use App\Services\Video\VideoStorageRepairService;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Mockery;
use Tests\TestCase;

class VideoStorageRepairTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
        Storage::fake('lesson_videos');
    }

    public function test_missing_source_video_is_marked_failed_and_has_no_playback_url(): void
    {
        [$student, $video] = $this->createEnrolledMissingSourceVideo();

        app(VideoStorageRepairService::class)->repair(dryRun: false);

        $video->refresh();
        $this->assertSame(VideoStatus::Failed, $video->status);

        Sanctum::actingAs($student);

        $response = $this->getJson('/api/v1/videos/'.$video->id)->assertOk();
        $this->assertNull($response->json('data.playback'));
        $this->assertSame('failed', $response->json('data.status'));
    }

    public function test_ready_bunny_video_playback_is_preserved_after_file_size_reconciliation(): void
    {
        Storage::disk('lesson_videos')->put('lesson-videos/ready-bunny.mp4', str_repeat('a', 2048));

        [$student, $video] = $this->createEnrolledBunnyReadyVideo(
            path: 'lesson-videos/ready-bunny.mp4',
            externalId: 'bunny-guid-ready',
            fileSize: 1,
        );

        $mock = Mockery::mock(BunnyStreamVideoProvider::class);
        $mock->shouldReceive('supports')->andReturn(true);
        $mock->shouldReceive('isConfigured')->andReturn(true);
        $mock->shouldReceive('generateSignedPlaybackUrl')->once()->andReturn([
            'url' => 'https://cdn.example.test/guid/playlist.m3u8',
            'expires_at' => now()->addMinutes(10),
            'type' => 'hls',
        ]);
        $this->app->instance(BunnyStreamVideoProvider::class, $mock);

        app(VideoStorageRepairService::class)->repair(dryRun: false);

        $video->refresh();
        $this->assertSame(2048, $video->file_size);
        $this->assertSame(VideoStatus::Ready, $video->status);

        Sanctum::actingAs($student);

        $response = $this->getJson('/api/v1/videos/'.$video->id)->assertOk();
        $this->assertSame('ready', $response->json('data.status'));
        $this->assertStringContainsString('playlist.m3u8', (string) $response->json('data.playback.url'));
    }

    public function test_repair_command_dry_run_does_not_mutate_database(): void
    {
        Storage::disk('lesson_videos')->put('lesson-videos/missing.mp4', 'x');

        $video = $this->createMissingSourceVideoRecord();

        $this->artisan('videos:repair-storage')->assertSuccessful();

        $video->refresh();
        $this->assertSame(VideoStatus::Uploading, $video->status);
    }

    /**
     * @return array{0: User, 1: Video}
     */
    protected function createEnrolledMissingSourceVideo(): array
    {
        $student = $this->createStudent();
        $lesson = $this->createLesson($this->createSubject());
        $this->enroll($student, $lesson->subject_id);

        $video = Video::query()->create([
            'lesson_id' => $lesson->id,
            'title' => 'Missing source',
            'storage_provider' => 'bunny',
            'video_url' => '',
            'video_path' => 'lesson-videos/missing-on-disk.mp4',
            'duration_seconds' => 0,
            'status' => VideoStatus::Uploading,
            'is_free' => false,
        ]);

        return [$student, $video];
    }

    /**
     * @return array{0: User, 1: Video}
     */
    protected function createEnrolledBunnyReadyVideo(string $path, string $externalId, int $fileSize): array
    {
        Config::set('video.provider', 'bunny');
        Config::set('video.bunny.playback_mode', 'cdn');
        Config::set('video.bunny.library_id', '12345');
        Config::set('video.bunny.token_key', 'token-key');
        Config::set('video.bunny.cdn_hostname', 'vz-test.b-cdn.net');

        $student = $this->createStudent();
        $lesson = $this->createLesson($this->createSubject());
        $this->enroll($student, $lesson->subject_id);

        $video = Video::query()->create([
            'lesson_id' => $lesson->id,
            'title' => 'Ready bunny',
            'storage_provider' => 'bunny',
            'video_url' => '',
            'video_path' => $path,
            'external_video_id' => $externalId,
            'file_size' => $fileSize,
            'duration_seconds' => 120,
            'status' => VideoStatus::Ready,
            'is_free' => false,
        ]);

        return [$student, $video];
    }

    protected function createMissingSourceVideoRecord(): Video
    {
        $lesson = $this->createLesson($this->createSubject());

        return Video::query()->create([
            'lesson_id' => $lesson->id,
            'title' => 'Missing source',
            'storage_provider' => 'bunny',
            'video_url' => '',
            'video_path' => 'lesson-videos/missing.mp4',
            'duration_seconds' => 0,
            'status' => VideoStatus::Uploading,
            'is_free' => false,
        ]);
    }

    protected function createSubject(): Subject
    {
        $instructor = User::factory()->create([
            'role' => UserRole::Instructor,
            'status' => UserStatus::Active,
        ]);

        return Subject::query()->create([
            'instructor_id' => $instructor->id,
            'title' => 'Subject',
            'description' => 'Desc',
            'category' => SubjectCategory::Medicine,
            'status' => ContentStatus::Active,
            'price' => 10,
        ]);
    }

    protected function createLesson(Subject $subject): Lesson
    {
        return Lesson::query()->create([
            'subject_id' => $subject->id,
            'title' => 'Lesson',
            'order' => 1,
            'status' => ContentStatus::Active,
        ]);
    }

    protected function createStudent(): User
    {
        $student = User::factory()->create([
            'role' => UserRole::Student,
            'status' => UserStatus::Active,
        ]);
        $student->assignRole('student');

        return $student;
    }

    protected function enroll(User $student, int $subjectId): void
    {
        SubjectStudent::query()->create([
            'subject_id' => $subjectId,
            'student_id' => $student->id,
            'payment_status' => PaymentStatus::Paid,
            'access_status' => AccessStatus::Active,
        ]);
    }
}
