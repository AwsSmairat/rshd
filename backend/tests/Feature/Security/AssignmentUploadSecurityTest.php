<?php

namespace Tests\Feature\Security;

use App\Enums\AccessStatus;
use App\Enums\ContentStatus;
use App\Enums\PaymentStatus;
use App\Models\Assignment;
use App\Models\SubjectStudent;
use App\Models\User;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use PHPUnit\Framework\Attributes\Group;
use Tests\Feature\Security\Concerns\CreatesEnrollmentScenario;
use Tests\TestCase;

#[Group('security')]
class AssignmentUploadSecurityTest extends TestCase
{
    use CreatesEnrollmentScenario;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
        Storage::fake('local');
    }

    public function test_enrolled_student_can_upload_allowed_file(): void
    {
        [$student, $assignment] = $this->createAssignmentScenario();

        Sanctum::actingAs($student);

        $this->postJson('/api/v1/assignments/'.$assignment->id.'/submit', [
            'answer_text' => 'إجابة تجريبية',
            'file' => UploadedFile::fake()->create('work.pdf', 100, 'application/pdf'),
        ], ['Accept' => 'application/json'])
            ->assertOk()
            ->assertJsonPath('data.has_attached_file', true)
            ->assertJsonPath('data.file_url', null);
    }

    public function test_foreign_student_is_blocked(): void
    {
        [, $assignment] = $this->createAssignmentScenario();
        $foreign = $this->createStudent(['email' => 'foreign-upload@rshd.test']);

        Sanctum::actingAs($foreign);

        $this->postJson('/api/v1/assignments/'.$assignment->id.'/submit', [
            'file' => UploadedFile::fake()->create('work.pdf', 100, 'application/pdf'),
        ], ['Accept' => 'application/json'])
            ->assertForbidden();
    }

    public function test_executable_extension_is_blocked(): void
    {
        [$student, $assignment] = $this->createAssignmentScenario();

        Sanctum::actingAs($student);

        $this->postJson('/api/v1/assignments/'.$assignment->id.'/submit', [
            'file' => UploadedFile::fake()->create('evil.php', 10, 'application/pdf'),
        ], ['Accept' => 'application/json'])
            ->assertStatus(422);
    }

    public function test_oversized_upload_is_rejected(): void
    {
        [$student, $assignment] = $this->createAssignmentScenario();

        Sanctum::actingAs($student);

        $this->postJson('/api/v1/assignments/'.$assignment->id.'/submit', [
            'file' => UploadedFile::fake()->create('big.pdf', 11000, 'application/pdf'),
        ], ['Accept' => 'application/json'])
            ->assertStatus(422);
    }

    /**
     * @return array{0: User, 1: Assignment}
     */
    public function test_assignments_have_no_deadline(): void
    {
        [$student, $assignment] = $this->createAssignmentScenario();
        // An old date left on an assignment from before deadlines were dropped.
        $assignment->update(['due_date' => now()->subMonth()]);
        Sanctum::actingAs($student);

        $this->getJson('/api/v1/assignments')
            ->assertOk()
            ->assertJsonPath('data.0.due_date', null);

        $this->postJson('/api/v1/assignments/'.$assignment->id.'/submit', [
            'answer_text' => 'تسليم في أي وقت',
        ])->assertOk();
    }

    public function test_unpublished_assignment_takes_no_submissions(): void
    {
        [$student, $assignment] = $this->createAssignmentScenario();
        $assignment->update(['status' => ContentStatus::Inactive]);
        Sanctum::actingAs($student);

        $this->postJson('/api/v1/assignments/'.$assignment->id.'/submit', [
            'answer_text' => 'مسودة',
        ])->assertForbidden();
    }

    protected function createAssignmentScenario(): array
    {
        $student = $this->createStudent();
        $subject = $this->createSubject();
        $lesson = $this->createLesson($subject);

        SubjectStudent::query()->create([
            'subject_id' => $subject->id,
            'student_id' => $student->id,
            'payment_status' => PaymentStatus::Paid,
            'access_status' => AccessStatus::Active,
        ]);

        $assignment = Assignment::query()->create([
            'subject_id' => $subject->id,
            'lesson_id' => $lesson->id,
            'title' => 'واجب أمني',
            'description' => 'اختبار',
            'due_date' => now()->addWeek(),
            'status' => ContentStatus::Active,
        ]);

        return [$student, $assignment];
    }
}
