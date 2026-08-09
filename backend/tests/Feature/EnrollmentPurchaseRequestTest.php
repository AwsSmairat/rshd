<?php

namespace Tests\Feature;

use App\Enums\AccessStatus;
use App\Enums\ContentStatus;
use App\Enums\PaymentStatus;
use App\Enums\SubjectCategory;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Models\Subject;
use App\Models\SubjectStudent;
use App\Models\User;
use App\Services\EnrollmentService;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class EnrollmentPurchaseRequestTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
    }

    public function test_admin_rejecting_pending_request_clears_student_catalog_status(): void
    {
        [$student, $subject] = $this->createPendingPurchaseScenario();

        app(EnrollmentService::class)->rejectPurchaseRequest(
            $student,
            $subject,
            $this->createAdmin(),
        );

        $this->assertDatabaseMissing('subject_students', [
            'student_id' => $student->id,
            'subject_id' => $subject->id,
        ]);

        Sanctum::actingAs($student);

        $response = $this->getJson('/api/v1/subjects')
            ->assertOk()
            ->json('data');

        $subjectPayload = collect($response)->firstWhere('id', $subject->id);
        $this->assertSame('none', $subjectPayload['enrollment_status'] ?? null);
    }

    public function test_revoked_unpaid_enrollment_is_not_reported_as_pending(): void
    {
        [$student, $subject] = $this->createPendingPurchaseScenario();

        SubjectStudent::query()
            ->where('student_id', $student->id)
            ->where('subject_id', $subject->id)
            ->update(['access_status' => AccessStatus::Revoked]);

        $status = app(EnrollmentService::class)->enrollmentStatusFor($student, $subject);

        $this->assertSame('none', $status);
    }

    /**
     * @return array{0: User, 1: Subject}
     */
    private function createPendingPurchaseScenario(): array
    {
        $student = User::factory()->create([
            'role' => UserRole::Student,
            'status' => UserStatus::Active,
            'email_verified_at' => now(),
        ]);
        $student->assignRole(Role::findByName(UserRole::Student->value, 'web'));

        $instructor = User::factory()->create([
            'role' => UserRole::Instructor,
            'status' => UserStatus::Active,
            'email_verified_at' => now(),
        ]);

        $subject = Subject::query()->create([
            'instructor_id' => $instructor->id,
            'title' => 'أساسيات التشريح',
            'description' => 'وصف',
            'category' => SubjectCategory::Medicine->value,
            'status' => ContentStatus::Active,
            'price' => 50,
        ]);

        SubjectStudent::query()->create([
            'subject_id' => $subject->id,
            'student_id' => $student->id,
            'payment_status' => PaymentStatus::Unpaid,
            'access_status' => AccessStatus::Pending,
        ]);

        return [$student, $subject];
    }

    private function createAdmin(): User
    {
        $admin = User::factory()->create([
            'role' => UserRole::Admin,
            'status' => UserStatus::Active,
            'email_verified_at' => now(),
        ]);
        $admin->assignRole(Role::findByName(UserRole::Admin->value, 'web'));

        return $admin;
    }
}
