<?php

namespace Tests\Feature;

use App\Enums\AccessStatus;
use App\Enums\ContentStatus;
use App\Enums\FileType;
use App\Enums\LessonFileStorageStatus;
use App\Enums\PaymentStatus;
use App\Enums\SubjectCategory;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Models\Lesson;
use App\Models\LessonFile;
use App\Models\Subject;
use App\Models\SubjectStudent;
use App\Models\User;
use App\Services\Bunny\BunnyFilesCdnTokenSigner;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class LessonFileDownloadTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);

        config([
            'files.signed_download' => true,
            'files.download_ttl' => 600,
            'files.bunny.token_key' => 'test-files-token-key',
            'files.bunny.cdn_hostname' => 'files-test.b-cdn.net',
            'files.bunny.storage_zone' => 'test-zone',
            'files.bunny.storage_password' => 'test-storage-password',
            'files.bunny.storage_hostname' => 'storage.bunnycdn.com',
        ]);
    }

    public function test_enrolled_student_receives_signed_download_url(): void
    {
        [$student, $file] = $this->createEnrolledLessonFileScenario();

        Sanctum::actingAs($student);

        $response = $this->getJson('/api/v1/files/'.$file->id.'/download')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => ['url', 'expires_at'],
            ]);

        $url = (string) $response->json('data.url');
        $this->assertStringContainsString('files-test.b-cdn.net', $url);
        $this->assertStringContainsString('token=', $url);
        $this->assertStringContainsString('expires=', $url);
        $this->assertStringContainsString('/lesson-files/'.$file->id.'/', $url);
    }

    public function test_show_does_not_expose_permanent_file_url_for_bunny_files(): void
    {
        [$student, $file] = $this->createEnrolledLessonFileScenario();

        Sanctum::actingAs($student);

        $this->getJson('/api/v1/files/'.$file->id)
            ->assertOk()
            ->assertJsonPath('data.file_url', null)
            ->assertJsonPath('data.requires_signed_download', true);
    }

    public function test_student_without_enrollment_is_blocked(): void
    {
        [, $file] = $this->createEnrolledLessonFileScenario();
        $other = $this->createStudent(['email' => 'other@rshdacademy.com']);

        Sanctum::actingAs($other);

        $this->getJson('/api/v1/files/'.$file->id.'/download')
            ->assertForbidden();
    }

    public function test_expired_enrollment_is_blocked(): void
    {
        [$student, $file] = $this->createEnrolledLessonFileScenario(
            expiresAt: now()->subDay(),
        );

        Sanctum::actingAs($student);

        $this->getJson('/api/v1/files/'.$file->id.'/download')
            ->assertForbidden();
    }

    public function test_idor_access_to_other_subject_file_is_blocked(): void
    {
        [$student] = $this->createEnrolledLessonFileScenario();
        $otherSubject = $this->createSubject();
        $otherLesson = $this->createLesson($otherSubject);
        $otherFile = $this->createBunnyLessonFile($otherLesson);

        Sanctum::actingAs($student);

        $this->getJson('/api/v1/files/'.$otherFile->id.'/download')
            ->assertForbidden();
    }

    public function test_blocked_user_is_denied(): void
    {
        [$student, $file] = $this->createEnrolledLessonFileScenario();
        $student->forceFill(['status' => UserStatus::Blocked])->save();

        Sanctum::actingAs($student);

        $this->getJson('/api/v1/files/'.$file->id.'/download')
            ->assertForbidden();
    }

    public function test_missing_bunny_config_fails_secure(): void
    {
        [$student, $file] = $this->createEnrolledLessonFileScenario();

        config(['files.bunny.token_key' => '']);

        Sanctum::actingAs($student);

        $this->getJson('/api/v1/files/'.$file->id.'/download')
            ->assertForbidden();
    }

    public function test_unsigned_cdn_url_is_distinct_from_signed_url(): void
    {
        [, $file] = $this->createEnrolledLessonFileScenario();

        $signer = app(BunnyFilesCdnTokenSigner::class);
        $unsigned = $signer->unsignedCdnUrl((string) $file->external_path);
        $signed = $signer->signCdnPath((string) $file->external_path, time() + 600);

        $this->assertStringNotContainsString('token=', $unsigned);
        $this->assertStringContainsString('token=', $signed);
    }

    public function test_expired_signed_url_has_past_expiry_timestamp(): void
    {
        [, $file] = $this->createEnrolledLessonFileScenario();

        $signer = app(BunnyFilesCdnTokenSigner::class);
        $signed = $signer->signCdnPath((string) $file->external_path, time() - 60);

        $this->assertMatchesRegularExpression('/expires=\d+/', $signed);
        preg_match('/expires=(\d+)/', $signed, $matches);
        $this->assertLessThan(time(), (int) ($matches[1] ?? 0));
    }

    public function test_pending_bunny_upload_serves_local_signed_stream_url(): void
    {
        [$student, $file] = $this->createEnrolledLessonFileScenario();

        $file->forceFill([
            'external_path' => null,
            'storage_status' => LessonFileStorageStatus::Pending,
            'storage_disk' => 'lesson_files',
            'file_path' => 'sources/pending-local.pdf',
        ])->save();

        \Illuminate\Support\Facades\Storage::disk('lesson_files')->put(
            'sources/pending-local.pdf',
            '%PDF-1.4 pending-local',
        );

        Sanctum::actingAs($student);

        $response = $this->getJson('/api/v1/files/'.$file->id.'/download')
            ->assertOk()
            ->assertJsonPath('success', true);

        $url = (string) $response->json('data.url');
        $this->assertStringContainsString('/api/v1/files/'.$file->id.'/stream', $url);
        $this->assertStringContainsString('signature=', $url);
        $this->assertStringContainsString('expires=', $url);

        $streamResponse = $this->get($url);
        $streamResponse->assertOk();
        $this->assertSame('%PDF-1.4 pending-local', $streamResponse->streamedContent());
    }

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
