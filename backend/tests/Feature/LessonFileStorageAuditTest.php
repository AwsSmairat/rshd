<?php

namespace Tests\Feature;

use App\Enums\ContentStatus;
use App\Enums\FileType;
use App\Enums\LessonFileStorageStatus;
use App\Enums\SubjectCategory;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Models\Lesson;
use App\Models\LessonFile;
use App\Models\Subject;
use App\Models\User;
use App\Services\Bunny\BunnyFilesStorageClient;
use App\Services\LessonFiles\LessonFileBunnyStorageAuditService;
use App\Services\LessonFiles\LessonFileStorageAuditService;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class LessonFileStorageAuditTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
    }

    public function test_local_audit_flags_public_pdf_delivery_source(): void
    {
        Storage::disk('public')->put('lesson-files/demo.pdf', 'pdf');

        $lesson = $this->createLesson();

        LessonFile::query()->create([
            'lesson_id' => $lesson->id,
            'title' => 'Public PDF',
            'file_type' => FileType::Pdf,
            'file_url' => 'https://example.test/storage/lesson-files/demo.pdf',
            'file_path' => 'lesson-files/demo.pdf',
        ]);

        $report = app(LessonFileStorageAuditService::class)->audit();

        $this->assertSame(1, $report['summary']['public_pdf_files']);
    }

    public function test_bunny_audit_detects_orphan_and_linked_objects(): void
    {
        $client = \Mockery::mock(BunnyFilesStorageClient::class);
        $client->shouldReceive('isConfigured')->andReturn(true);
        $client->shouldReceive('listDirectory')
            ->with('lesson-files')
            ->andReturn([
                ['ObjectName' => '1', 'IsDirectory' => true],
            ]);
        $client->shouldReceive('listDirectory')
            ->with('lesson-files/1')
            ->andReturn([
                [
                    'ObjectName' => 'linked.pdf',
                    'IsDirectory' => false,
                    'Length' => 100,
                ],
                [
                    'ObjectName' => 'orphan.pdf',
                    'IsDirectory' => false,
                    'Length' => 200,
                ],
            ]);

        $this->app->instance(BunnyFilesStorageClient::class, $client);

        $lesson = $this->createLesson();

        LessonFile::query()->create([
            'lesson_id' => $lesson->id,
            'title' => 'Linked',
            'file_type' => FileType::Pdf,
            'file_url' => '',
            'storage_provider' => 'bunny',
            'external_path' => 'lesson-files/1/linked.pdf',
            'storage_status' => LessonFileStorageStatus::Ready,
        ]);

        $report = app(LessonFileBunnyStorageAuditService::class)->audit();

        $this->assertSame(2, $report['summary']['remote_objects']);
        $this->assertSame(1, $report['summary']['linked_objects']);
        $this->assertSame(1, $report['summary']['orphan_objects']);
    }

    public function test_delete_orphan_command_requires_confirm_and_exact_path(): void
    {
        $audit = \Mockery::mock(LessonFileBunnyStorageAuditService::class);
        $audit->shouldReceive('isConfirmedOrphan')
            ->once()
            ->with('lesson-files/1/orphan.pdf')
            ->andReturn(true);

        $storage = \Mockery::mock(BunnyFilesStorageClient::class);
        $storage->shouldReceive('delete')
            ->once()
            ->with('lesson-files/1/orphan.pdf')
            ->andReturn(true);

        $this->app->instance(LessonFileBunnyStorageAuditService::class, $audit);
        $this->app->instance(BunnyFilesStorageClient::class, $storage);

        $this->artisan('files:delete-bunny-orphan', [
            '--path' => 'lesson-files/1/orphan.pdf',
            '--confirm' => true,
        ])->assertSuccessful();
    }

    protected function createLesson(): Lesson
    {
        $instructor = User::factory()->create([
            'role' => UserRole::Instructor,
            'status' => UserStatus::Active,
            'email_verified_at' => now(),
        ]);

        $subject = Subject::query()->create([
            'instructor_id' => $instructor->id,
            'title' => 'مادة',
            'description' => 'وصف',
            'category' => SubjectCategory::General->value,
            'status' => ContentStatus::Active,
            'price' => 10,
        ]);

        return Lesson::query()->create([
            'subject_id' => $subject->id,
            'title' => 'درس',
            'description' => 'وصف',
            'status' => ContentStatus::Active,
        ]);
    }
}
