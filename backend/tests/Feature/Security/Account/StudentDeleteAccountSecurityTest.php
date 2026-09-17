<?php

namespace Tests\Feature\Security\Account;


use PHPUnit\Framework\Attributes\Group;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\Feature\Security\Concerns\CreatesEnrollmentScenario;
use Tests\TestCase;

#[Group('security')]
class StudentDeleteAccountSecurityTest extends TestCase
{
    use CreatesEnrollmentScenario;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
    }

    public function test_student_can_delete_own_account_with_password_and_confirmation(): void
    {
        $student = $this->createStudent([
            'email' => 'delete-own@rshd.test',
            'password' => Hash::make('DeleteMe123!'),
            'password_set_at' => now(),
        ]);

        Sanctum::actingAs($student);

        $this->postJson('/api/v1/student/account/delete', [
            'password' => 'DeleteMe123!',
            'confirmation' => 'حذف',
        ])
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->assertDatabaseMissing('users', ['id' => $student->id]);
        $this->assertNull($student->fresh());
    }

    public function test_deleted_account_revokes_current_session_token(): void
    {
        $student = $this->createStudent([
            'email' => 'delete-token@rshd.test',
            'password' => Hash::make('DeleteMe123!'),
            'password_set_at' => now(),
        ]);

        $createdToken = $student->createToken('api');
        $plainTextToken = $createdToken->plainTextToken;
        $tokenId = $createdToken->accessToken->getKey();

        $this->withToken($plainTextToken)->postJson('/api/v1/student/account/delete', [
            'password' => 'DeleteMe123!',
            'confirmation' => 'حذف',
        ])->assertOk();

        $this->assertDatabaseMissing('personal_access_tokens', [
            'id' => $tokenId,
        ]);

        $this->assertDatabaseMissing('users', [
            'id' => $student->id,
        ]);
    }

    public function test_wrong_password_is_rejected(): void
    {
        $student = $this->createStudent([
            'email' => 'delete-wrong-pass@rshd.test',
            'password' => Hash::make('DeleteMe123!'),
            'password_set_at' => now(),
        ]);

        Sanctum::actingAs($student);

        $this->postJson('/api/v1/student/account/delete', [
            'password' => 'WrongPassword1!',
            'confirmation' => 'حذف',
        ])->assertStatus(422);

        $this->assertSame('delete-wrong-pass@rshd.test', $student->fresh()->email);
    }

    public function test_wrong_confirmation_is_rejected(): void
    {
        $student = $this->createStudent([
            'email' => 'delete-no-confirm@rshd.test',
            'password' => Hash::make('DeleteMe123!'),
            'password_set_at' => now(),
        ]);

        Sanctum::actingAs($student);

        $this->postJson('/api/v1/student/account/delete', [
            'password' => 'DeleteMe123!',
            'confirmation' => 'delete',
        ])->assertStatus(422);
    }

    public function test_missing_confirmation_is_rejected(): void
    {
        $student = $this->createStudent([
            'email' => 'delete-missing-confirm@rshd.test',
            'password' => Hash::make('DeleteMe123!'),
            'password_set_at' => now(),
        ]);

        Sanctum::actingAs($student);

        $this->postJson('/api/v1/student/account/delete', [
            'password' => 'DeleteMe123!',
        ])->assertStatus(422);

        $this->assertDatabaseHas('users', ['id' => $student->id]);
    }

    public function test_delete_account_removes_avatar_file(): void
    {
        Storage::fake('public');

        $avatarPath = 'avatars/delete-account-test.png';
        Storage::disk('public')->put($avatarPath, 'avatar');

        $student = $this->createStudent([
            'email' => 'delete-avatar@rshd.test',
            'password' => Hash::make('DeleteMe123!'),
            'password_set_at' => now(),
            'avatar_path' => $avatarPath,
        ]);

        Sanctum::actingAs($student);

        $this->postJson('/api/v1/student/account/delete', [
            'password' => 'DeleteMe123!',
            'confirmation' => 'حذف',
        ])->assertOk();

        Storage::disk('public')->assertMissing($avatarPath);
        $this->assertDatabaseMissing('users', ['id' => $student->id]);
    }

    public function test_delete_account_removes_assignment_submission_file(): void
    {
        Storage::fake('local');

        $student = $this->createStudent([
            'email' => 'delete-submission@rshd.test',
            'password' => Hash::make('DeleteMe123!'),
            'password_set_at' => now(),
        ]);

        $subject = $this->createSubject();

        $assignment = \App\Models\Assignment::query()->create([
            'subject_id' => $subject->id,
            'title' => 'واجب اختبار حذف الحساب',
        ]);

        $submissionPath = 'assignment-submissions/delete-account-test.pdf';
        Storage::disk('local')->put($submissionPath, 'submission-file');

        $submission = \App\Models\AssignmentSubmission::query()->create([
            'assignment_id' => $assignment->id,
            'student_id' => $student->id,
            'file_path' => $submissionPath,
            'original_file_name' => 'submission.pdf',
            'file_size' => 15,
            'file_mime_type' => 'application/pdf',
            'submitted_at' => now(),
        ]);

        Sanctum::actingAs($student);

        $this->postJson('/api/v1/student/account/delete', [
            'password' => 'DeleteMe123!',
            'confirmation' => 'حذف',
        ])->assertOk();

        Storage::disk('local')->assertMissing($submissionPath);

        $this->assertDatabaseMissing('assignment_submissions', [
            'id' => $submission->id,
        ]);

        $this->assertDatabaseMissing('users', [
            'id' => $student->id,
        ]);
    }

    public function test_anonymous_user_cannot_delete_account(): void
    {
        $this->postJson('/api/v1/student/account/delete', [
            'password' => 'DeleteMe123!',
            'confirmation' => 'حذف',
        ])->assertUnauthorized();
    }

    public function test_delete_account_does_not_accept_foreign_user_id(): void
    {
        $studentA = $this->createStudent([
            'email' => 'delete-a@rshd.test',
            'password' => Hash::make('DeleteMe123!'),
            'password_set_at' => now(),
        ]);
        $studentB = $this->createStudent([
            'email' => 'delete-b@rshd.test',
            'password' => Hash::make('DeleteMe123!'),
            'password_set_at' => now(),
        ]);

        Sanctum::actingAs($studentA);

        $this->postJson('/api/v1/student/account/delete', [
            'password' => 'DeleteMe123!',
            'confirmation' => 'حذف',
            'user_id' => $studentB->id,
        ])->assertOk();

        $this->assertSame('delete-b@rshd.test', $studentB->fresh()->email);
        $this->assertDatabaseMissing('users', ['id' => $studentA->id]);
        $this->assertNull($studentA->fresh());
    }
}
