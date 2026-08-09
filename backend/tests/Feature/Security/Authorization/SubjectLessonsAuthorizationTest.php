<?php

namespace Tests\Feature\Security\Authorization;

use App\Enums\VideoStatus;
use App\Models\Video;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Feature\Security\Concerns\CreatesEnrollmentScenario;
use Tests\TestCase;

/**
 * @group security
 */
class SubjectLessonsAuthorizationTest extends TestCase
{
    use CreatesEnrollmentScenario;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
    }

    public function test_enrolled_student_sees_lessons_for_their_subject(): void
    {
        [$student, $file] = $this->createEnrolledLessonFileScenario();
        $subject = $file->lesson->subject;
        $this->attachVideoToLesson($file->lesson);

        Sanctum::actingAs($student);

        $response = $this->getJson('/api/v1/subjects/'.$subject->id.'/lessons')
            ->assertOk()
            ->assertJsonPath('success', true);

        $lessons = collect($response->json('data'));
        $this->assertTrue($lessons->pluck('id')->contains($file->lesson_id));
    }

    public function test_non_enrolled_student_gets_preview_only_with_locked_protected_content(): void
    {
        [$enrolledStudent, $file] = $this->createEnrolledLessonFileScenario();
        $subject = $file->lesson->subject;
        $this->attachVideoToLesson($file->lesson);

        $foreignStudent = $this->createStudent(['email' => 'subject-lessons-foreign@rshd.test']);
        Sanctum::actingAs($foreignStudent);

        $response = $this->getJson('/api/v1/subjects/'.$subject->id.'/lessons')
            ->assertOk()
            ->assertJsonPath('success', true);

        $lesson = collect($response->json('data'))->firstWhere('id', $file->lesson_id);
        $this->assertNotNull($lesson);

        $filePayload = collect($lesson['files'] ?? [])->firstWhere('id', $file->id);
        $this->assertTrue($filePayload['is_locked'] ?? false);
        $this->assertNull($filePayload['file_url'] ?? null);
        $this->assertFalse($filePayload['requires_signed_download'] ?? true);

        $videoPayload = collect($lesson['videos'] ?? [])->first();
        $this->assertTrue($videoPayload['is_locked'] ?? false);
        $this->assertNull($videoPayload['playback']['url'] ?? null);
    }

    public function test_expired_enrollment_student_sees_locked_protected_content(): void
    {
        [$student, $file] = $this->createEnrolledLessonFileScenario(expiresAt: now()->subDay());
        $subject = $file->lesson->subject;
        $this->attachVideoToLesson($file->lesson);

        Sanctum::actingAs($student);

        $response = $this->getJson('/api/v1/subjects/'.$subject->id.'/lessons')->assertOk();

        $lesson = collect($response->json('data'))->firstWhere('id', $file->lesson_id);
        $filePayload = collect($lesson['files'] ?? [])->firstWhere('id', $file->id);

        $this->assertTrue($filePayload['is_locked'] ?? false);
        $this->assertNull($filePayload['file_url'] ?? null);
    }

    public function test_anonymous_user_cannot_list_subject_lessons(): void
    {
        [, $file] = $this->createEnrolledLessonFileScenario();

        $this->getJson('/api/v1/subjects/'.$file->lesson->subject_id.'/lessons')
            ->assertUnauthorized();
    }

    public function test_enrolled_student_cannot_unlock_foreign_subject_via_id_manipulation(): void
    {
        [$studentA] = $this->createEnrolledLessonFileScenario();
        [$studentB, $foreignFile] = $this->createEnrolledLessonFileScenario();
        $foreignSubject = $foreignFile->lesson->subject;

        Sanctum::actingAs($studentA);

        $response = $this->getJson('/api/v1/subjects/'.$foreignSubject->id.'/lessons')
            ->assertOk();

        $lesson = collect($response->json('data'))->firstWhere('id', $foreignFile->lesson_id);
        $filePayload = collect($lesson['files'] ?? [])->firstWhere('id', $foreignFile->id);

        $this->assertTrue($filePayload['is_locked'] ?? false);
        $this->assertNull($filePayload['file_url'] ?? null);

        Sanctum::actingAs($studentB);

        $owned = $this->getJson('/api/v1/subjects/'.$foreignSubject->id.'/lessons')->assertOk();
        $ownedLesson = collect($owned->json('data'))->firstWhere('id', $foreignFile->lesson_id);
        $ownedFile = collect($ownedLesson['files'] ?? [])->firstWhere('id', $foreignFile->id);

        $this->assertFalse($ownedFile['is_locked'] ?? true);
        $this->assertTrue($ownedFile['requires_signed_download'] ?? false);
    }

    public function test_nested_lesson_payload_does_not_expose_permanent_bunny_paths(): void
    {
        [$student, $file] = $this->createEnrolledLessonFileScenario();
        $subject = $file->lesson->subject;

        Sanctum::actingAs($student);

        $payload = json_encode(
            $this->getJson('/api/v1/subjects/'.$subject->id.'/lessons')->json('data'),
        );

        $this->assertStringNotContainsString($file->external_path, $payload);
        $this->assertStringNotContainsString('storage.bunnycdn.com', strtolower($payload));
    }

    private function attachVideoToLesson($lesson): Video
    {
        return Video::query()->create([
            'lesson_id' => $lesson->id,
            'title' => 'فيديو تجريبي',
            'is_free' => false,
            'duration_seconds' => 120,
            'status' => VideoStatus::Ready,
            'storage_provider' => 'local',
            'video_path' => 'videos/sample.mp4',
        ]);
    }
}
