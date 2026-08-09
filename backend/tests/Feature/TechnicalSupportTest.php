<?php

namespace Tests\Feature;

use App\Enums\SupportTicketStatus;
use App\Enums\UserRole;
use App\Enums\UserStatus;
use App\Models\SupportTicket;
use App\Models\User;
use App\Services\TechnicalSupportService;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class TechnicalSupportTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RolePermissionSeeder::class);
    }

    public function test_student_can_start_support_conversation(): void
    {
        $student = $this->createStudent();
        Sanctum::actingAs($student);

        $response = $this->postJson('/api/v1/student/support/messages', [
            'message' => 'أحتاج مساعدة في تسجيل الدخول',
        ]);

        $response
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.ticket.status', SupportTicketStatus::Pending->value)
            ->assertJsonCount(1, 'data.messages');

        $this->assertDatabaseHas('support_tickets', [
            'student_id' => $student->id,
            'status' => SupportTicketStatus::Pending->value,
        ]);
    }

    public function test_pending_ticket_visible_to_all_admins_until_accepted(): void
    {
        $student = $this->createStudent();
        $adminOne = $this->createAdmin(['email' => 'admin1@example.com']);
        $adminTwo = $this->createAdmin(['email' => 'admin2@example.com']);

        Sanctum::actingAs($student);
        $this->postJson('/api/v1/student/support/messages', [
            'message' => 'مشكلة في التطبيق',
        ])->assertOk();

        $ticket = SupportTicket::query()->firstOrFail();
        $service = app(TechnicalSupportService::class);

        $this->assertCount(1, $service->pendingTicketsForAdmins());
        $this->assertCount(0, $service->activeTicketsForAdmin($adminOne));
        $this->assertCount(0, $service->activeTicketsForAdmin($adminTwo));

        $service->acceptTicket($adminOne, $ticket);

        $this->assertCount(0, $service->pendingTicketsForAdmins());
        $this->assertCount(1, $service->activeTicketsForAdmin($adminOne));
        $this->assertCount(0, $service->activeTicketsForAdmin($adminTwo));
    }

    public function test_admin_can_close_ticket_and_student_can_start_new_one(): void
    {
        $student = $this->createStudent();
        $admin = $this->createAdmin();
        $service = app(TechnicalSupportService::class);

        Sanctum::actingAs($student);
        $this->postJson('/api/v1/student/support/messages', [
            'message' => 'رسالة أولى',
        ])->assertOk();

        $ticket = SupportTicket::query()->firstOrFail();
        $service->acceptTicket($admin, $ticket);
        $service->closeTicket($admin, $ticket->fresh());

        $this->getJson('/api/v1/student/support/ticket')
            ->assertOk()
            ->assertJsonPath('data.ticket', null);

        $this->postJson('/api/v1/student/support/messages', [
            'message' => 'محادثة جديدة',
        ])->assertOk();

        $this->assertSame(2, SupportTicket::query()->count());
    }

    /**
     * @param  array<string, mixed>  $overrides
     */
    protected function createStudent(array $overrides = []): User
    {
        return User::query()->create(array_merge([
            'name' => 'Student User',
            'email' => 'student@example.com',
            'password' => Hash::make('password'),
            'password_set_at' => now(),
            'role' => UserRole::Student,
            'status' => UserStatus::Active,
            'email_verified_at' => now(),
        ], $overrides));
    }

    /**
     * @param  array<string, mixed>  $overrides
     */
    protected function createAdmin(array $overrides = []): User
    {
        return User::query()->create(array_merge([
            'name' => 'Admin User',
            'email' => 'admin@example.com',
            'password' => Hash::make('password'),
            'password_set_at' => now(),
            'role' => UserRole::Admin,
            'status' => UserStatus::Active,
            'email_verified_at' => now(),
        ], $overrides));
    }
}
