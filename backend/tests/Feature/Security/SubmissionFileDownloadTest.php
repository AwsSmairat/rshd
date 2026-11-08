<?php

namespace Tests\Feature\Security;

use App\Enums\ContentStatus;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Models\Assignment;
use App\Models\AssignmentSubmission;
use App\Models\User;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use PHPUnit\Framework\Attributes\Group;
use Tests\Feature\Security\Concerns\CreatesEnrollmentScenario;
use Tests\TestCase;

/**
 * Staff open a student's submitted file through a signed link: the subject's
 * instructor and admins only, and only while signed in.
 */
#[Group('security')]
class SubmissionFileDownloadTest extends TestCase
{
    use CreatesEnrollmentScenario;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
        Storage::fake('local');
    }

    public function test_the_subjects_instructor_downloads_the_file(): void
    {
        [$instructor, $submission] = $this->scenario();

        $this->actingAs($instructor)
            ->get($submission->resolvedFileUrl())
            ->assertOk()
            ->assertDownload()
            ->assertHeader('X-Content-Type-Options', 'nosniff');
    }

    public function test_another_instructor_is_refused(): void
    {
        [, $submission] = $this->scenario();
        $other = $this->instructor();

        // Refusals under /admin send a signed-in user back to the dashboard.
        $this->actingAs($other)
            ->get($submission->resolvedFileUrl())
            ->assertRedirect('/admin');
    }

    public function test_a_signed_out_visitor_is_refused(): void
    {
        [, $submission] = $this->scenario();

        $this->get($submission->resolvedFileUrl())->assertForbidden();
    }

    public function test_an_unsigned_link_is_refused(): void
    {
        [$instructor, $submission] = $this->scenario();

        $this->actingAs($instructor)
            ->get(route('admin.assignment-submissions.file', $submission))
            ->assertRedirect('/admin');
    }

    /**
     * @return array{User, AssignmentSubmission}
     */
    private function scenario(): array
    {
        $instructor = $this->instructor();
        $subject = $this->createSubject($instructor);
        $lesson = $this->createLesson($subject);
        $student = $this->createStudent();

        $assignment = Assignment::query()->create([
            'subject_id' => $subject->id,
            'lesson_id' => $lesson->id,
            'title' => 'واجب',
            'description' => 'وصف',
            'due_date' => now()->addWeek(),
            'status' => ContentStatus::Active,
        ]);

        $path = "assignment-submissions/{$student->id}/{$assignment->id}/work.pdf";
        Storage::disk('local')->put($path, '%PDF-1.4 test');

        $submission = AssignmentSubmission::query()->create([
            'assignment_id' => $assignment->id,
            'student_id' => $student->id,
            'file_path' => $path,
            'original_file_name' => 'حل الطالب.pdf',
            'submitted_at' => now(),
        ]);

        return [$instructor, $submission];
    }

    private function instructor(): User
    {
        return User::factory()->create([
            'role' => UserRole::Instructor,
            'status' => UserStatus::Active,
            'email_verified_at' => now(),
        ]);
    }
}
