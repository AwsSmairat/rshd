<?php

namespace Tests\Feature\Security\Authorization;


use PHPUnit\Framework\Attributes\Group;
use App\Models\AppNotification;
use App\Models\User;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Feature\Security\Concerns\CreatesEnrollmentScenario;
use Tests\TestCase;

#[Group('security')]
class NotificationAuthorizationTest extends TestCase
{
    use CreatesEnrollmentScenario;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
    }

    public function test_student_can_mark_own_notification_as_read(): void
    {
        $student = $this->createStudent();
        $notification = $this->createNotificationFor($student);

        Sanctum::actingAs($student);

        $this->postJson('/api/v1/notifications/'.$notification->id.'/read')
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->assertTrue($notification->fresh()->is_read);
    }

    public function test_student_cannot_mark_foreign_notification_as_read(): void
    {
        $owner = $this->createStudent(['email' => 'notify-owner@rshd.test']);
        $attacker = $this->createStudent(['email' => 'notify-attacker@rshd.test']);
        $foreignNotification = $this->createNotificationFor($owner);

        Sanctum::actingAs($attacker);

        $this->postJson('/api/v1/notifications/'.$foreignNotification->id.'/read')
            ->assertForbidden();

        $this->assertFalse($foreignNotification->fresh()->is_read);
    }

    public function test_marking_nonexistent_notification_is_safe(): void
    {
        $student = $this->createStudent();

        Sanctum::actingAs($student);

        $this->postJson('/api/v1/notifications/999999/read')
            ->assertNotFound();
    }

    protected function createNotificationFor(User $user): AppNotification
    {
        return AppNotification::query()->create([
            'user_id' => $user->id,
            'title' => 'إشعار تجريبي',
            'body' => 'محتوى',
            'type' => 'test',
            'data' => ['source' => 'security-test'],
            'is_read' => false,
        ]);
    }
}
