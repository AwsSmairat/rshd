<?php

namespace Tests\Feature\Security\Account;

use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\Sanctum;
use Tests\Feature\Security\Concerns\CreatesEnrollmentScenario;
use Tests\TestCase;

/**
 * @group security
 */
class StudentPasswordUpdateSecurityTest extends TestCase
{
    use CreatesEnrollmentScenario;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
    }

    public function test_student_can_update_password_with_valid_current_password(): void
    {
        $student = $this->createStudent([
            'email' => 'pass-update@rshd.test',
            'password' => Hash::make('CurrentPass123!'),
            'password_set_at' => now(),
        ]);

        Sanctum::actingAs($student);

        $this->patchJson('/api/v1/student/password', [
            'current_password' => 'CurrentPass123!',
            'password' => 'NewPass123!',
            'password_confirmation' => 'NewPass123!',
        ])
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->assertTrue(Hash::check('NewPass123!', $student->fresh()->password));
        $this->assertFalse(Hash::check('CurrentPass123!', $student->fresh()->password));
    }

    public function test_wrong_current_password_is_rejected(): void
    {
        $student = $this->createStudent([
            'email' => 'pass-wrong-current@rshd.test',
            'password' => Hash::make('CurrentPass123!'),
            'password_set_at' => now(),
        ]);

        Sanctum::actingAs($student);

        $this->patchJson('/api/v1/student/password', [
            'current_password' => 'WrongPass123!',
            'password' => 'NewPass123!',
            'password_confirmation' => 'NewPass123!',
        ])->assertStatus(422);

        $this->assertTrue(Hash::check('CurrentPass123!', $student->fresh()->password));
    }

    public function test_password_confirmation_mismatch_is_rejected(): void
    {
        $student = $this->createStudent([
            'email' => 'pass-mismatch@rshd.test',
            'password' => Hash::make('CurrentPass123!'),
            'password_set_at' => now(),
        ]);

        Sanctum::actingAs($student);

        $this->patchJson('/api/v1/student/password', [
            'current_password' => 'CurrentPass123!',
            'password' => 'NewPass123!',
            'password_confirmation' => 'Different123!',
        ])->assertStatus(422);
    }

    public function test_user_a_cannot_change_user_b_password_via_body_ids(): void
    {
        $studentA = $this->createStudent([
            'email' => 'pass-a@rshd.test',
            'password' => Hash::make('CurrentPass123!'),
            'password_set_at' => now(),
        ]);
        $studentB = $this->createStudent([
            'email' => 'pass-b@rshd.test',
            'password' => Hash::make('OtherPass123!'),
            'password_set_at' => now(),
        ]);

        Sanctum::actingAs($studentA);

        $this->patchJson('/api/v1/student/password', [
            'current_password' => 'CurrentPass123!',
            'password' => 'NewPass123!',
            'password_confirmation' => 'NewPass123!',
            'user_id' => $studentB->id,
        ])->assertOk();

        $this->assertTrue(Hash::check('NewPass123!', $studentA->fresh()->password));
        $this->assertTrue(Hash::check('OtherPass123!', $studentB->fresh()->password));
    }

    public function test_anonymous_user_cannot_update_password(): void
    {
        $this->patchJson('/api/v1/student/password', [
            'current_password' => 'CurrentPass123!',
            'password' => 'NewPass123!',
            'password_confirmation' => 'NewPass123!',
        ])->assertUnauthorized();
    }

    public function test_new_password_works_for_login_after_update(): void
    {
        $student = $this->createStudent([
            'email' => 'pass-login@rshd.test',
            'password' => Hash::make('CurrentPass123!'),
            'password_set_at' => now(),
        ]);

        Sanctum::actingAs($student);

        $this->patchJson('/api/v1/student/password', [
            'current_password' => 'CurrentPass123!',
            'password' => 'NewPass123!',
            'password_confirmation' => 'NewPass123!',
        ])->assertOk();

        $this->postJson('/api/v1/login', [
            'email' => $student->email,
            'password' => 'NewPass123!',
            'device_id' => 'pass-login-device',
        ])->assertOk();

        $this->postJson('/api/v1/login', [
            'email' => $student->email,
            'password' => 'CurrentPass123!',
            'device_id' => 'pass-login-device',
        ])->assertStatus(422);
    }
}
