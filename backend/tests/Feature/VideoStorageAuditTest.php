<?php

namespace Tests\Feature;

use App\Enums\ContentStatus;
use App\Enums\SubjectCategory;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Enums\VideoStatus;
use App\Models\Lesson;
use App\Models\Subject;
use App\Models\User;
use App\Models\Video;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class VideoStorageAuditTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
        Storage::fake('lesson_videos');
    }

    public function test_audit_storage_command_is_read_only_and_reports_inventory(): void
    {
        Storage::disk('lesson_videos')->put('lesson-videos/local-one.mp4', 'video-bytes');

        $instructor = User::factory()->create([
            'role' => UserRole::Instructor,
            'status' => UserStatus::Active,
        ]);

        $subject = Subject::query()->create([
            'instructor_id' => $instructor->id,
            'title' => 'Audit subject',
            'description' => 'Test',
            'category' => SubjectCategory::Medicine,
            'status' => ContentStatus::Active,
            'price' => 10,
        ]);

        $lesson = Lesson::query()->create([
            'subject_id' => $subject->id,
            'title' => 'Lesson',
            'order' => 1,
            'status' => \App\Enums\ContentStatus::Active,
        ]);

        $localVideo = Video::query()->create([
            'lesson_id' => $lesson->id,
            'title' => 'Local pending',
            'storage_provider' => 'local',
            'video_url' => '',
            'video_path' => 'lesson-videos/local-one.mp4',
            'duration_seconds' => 0,
            'status' => VideoStatus::Ready,
            'is_free' => false,
        ]);

        Video::query()->create([
            'lesson_id' => $lesson->id,
            'title' => 'Missing source',
            'storage_provider' => 'bunny',
            'video_url' => '',
            'video_path' => 'lesson-videos/missing.mp4',
            'duration_seconds' => 0,
            'status' => VideoStatus::Uploading,
            'is_free' => false,
        ]);

        Storage::disk('lesson_videos')->put('lesson-videos/orphan.mp4', 'orphan');

        Http::fake();

        $this->artisan('videos:audit-storage', ['--skip-bunny' => true])
            ->assertSuccessful()
            ->expectsOutputToContain('Video storage audit (read-only)');

        $localVideo->refresh();
        $this->assertSame('local', $localVideo->storage_provider);
        $this->assertTrue(Storage::disk('lesson_videos')->exists('lesson-videos/local-one.mp4'));
        $this->assertTrue(Storage::disk('lesson_videos')->exists('lesson-videos/orphan.mp4'));
    }
}
