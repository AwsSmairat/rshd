<?php

namespace Tests\Feature\Security\Account;


use PHPUnit\Framework\Attributes\Group;
use App\Enums\UserStatus;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
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

        $fresh = $student->fresh();
        $this->assertSame(UserStatus::Blocked, $fresh->status);
        $this->assertStringContainsString('deleted_', $fresh->email);
    }

    public function test_deleted_account_revokes_current_session_token(): void
    {
        $student = $this->createStudent([
            'email' => 'delete-token@rshd.test',
            'password' => Hash::make('DeleteMe123!'),
            'password_set_at' => now(),
        ]);
        $token = $student->createToken('api')->plainTextToken;

        $this->withToken($token)->postJson('/api/v1/student/account/delete', [
            'password' => 'DeleteMe123!',
            'confirmation' => 'حذف',
        ])->assertOk();

        $this->withToken($token)->getJson('/api/v1/me')->assertForbidden();
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

    public function test_missing_confirmation_is_rejected(): void
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
        $this->assertStringContainsString('deleted_', $studentA->fresh()->email);
    }
}
