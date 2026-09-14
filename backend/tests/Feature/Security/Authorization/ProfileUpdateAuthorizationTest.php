<?php

namespace Tests\Feature\Security\Authorization;


use PHPUnit\Framework\Attributes\Group;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Models\User;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Feature\Security\Concerns\CreatesEnrollmentScenario;
use Tests\TestCase;

#[Group('security')]
class ProfileUpdateAuthorizationTest extends TestCase
{
    use CreatesEnrollmentScenario;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
    }

    public function test_student_can_update_own_profile(): void
    {
        $student = $this->createStudent([
            'email' => 'profile-owner@rshd.test',
            'name' => 'Student Original',
        ]);

        Sanctum::actingAs($student);

        $this->patchJson('/api/v1/student/profile', [
            'name' => 'Student Updated',
            'phone' => '0790000000',
        ])
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.profile.name', 'Student Updated');

        $this->assertSame('Student Updated', $student->fresh()->name);
        $this->assertSame('0790000000', $student->fresh()->phone);
    }

    public function test_student_cannot_modify_another_user_via_body_identifiers(): void
    {
        $studentA = $this->createStudent([
            'email' => 'profile-a@rshd.test',
            'name' => 'Student A',
        ]);
        $studentB = $this->createStudent([
            'email' => 'profile-b@rshd.test',
            'name' => 'Student B',
        ]);

        Sanctum::actingAs($studentA);

        $this->patchJson('/api/v1/student/profile', [
            'name' => 'Student A Updated',
            'id' => $studentB->id,
            'user_id' => $studentB->id,
            'student_id' => $studentB->id,
        ])
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->assertSame('Student A Updated', $studentA->fresh()->name);
        $this->assertSame('Student B', $studentB->fresh()->name);
    }

    public function test_privileged_fields_are_not_mass_assignable(): void
    {
        $student = $this->createStudent([
            'email' => 'profile-priv@rshd.test',
            'name' => 'Safe Name',
            'role' => UserRole::Student,
            'status' => UserStatus::Active,
        ]);

        $originalEmail = $student->email;
        $originalRole = $student->role;
        $originalStatus = $student->status;
        $originalVerifiedAt = $student->email_verified_at?->toIso8601String();

        Sanctum::actingAs($student);

        $this->patchJson('/api/v1/student/profile', [
            'name' => 'Still Safe Name',
            'role' => UserRole::Admin->value,
            'status' => UserStatus::Blocked->value,
            'email' => 'hacked@rshd.test',
            'email_verified_at' => now()->subYear()->toIso8601String(),
            'password' => 'NewPassword1!',
        ])
            ->assertOk()
            ->assertJsonPath('success', true);

        $fresh = $student->fresh();

        $this->assertSame('Still Safe Name', $fresh->name);
        $this->assertSame($originalEmail, $fresh->email);
        $this->assertSame($originalRole, $fresh->role);
        $this->assertSame($originalStatus, $fresh->status);
        $this->assertSame($originalVerifiedAt, $fresh->email_verified_at?->toIso8601String());
    }

    public function test_non_student_cannot_update_student_profile_endpoint(): void
    {
        $instructor = User::factory()->create([
            'role' => UserRole::Instructor,
            'status' => UserStatus::Active,
            'email_verified_at' => now(),
        ]);

        Sanctum::actingAs($instructor);

        $this->patchJson('/api/v1/student/profile', [
            'name' => 'Instructor Attempt',
        ])->assertForbidden();
    }

    public function test_anonymous_user_cannot_update_profile(): void
    {
        $this->patchJson('/api/v1/student/profile', [
            'name' => 'Anonymous Attempt',
        ])->assertUnauthorized();
    }
}
