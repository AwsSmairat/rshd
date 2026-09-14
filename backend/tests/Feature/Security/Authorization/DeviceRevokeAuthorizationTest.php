<?php

namespace Tests\Feature\Security\Authorization;


use PHPUnit\Framework\Attributes\Group;
use App\Models\StudentDevice;
use App\Models\User;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Feature\Security\Concerns\CreatesEnrollmentScenario;
use Tests\TestCase;

#[Group('security')]
class DeviceRevokeAuthorizationTest extends TestCase
{
    use CreatesEnrollmentScenario;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
    }

    public function test_student_can_revoke_own_device(): void
    {
        $student = $this->createStudent();
        $device = $this->createDeviceFor($student, 'device-a');

        Sanctum::actingAs($student);

        $this->deleteJson('/api/v1/student/devices/'.$device->id)
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->assertFalse($device->fresh()->is_active);
    }

    public function test_student_cannot_revoke_foreign_device(): void
    {
        $owner = $this->createStudent(['email' => 'device-owner@rshd.test']);
        $attacker = $this->createStudent(['email' => 'device-attacker@rshd.test']);
        $foreignDevice = $this->createDeviceFor($owner, 'device-b');

        Sanctum::actingAs($attacker);

        $this->deleteJson('/api/v1/student/devices/'.$foreignDevice->id)
            ->assertNotFound();

        $this->assertTrue($foreignDevice->fresh()->is_active);
    }

    public function test_revoking_nonexistent_device_is_safe(): void
    {
        $student = $this->createStudent();

        Sanctum::actingAs($student);

        $this->deleteJson('/api/v1/student/devices/999999')
            ->assertNotFound();
    }

    protected function createDeviceFor(User $student, string $deviceId): StudentDevice
    {
        return StudentDevice::query()->create([
            'student_id' => $student->id,
            'device_id' => $deviceId,
            'device_name' => 'Test Device',
            'platform' => 'ios',
            'is_active' => true,
            'last_login_at' => now(),
        ]);
    }
}
